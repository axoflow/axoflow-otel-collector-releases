#!/usr/bin/env bash

# Setup SSH based git operations for GitHub Actions
git config --global url."git@github.com:".insteadOf "https://github.com/"

# Setup Deploy Key for private repository access

export SSH_AUTH_SOCK="/tmp/ssh_agent.sock"

ssh-agent -a ${SSH_AUTH_SOCK} >/dev/null
ssh-add - <<<"${DEPLOY_KEY_PRIVATE_FOR_AXO_ETW}"
