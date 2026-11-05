# Launch Library Management System Frontend
$indexPath = Join-Path $PSScriptRoot "frontend\index.html"
Write-Host "Opening Library Management System Frontend..." -ForegroundColor Cyan
Start-Process $indexPath
Write-Host "Frontend opened in default web browser!" -ForegroundColor Green

