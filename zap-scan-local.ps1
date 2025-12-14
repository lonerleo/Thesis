# Local ZAP Scan Script for Testing (PowerShell)
# Run this script locally before pushing to GitHub Actions

param(
    [string]$TargetUrl = "http://localhost:8080",
    [ValidateSet("baseline", "full", "api")]
    [string]$ScanType = "baseline",
    [string]$ApiDefinition = "/v3/api-docs"
)

$ZapImage = "ghcr.io/zaproxy/zaproxy:stable"
$ReportDir = ".\zap-reports"

Write-Host "========================================" -ForegroundColor Green
Write-Host "OWASP ZAP Local Scan Script" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Target URL: $TargetUrl" -ForegroundColor Yellow
Write-Host "Scan Type: $ScanType" -ForegroundColor Yellow
Write-Host ""

# Create report directory
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir | Out-Null
}

# Pull latest ZAP image
Write-Host "Pulling latest ZAP Docker image..." -ForegroundColor Green
docker pull $ZapImage

# Check if target is reachable
Write-Host "Checking if target is reachable..." -ForegroundColor Green
try {
    $response = Invoke-WebRequest -Uri $TargetUrl -Method Head -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    Write-Host "✓ Target is reachable (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "✗ Target is not reachable. Please check the URL." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Get absolute path for volume mounting
$AbsoluteReportDir = (Resolve-Path $ReportDir).Path

# Run scan based on type
switch ($ScanType) {
    "baseline" {
        Write-Host "Running ZAP Baseline Scan..." -ForegroundColor Green
        docker run --rm `
            -v "${AbsoluteReportDir}:/zap/wrk:rw" `
            $ZapImage `
            zap-baseline.py `
            -t $TargetUrl `
            -r baseline-report.html `
            -J baseline-report.json `
            -w baseline-report.md `
            -a `
            -j `
            -l INFO `
            -d
        
        $ReportFile = "baseline-report"
    }
    
    "full" {
        Write-Host "Running ZAP Full Scan (this may take 30+ minutes)..." -ForegroundColor Yellow
        docker run --rm `
            -v "${AbsoluteReportDir}:/zap/wrk:rw" `
            $ZapImage `
            zap-full-scan.py `
            -t $TargetUrl `
            -r full-scan-report.html `
            -J full-scan-report.json `
            -w full-scan-report.md `
            -a `
            -j `
            -l INFO
        
        $ReportFile = "full-scan-report"
    }
    
    "api" {
        Write-Host "Running ZAP API Scan..." -ForegroundColor Green
        docker run --rm `
            -v "${AbsoluteReportDir}:/zap/wrk:rw" `
            $ZapImage `
            zap-api-scan.py `
            -t $TargetUrl `
            -f openapi `
            -r api-scan-report.html `
            -J api-scan-report.json `
            -w api-scan-report.md `
            -l INFO
        
        $ReportFile = "api-scan-report"
    }
}

# Parse results
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Scan Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$JsonReportPath = Join-Path $ReportDir "$ReportFile.json"

if (Test-Path $JsonReportPath) {
    Write-Host "Parsing results..." -ForegroundColor Green
    
    try {
        $reportContent = Get-Content $JsonReportPath -Raw | ConvertFrom-Json
        
        $high = ($reportContent.site.alerts | Where-Object { $_.riskcode -eq "3" }).Count
        $medium = ($reportContent.site.alerts | Where-Object { $_.riskcode -eq "2" }).Count
        $low = ($reportContent.site.alerts | Where-Object { $_.riskcode -eq "1" }).Count
        $info = ($reportContent.site.alerts | Where-Object { $_.riskcode -eq "0" }).Count
        
        Write-Host ""
        Write-Host "Summary of Findings:"
        Write-Host "  🔴 High:     $high" -ForegroundColor Red
        Write-Host "  🟠 Medium:   $medium" -ForegroundColor Yellow
        Write-Host "  🟡 Low:      $low"
        Write-Host "  ℹ️  Info:     $info"
        Write-Host ""
        
        if ($high -gt 0) {
            Write-Host "⚠️  HIGH severity issues found! Review immediately." -ForegroundColor Red
        } elseif ($medium -gt 0) {
            Write-Host "⚠️  MEDIUM severity issues found. Review soon." -ForegroundColor Yellow
        } else {
            Write-Host "✓ No high or medium severity issues found." -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️  Could not parse JSON report" -ForegroundColor Yellow
        Write-Host "Error: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  JSON report not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Reports saved to: $ReportDir" -ForegroundColor Green
Write-Host "  - HTML Report: $ReportFile.html"
Write-Host "  - JSON Report: $ReportFile.json"
Write-Host "  - Markdown Report: $ReportFile.md"
Write-Host ""
Write-Host "Open HTML report with:" -ForegroundColor Green
Write-Host "  Invoke-Item $ReportDir\$ReportFile.html"
Write-Host ""

# Usage examples
<#
.SYNOPSIS
    Run OWASP ZAP security scans locally using Docker

.DESCRIPTION
    This script runs OWASP ZAP security scans against a target application
    and generates HTML, JSON, and Markdown reports.

.PARAMETER TargetUrl
    The URL of the application to scan (default: http://localhost:8080)

.PARAMETER ScanType
    Type of scan to run: baseline, full, or api (default: baseline)

.PARAMETER ApiDefinition
    API definition endpoint for API scans (default: /v3/api-docs)

.EXAMPLE
    .\zap-scan-local.ps1
    Run a baseline scan against http://localhost:8080

.EXAMPLE
    .\zap-scan-local.ps1 -TargetUrl "http://192.168.1.100:8080" -ScanType baseline
    Run a baseline scan against a specific target

.EXAMPLE
    .\zap-scan-local.ps1 -TargetUrl "http://localhost:8080" -ScanType full
    Run a full active scan (takes longer)

.EXAMPLE
    .\zap-scan-local.ps1 -TargetUrl "http://localhost:8080" -ScanType api
    Run an API scan

.NOTES
    Requires Docker to be installed and running
#>
