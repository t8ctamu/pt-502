param(
    [ValidateSet("setup", "test", "lint", "server")]
    [string]$Action = "test",
    [string]$Container = "admiring_liskov"
)
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
$runId = [guid]::NewGuid().ToString("N")
$archive = Join-Path ([IO.Path]::GetTempPath()) "pt502-$runId.tar"
$containerDir = "/tmp/pt502-$runId"
$evidence = Join-Path $repoRoot "evidence"
New-Item -ItemType Directory -Force $evidence | Out-Null
function Assert-Native([string]$Step) {
    if ($LASTEXITCODE -ne 0) { throw "$Step failed (exit $LASTEXITCODE)" }
}
try {
    docker start $Container | Out-Null
    Assert-Native "Start container"
    # Host repo is the source of truth; each run uses a fresh container copy.
    tar -cf $archive --exclude=.git --exclude=coverage --exclude=evidence --exclude=tmp --exclude=log --exclude=storage --exclude=.bundle --exclude=vendor/bundle --exclude=config/master.key --exclude=.env -C $repoRoot .
    Assert-Native "Archive project"
    docker exec $Container mkdir -p $containerDir
    Assert-Native "Create working directory"
    docker cp $archive "${Container}:${containerDir}/source.tar"
    Assert-Native "Copy project"
    docker exec -w $containerDir $Container tar -xf source.tar
    Assert-Native "Extract project"
    $ErrorActionPreference = "Continue"
    docker exec -w $containerDir $Container bash script/container-lab.sh $Action 2>&1 | Tee-Object -FilePath (Join-Path $evidence "$Action-output.txt")
    $result = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    docker cp "${Container}:${containerDir}/Gemfile.lock" (Join-Path $repoRoot "Gemfile.lock") | Out-Null
    if ($Action -in @("setup", "test")) {
        docker cp "${Container}:${containerDir}/db/." (Join-Path $repoRoot "db") | Out-Null
    }
    if ($Action -eq "test") {
        New-Item -ItemType Directory -Force (Join-Path $repoRoot "coverage") | Out-Null
        docker cp "${Container}:${containerDir}/coverage/." (Join-Path $repoRoot "coverage") | Out-Null
    }
    if ($result -ne 0) { throw "$Action failed (exit $result). See evidence/$Action-output.txt." }
} finally {
    # Only remove this invocation's generated temporary files.
    if ($containerDir -match '^/tmp/pt502-[0-9a-f]{32}$') {
        docker exec $Container rm -rf -- $containerDir | Out-Null
    }
    if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive }
}
