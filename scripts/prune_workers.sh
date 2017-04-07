#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<-EOUSAGE >&2
  Prunes stalled workers after a concourse deployment
  
  Usage: $(basename "$0") <target> [number of workers manifest]

  Required
    [target]                        concourse target

  Optional
    [number of workers manifest]    workers specified in the BOSH manifest
                                    validates if all workers got deployed

EOUSAGE
  exit 1
}

msg() {
  printf "=> %s\n" "$@"
}

error() {
  local _msg="${1:-}"
  COLOR='\033[0;31m'; NC='\033[0m'
  
  [[ -n "$_msg" ]] && printf "${COLOR}%s${NC}\n" "ERROR: $_msg" >&2
}

check_installed() {
  if ! command -v "$1" > /dev/null 2>&1; then
    error "$1 must be installed before running this script!"
    exit 2
  fi
}

get_all_workers() {
  WORKERS="${WORKERS:-$($fly_cmd workers)}"
}

list_running_workers() {
  echo "$WORKERS" | grep 'running'
}

list_stalled_workers() {
  echo "$WORKERS" | grep 'stalled'
}

[[ $# -gt 0 ]] || usage
target="$1"
num_workers_deployment="${2:-}"

fly_cmd="fly -t ${target}"

check_installed fly

msg "Syncing target: $target"
$fly_cmd sync || true

# Checks if login is needed
if ! get_all_workers 2> /dev/null; then
  $fly_cmd login
fi

if [[ -n ${num_workers_deployment} ]]; then
  msg "Validating if all workers got deployed"

  count=$(list_running_workers | wc -l | awk '{print $1}')
  if [[ ${count:-$num_workers_deployment} -ne "$num_workers_deployment" ]]; then
    error "There are missing workers"
    error "Number of workers in deployment: ${num_workers_deployment}, got $count"

    echo
    list_running_workers
    exit 1
  fi
fi

msg "Pruning workers"
for _worker in $(list_stalled_workers | awk '{print $1}'); do
  echo "Pruning: $_worker"
  $fly_cmd prune-worker -w "$_worker"
done
msg "Done"
