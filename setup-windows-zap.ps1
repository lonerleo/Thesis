# Setup Script for Windows ZAP Server
# Run this on the Windows Server (51.21.57.0) as Administrator

Write-Host "=== Setting up Windows ZAP Server ===" -ForegroundColor Green

# 1. Create reports directory
$reportDir = "C:\zap-reports"
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir
    Write-Host "✅ Created reports directory: $reportDir" -ForegroundColor Green
} else {
    Write-Host "✅ Reports directory already exists" -ForegroundColor Yellow
}

# 2. Ensure ZAP is installed
$zapPath = "C:\Program Files\ZAP\Zed Attack Proxy"
if (Test-Path $zapPath) {
    Write-Host "✅ ZAP is installed at: $zapPath" -ForegroundColor Green
} else {
    Write-Host "❌ ZAP not found. Please install from: https://www.zaproxy.org/download/" -ForegroundColor Red
    exit 1
}

# 3. Test ZAP command
Write-Host "`n=== Testing ZAP ===" -ForegroundColor Cyan
cd $zapPath
.\zap.bat -version

Write-Host "`n=== Setup Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Keep this Windows server running"
Write-Host "2. Ensure SSH is enabled (for GitHub Actions to connect)"
Write-Host "3. ZAP GUI will show scan results when scans run"
Write-Host ""
Write-Host "To view scans:" -ForegroundColor Cyan
Write-Host "- RDP to this server (51.21.57.0)"
Write-Host "- Open ZAP GUI"
Write-Host "- View scan history and results"
Write-Host ""
Write-Host "Reports saved to: $reportDir" -ForegroundColor Cyan
