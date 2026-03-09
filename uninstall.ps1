#!/usr/bin/env pwsh
# claude-mint uninstaller for Windows (if applicable)

$ErrorActionPreference = "Stop"

Write-Host "=== Uninstalling claude-mint ===" -ForegroundColor Cyan

$SkillDir = Join-Path $env:USERPROFILE ".claude" "skills" "mint"
if (Test-Path $SkillDir) {
    Remove-Item -Recurse -Force $SkillDir
    Write-Host "  Removed: $SkillDir" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== claude-mint uninstalled ===" -ForegroundColor Cyan
Write-Host "Restart Claude Code to complete removal." -ForegroundColor Yellow
