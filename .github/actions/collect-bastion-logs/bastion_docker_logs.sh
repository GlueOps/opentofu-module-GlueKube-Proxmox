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
set -uo pipefail

CONTAINER_COUNT="${CONTAINER_COUNT:-3}"
TAIL_LINES="${TAIL_LINES:-500}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is not installed on this bastion."
  echo "The base image does not ship it (cloudinit/cloud-init-bastion.yaml installs"
  echo "only curl and qemu-guest-agent), so AutoGlue provisioning adds it when it"
  echo "brings the bastion to 'ready'. Docker missing therefore means provisioning"
  echo "never got that far — which is the finding, not a gap in this collector."
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
  echo "No containers exist on the bastion at all."
  echo "The AutoGlue run therefore never started one, so its failure happened before"
  echo "that — check the run record and the bastion's own provisioning."
  exit 0
fi

for id in "${IDS[@]}"; do
  name=$(docker inspect -f '{{.Name}}'             "$id" 2>/dev/null | sed 's|^/||')
  image=$(docker inspect -f '{{.Config.Image}}'    "$id" 2>/dev/null)
  status=$(docker inspect -f '{{.State.Status}}'   "$id" 2>/dev/null)
  exitcode=$(docker inspect -f '{{.State.ExitCode}}' "$id" 2>/dev/null)
  started=$(docker inspect -f '{{.State.StartedAt}}' "$id" 2>/dev/null)

  echo "::group::${name:-$id} — ${image:-unknown image} — ${status:-unknown} (exit ${exitcode:-?})"
  echo "container : ${id}"
  echo "image     : ${image:-unknown}"
  echo "started   : ${started:-unknown}"
  echo "status    : ${status:-unknown} (exit code ${exitcode:-unknown})"
  echo "----------------------------------------------------------------------"
  # 2>&1 because a container's stderr is a separate stream to docker and the
  # Ansible failure text is usually on it — dropping it would lose the message
  # this whole action exists to surface.
  docker logs --tail "${TAIL_LINES}" --timestamps "$id" 2>&1 \
    || echo "(could not read logs for ${id})"
  echo "::endgroup::"
  echo ""
done

# Deliberately last and unconditional: an exit code of 0 on the newest container
# with a red job usually means the failure is one of the OLDER containers above,
# and this line is the nudge to scroll up rather than conclude "logs look fine".
echo "Dumped ${#IDS[@]} of the most recent containers. If none of them looks like the"
echo "failure, raise container-count on the collect-bastion-logs step."
exit 0
