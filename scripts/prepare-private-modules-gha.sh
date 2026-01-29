#!/usr/bin/env bash

export SSH_AUTH_SOCK="/tmp/ssh_agent.sock"
ssh-agent -a "${SSH_AUTH_SOCK}" > /dev/null
ssh-add - <<< "${DEPLOY_KEY_PRIVATE_FOR_AXO_ETW}"

mkdir -p ~/.ssh
ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null

git config --global url."git@github.com:axoflow/axo-etw.git".insteadOf "https://github.com/axoflow/axo-etw"

echo "SSH_AUTH_SOCK=${SSH_AUTH_SOCK}" >> "$GITHUB_ENV"
