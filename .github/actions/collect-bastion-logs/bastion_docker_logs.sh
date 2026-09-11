#!/usr/bin/env bash
#
# Runs ON THE BASTION, as root, piped in over ssh by collect_bastion_logs.sh.
# Prints `docker ps -a` and the tail of the most recently created containers'
# logs — the GlueKube container an AutoGlue action run leaves behind, which is
# where the real reason for a failed run lives.
#
# Environment (set by the caller's `sudo env ...` prefix):
#   CONTAINER_COUNT  how many containers to dump, newest first
#   TAIL_LINES       log lines from the end of each
#
# Like its caller, this always exits 0 — it explains a failure, it does not add one.
#
# Making the failure FINDABLE, not just present
#
#   Dumping the logs is not enough on its own. The first version of this printed
#   the right error, and it still went unseen: it sat inside this step, which is
#   green by design, inside a collapsed ::group::, below ~150 lines of healthy
#   `ping` output. Anyone opening the run clicks the RED step, which only ever
#   says "run failed after 30s". So for every container that exited non-zero:
#     - its log is printed OUTSIDE a group, so it is expanded by default;
#     - the lines that look like the cause are re-emitted as ::error::
#       annotations, which GitHub shows on the run's summary page and in the
#       step list, where people actually look.
#   Containers that exited 0 stay grouped: they are context, not the answer.
set -uo pipefail

CONTAINER_COUNT="${CONTAINER_COUNT:-3}"
TAIL_LINES="${TAIL_LINES:-500}"

# What a cause looks like in GlueKube's output: Ansible's own failure markers and
# make's final "Error N" line, which names the target that died.
ERROR_PATTERN='\[ERROR\]|fatal:|FAILED!|UNREACHABLE!|make: \*\*\*'
# GitHub renders at most 10 error annotations per step. Keep a few spare for the
# caller's own warnings, and because the first handful carry the cause anyway —
# the rest of a failing play is usually the same error repeated per host.
MAX_ANNOTATIONS=6

if ! command -v docker >/dev/null 2>&1; then
  echo "::warning title=docker is not installed on the bastion::AutoGlue provisioning installs docker when it brings the bastion to 'ready' (the base cloud-init does not), so it never got that far. That is the finding."
  exit 0
fi

echo "::group::docker ps -a (every container on the bastion)"
docker ps -a --format 'table {{.ID}}\t{{.Image}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Names}}' 2>&1
echo "::endgroup::"
echo ""

# Newest first. `docker ps -aq -n N` orders by creation, which is what we want:
# the container that failed is near the top, but not always AT the top, since a
# run can spawn a short-lived helper afterwards.
mapfile -t IDS < <(docker ps -aq -n "${CONTAINER_COUNT}" 2>/dev/null)

if [ "${#IDS[@]}" -eq 0 ]; then
  echo "::warning title=No containers on the bastion::The AutoGlue run never started a GlueKube container, so it failed before that. Check the run record and the bastion's own provisioning."
  exit 0
fi

# Everything a container printed goes between these, so a log line that happens to
# look like a workflow command (`::add-mask::`, `::error::`, `::endgroup::` ...) is
# printed as text instead of being executed by the runner. The token is random so
# the log cannot contain the resume line by accident.
STOP_TOKEN="gluekube-logs-$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"

failed_seen=0
for id in "${IDS[@]}"; do
  name=$(docker inspect -f '{{.Name}}'               "$id" 2>/dev/null | sed 's|^/||')
  image=$(docker inspect -f '{{.Config.Image}}'      "$id" 2>/dev/null)
  status=$(docker inspect -f '{{.State.Status}}'     "$id" 2>/dev/null)
  exitcode=$(docker inspect -f '{{.State.ExitCode}}' "$id" 2>/dev/null)
  started=$(docker inspect -f '{{.State.StartedAt}}' "$id" 2>/dev/null)
  label="${name:-$id} — ${image:-unknown image} — ${status:-unknown} (exit ${exitcode:-?})"

  failed=0
  if [ "${status}" = "exited" ] && [ "${exitcode:-0}" != "0" ]; then
    failed=1
  fi

  if [ "$failed" -eq 1 ]; then
    echo "======================================================================"
    echo "FAILED CONTAINER: ${label}"
    echo "======================================================================"
  else
    echo "::group::${label}"
  fi
  echo "container : ${id}"
  echo "image     : ${image:-unknown}"
  echo "started   : ${started:-unknown}"
  echo "status    : ${status:-unknown} (exit code ${exitcode:-unknown})"
  echo "----------------------------------------------------------------------"

  # 2>&1 because a container's stderr is a separate stream to docker and the
  # Ansible failure text is usually on it — dropping it would lose the message
  # this whole action exists to surface.
  logs=$(docker logs --tail "${TAIL_LINES}" --timestamps "$id" 2>&1) \
    || logs="(could not read logs for ${id})"

  echo "::stop-commands::${STOP_TOKEN}"
  printf '%s\n' "$logs"
  echo "::${STOP_TOKEN}::"

  if [ "$failed" -eq 1 ]; then
    failed_seen=$((failed_seen + 1))
    # Drop docker's RFC3339 prefix: the annotation is read on its own, and the
    # timestamp is noise there. `%` must be escaped or the runner eats it as the
    # start of an escape sequence.
    matches=$(printf '%s\n' "$logs" \
      | grep -E "$ERROR_PATTERN" \
      | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z //' \
      | awk '!seen[$0]++' \
      | head -n "$MAX_ANNOTATIONS")

    echo ""
    if [ -n "$matches" ]; then
      while IFS= read -r line; do
        echo "::error title=GlueKube container ${name:-$id} exited ${exitcode}::${line//%/%25}"
      done <<< "$matches"
    else
      # Nothing matched the pattern — say so and point at the tail, rather than
      # emitting nothing and letting the run page look as uninformative as before.
      last=$(printf '%s\n' "$logs" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z //' | grep -v '^[[:space:]]*$' | tail -n 1)
      echo "::error title=GlueKube container ${name:-$id} exited ${exitcode}::No recognised error line; the log above ends with: ${last//%/%25}"
    fi
  else
    echo "::endgroup::"
  fi
  echo ""
done

if [ "$failed_seen" -eq 0 ]; then
  # An exit 0 on every container with a red job usually means the failure was in
  # an older container than the ones dumped, or not in a container at all.
  echo "::warning title=No failed container among the last ${#IDS[@]}::None of the most recent containers exited non-zero. Raise container-count on the collect-bastion-logs step, or the failure was outside the GlueKube container."
fi
exit 0
