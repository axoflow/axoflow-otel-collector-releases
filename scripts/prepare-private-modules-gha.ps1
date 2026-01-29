$keyPath = "$env:RUNNER_TEMP\deploy_key"

$key = ($env:DEPLOY_KEY_PRIVATE_FOR_AXO_ETW -replace "`r", "").Trim() + "`n"
[System.IO.File]::WriteAllBytes($keyPath, [System.Text.Encoding]::ASCII.GetBytes($key))

icacls $keyPath /inheritance:r | Out-Null
icacls $keyPath /grant:r "$($env:USERNAME):(R)" | Out-Null

$sshDir = "$env:USERPROFILE\.ssh"
if (!(Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}
ssh-keyscan github.com >> "$sshDir\known_hosts" 2>$null

$keyPathUnix = $keyPath -replace '\\', '/'

$env:GIT_SSH_COMMAND = "ssh -i `"$keyPathUnix`" -o IdentitiesOnly=yes -o StrictHostKeyChecking=no"

"GIT_SSH_COMMAND=ssh -i `"$keyPathUnix`" -o IdentitiesOnly=yes -o StrictHostKeyChecking=no" >> $env:GITHUB_ENV

git config --global url."git@github.com:axoflow/axo-etw.git".insteadOf "https://github.com/axoflow/axo-etw"
