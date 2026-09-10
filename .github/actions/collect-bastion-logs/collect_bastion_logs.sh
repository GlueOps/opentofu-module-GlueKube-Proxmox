#!/usr/bin/env bash
#
# Dump `docker ps -a` and the tail of the most recent containers' logs from this
# run's AutoGlue bastion. See action.yml for why this exists.
#
# Required environment variables:
#   BASE_URL   AutoGlue API base url
#   API_KEY    AutoGlue API key  (sent as X-API-KEY header)
#   ORG_NAME   AutoGlue org name (resolved to an org id via /orgs)
# Optional:
#   CLUSTER_NAME         restrict the bastion lookup to this cluster
#   CONTAINER_COUNT      containers to dump, newest first   (default 3)
#   TAIL_LINES           log lines from the end of each      (default 500)
#   SSH_CONNECT_TIMEOUT  ssh connect timeout in seconds      (default 30)
#
# ALWAYS EXITS 0.
#
# This is a diagnostic that runs when the job is already failing, so every way it
# can go wrong — no bastion registered yet because the first apply died, the API
# unreachable, docker not installed, no containers — is reported as a message and
# not as an exit code. A diagnostic that fails on top of the failure it was meant
# to explain replaces the real error in the log with its own, which is the exact
# problem it was added to solve. Note the missing `-e`: this script checks its
# own steps rather than aborting on the first non-zero.
set -uo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-}"
CONTAINER_COUNT="${CONTAINER_COUNT:-3}"
TAIL_LINES="${TAIL_LINES:-500}"
SSH_CONNECT_TIMEOUT="${SSH_CONNECT_TIMEOUT:-30}"

# Bail out politely, never fatally. Every early return in this script goes through
# here so the reason is visible in the job log and the step still passes.
give_up() {
  echo "::warning title=Could not collect bastion docker logs::$*"
  echo ""
  echo "No bastion logs were collected: $*"
  echo "The failure this run is reporting is above; this step adds nothing to it."
  exit 0
}

for var in BASE_URL API_KEY ORG_NAME; do
  if [ -z "${!var:-}" ]; then
    give_up "${var} is not set"
  fi
done

# These are interpolated into the remote command line, so reject anything that is
# not a plain integer rather than shipping it to the bastion.
for var in CONTAINER_COUNT TAIL_LINES SSH_CONNECT_TIMEOUT; do
  case "${!var}" in
    "" | *[!0-9]*) give_up "${var} must be a non-negative integer, got: ${!var}" ;;
  esac
done

api() {
  curl -sfS --http1.1 --max-time 60 "$@" \
    -H "accept: application/json" \
    -H "X-API-KEY: ${API_KEY}"
}

echo "==> Resolving org '${ORG_NAME}'..."
ORGS=$(api -X GET "${BASE_URL}/orgs") || give_up "could not reach ${BASE_URL}/orgs"
ORG_ID=$(echo "$ORGS" | jq -r --arg name "$ORG_NAME" '.[] | select(.name == $name) | .id')
if [ -z "$ORG_ID" ] || [ "$ORG_ID" = "null" ]; then
  give_up "org '${ORG_NAME}' not found"
fi

# Same isolation rationale as check-cluster-health: without the cluster filter the
# only thing keeping this off a previous run's leftover bastion is the pre-flight
# org nuke, and reading the wrong bastion's logs sends you debugging a failure
# that never happened.
CLUSTER_ID=""
if [ -n "$CLUSTER_NAME" ]; then
  echo "==> Resolving cluster '${CLUSTER_NAME}'..."
  CLUSTERS=$(api -G "${BASE_URL}/clusters" \
    --data-urlencode "q=${CLUSTER_NAME}" \
    -H "x-org-id: ${ORG_ID}") || give_up "could not list clusters"
  CLUSTER_ID=$(echo "$CLUSTERS" | jq -r --arg n "$CLUSTER_NAME" \
    'map(select(.name == $n)) | .[0].id // empty')
  [ -n "$CLUSTER_ID" ] || give_up "cluster '${CLUSTER_NAME}' not found in org '${ORG_NAME}' (did the first apply get that far?)"
