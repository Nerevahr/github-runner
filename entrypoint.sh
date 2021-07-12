#!/usr/bin/dumb-init /bin/bash

export RUNNER_ALLOW_RUNASROOT=1
export PATH=$PATH:/actions-runner

deregister_runner() {
  echo "Caught SIGTERM. Deregistering runner"
  _TOKEN=$(bash /token.sh)
  RUNNER_TOKEN=$(echo "${_TOKEN}" | jq -r .token)
  ./config.sh remove --token "${RUNNER_TOKEN}"
  exit
}

_RUNNER_NAME=${RUNNER_NAME:-${RUNNER_NAME_PREFIX:-github-runner}-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')}
_RUNNER_WORKDIR=${RUNNER_WORKDIR:-/_work}
_LABELS=${LABELS:-default}
_SHORT_URL=${REPO_URL}

if [[ ${ORG_RUNNER} == "true" ]]; then
  _SHORT_URL="https://github.com/${ORG_NAME}"
fi

if [[ -n "${ACCESS_TOKEN}" ]]; then
  echo "Obtaining runner token from access token"
  _TOKEN=$(bash /token.sh)
  RUNNER_TOKEN=$(echo "${_TOKEN}" | jq -r .token)
  _SHORT_URL=$(echo "${_TOKEN}" | jq -r .short_url)
fi

echo "Configuring"
./config.sh \
    --name "${_RUNNER_NAME}" \
    --token "${RUNNER_TOKEN}" \
    --url "${_SHORT_URL}" \
    --work "${_RUNNER_WORKDIR}" \
    --labels "${_LABELS}" \
    --unattended \
    --replace

unset RUNNER_TOKEN
trap deregister_runner SIGINT SIGQUIT SIGTERM

./bin/runsvc.sh