else
  echo "WARNING: CLUSTER_NAME is not set, so the bastion lookup cannot be filtered"
  echo "WARNING: to this run's cluster. Logs may come from a leftover bastion."
fi

echo "==> Finding the bastion..."
SERVERS=$(api -G "${BASE_URL}/servers" \
  --data-urlencode "role=bastion" \
  -H "x-org-id: ${ORG_ID}") || give_up "could not list servers"

FILTERED="$SERVERS"
if [ -n "$CLUSTER_ID" ]; then
  # Only filter when the records actually carry a cluster id — otherwise filtering
  # yields nothing and reads as "no bastion", masking the real situation.
  if [ "$(echo "$SERVERS" | jq -r '[.[] | select(has("cluster_id"))] | length')" -gt 0 ]; then
    FILTERED=$(echo "$SERVERS" | jq --arg cid "$CLUSTER_ID" 'map(select(.cluster_id == $cid))')
  else
    echo "WARNING: /servers records carry no cluster_id; cannot filter to this run."
  fi
fi

BASTION=$(echo "$FILTERED" | jq -r '.[0] // empty')
[ -n "$BASTION" ] || give_up "no bastion server is registered in AutoGlue yet"

BASTION_IP=$(echo "$BASTION" | jq -r '.public_ip_address // empty')
BASTION_USER=$(echo "$BASTION" | jq -r '.ssh_user // empty')
BASTION_KEY_ID=$(echo "$BASTION" | jq -r '.ssh_key_id // empty')
[ -n "$BASTION_IP" ]     || give_up "the bastion record has no public_ip_address"
[ -n "$BASTION_USER" ]   || give_up "the bastion record has no ssh_user"
[ -n "$BASTION_KEY_ID" ] || give_up "the bastion record has no ssh_key_id"

echo "==> Revealing the bastion ssh key..."
KEY_FILE=$(mktemp)
trap 'rm -f "$KEY_FILE"' EXIT
chmod 600 "$KEY_FILE"
api -G "${BASE_URL}/ssh/${BASTION_KEY_ID}" \
  --data-urlencode "reveal=true" \
  -H "x-org-id: ${ORG_ID}" | jq -r '.private_key // empty' > "$KEY_FILE"
[ -s "$KEY_FILE" ] || give_up "ssh key ${BASTION_KEY_ID} returned an empty private_key"
# Guard against a key stored without its trailing newline; ssh rejects those.
[ -n "$(tail -c1 "$KEY_FILE")" ] && echo >> "$KEY_FILE"

REMOTE_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bastion_docker_logs.sh"
[ -f "$REMOTE_SCRIPT" ] || give_up "bastion_docker_logs.sh is not next to this script"

echo "==> Collecting docker logs from ${BASTION_USER}@${BASTION_IP}"
echo "    (last ${CONTAINER_COUNT} containers, ${TAIL_LINES} lines each)"
echo ""

# The script arrives on stdin rather than being interpolated into a shell string,
# so it can contain quotes freely — the same choice check_cluster_health.sh makes,
# and for the same reason: an escaping mistake there becomes a baffling remote
# failure. CONTAINER_COUNT and TAIL_LINES are integer-validated above, so building
# the `env` prefix by hand is safe.
ssh -i "$KEY_FILE" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o ConnectTimeout="${SSH_CONNECT_TIMEOUT}" \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=10 \
  -o BatchMode=yes \
  "${BASTION_USER}@${BASTION_IP}" \
  "sudo env CONTAINER_COUNT=${CONTAINER_COUNT} TAIL_LINES=${TAIL_LINES} bash -s" \
  < "$REMOTE_SCRIPT"

rc=$?
if [ "$rc" -ne 0 ]; then
  # Not fatal, on purpose: see the header. Most likely the bastion never finished
  # provisioning, which is itself worth knowing and is stated rather than guessed.
  echo ""
  echo "::warning title=Bastion log collection was incomplete::ssh to the bastion exited ${rc}. If the AutoGlue run failed because the bastion never came up, that is expected and is the finding."
fi

echo ""
echo "==> Bastion log collection finished."
exit 0
