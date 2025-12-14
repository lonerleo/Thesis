#!/bin/bash

# Local ZAP Scan Script for Testing
# Run this script locally before pushing to GitHub Actions

set -e

# Configuration
TARGET_URL="${1:-http://localhost:8080}"
SCAN_TYPE="${2:-baseline}"
ZAP_IMAGE="ghcr.io/zaproxy/zaproxy:stable"
REPORT_DIR="./zap-reports"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OWASP ZAP Local Scan Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Target URL: ${YELLOW}$TARGET_URL${NC}"
echo -e "Scan Type: ${YELLOW}$SCAN_TYPE${NC}"
echo ""

# Create report directory
mkdir -p "$REPORT_DIR"

# Pull latest ZAP image
echo -e "${GREEN}Pulling latest ZAP Docker image...${NC}"
docker pull $ZAP_IMAGE

# Check if target is reachable
echo -e "${GREEN}Checking if target is reachable...${NC}"
if curl -s -o /dev/null -w "%{http_code}" "$TARGET_URL" | grep -q "200\|302\|301"; then
    echo -e "${GREEN}✓ Target is reachable${NC}"
else
    echo -e "${RED}✗ Target is not reachable. Please check the URL.${NC}"
    exit 1
fi

# Run scan based on type
case $SCAN_TYPE in
    baseline)
        echo -e "${GREEN}Running ZAP Baseline Scan...${NC}"
        docker run --rm \
            -v "$(pwd)/$REPORT_DIR:/zap/wrk:rw" \
            $ZAP_IMAGE \
            zap-baseline.py \
            -t "$TARGET_URL" \
            -r baseline-report.html \
            -J baseline-report.json \
            -w baseline-report.md \
            -a \
            -j \
            -l INFO \
            -d || true
        
        REPORT_FILE="baseline-report"
        ;;
        
    full)
        echo -e "${YELLOW}Running ZAP Full Scan (this may take 30+ minutes)...${NC}"
        docker run --rm \
            -v "$(pwd)/$REPORT_DIR:/zap/wrk:rw" \
            $ZAP_IMAGE \
            zap-full-scan.py \
            -t "$TARGET_URL" \
            -r full-scan-report.html \
            -J full-scan-report.json \
            -w full-scan-report.md \
            -a \
            -j \
            -l INFO || true
        
        REPORT_FILE="full-scan-report"
        ;;
        
    api)
        API_DEF="${3:-/v3/api-docs}"
        echo -e "${GREEN}Running ZAP API Scan...${NC}"
        docker run --rm \
            -v "$(pwd)/$REPORT_DIR:/zap/wrk:rw" \
            $ZAP_IMAGE \
            zap-api-scan.py \
            -t "$TARGET_URL" \
            -f openapi \
            -r api-scan-report.html \
            -J api-scan-report.json \
            -w api-scan-report.md \
            -l INFO || true
        
        REPORT_FILE="api-scan-report"
        ;;
        
    *)
        echo -e "${RED}Invalid scan type. Use: baseline, full, or api${NC}"
        exit 1
        ;;
esac

# Parse results
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Scan Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if [ -f "$REPORT_DIR/${REPORT_FILE}.json" ]; then
    echo -e "${GREEN}Parsing results...${NC}"
    
    HIGH=$(jq '[.site[].alerts[] | select(.riskcode == "3")] | length' "$REPORT_DIR/${REPORT_FILE}.json" 2>/dev/null || echo "0")
    MEDIUM=$(jq '[.site[].alerts[] | select(.riskcode == "2")] | length' "$REPORT_DIR/${REPORT_FILE}.json" 2>/dev/null || echo "0")
    LOW=$(jq '[.site[].alerts[] | select(.riskcode == "1")] | length' "$REPORT_DIR/${REPORT_FILE}.json" 2>/dev/null || echo "0")
    INFO=$(jq '[.site[].alerts[] | select(.riskcode == "0")] | length' "$REPORT_DIR/${REPORT_FILE}.json" 2>/dev/null || echo "0")
    
    echo ""
    echo "Summary of Findings:"
    echo -e "  🔴 High:     ${RED}$HIGH${NC}"
    echo -e "  🟠 Medium:   ${YELLOW}$MEDIUM${NC}"
    echo -e "  🟡 Low:      $LOW"
    echo -e "  ℹ️  Info:     $INFO"
    echo ""
    
    if [ "$HIGH" -gt 0 ]; then
        echo -e "${RED}⚠️  HIGH severity issues found! Review immediately.${NC}"
    elif [ "$MEDIUM" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  MEDIUM severity issues found. Review soon.${NC}"
    else
        echo -e "${GREEN}✓ No high or medium severity issues found.${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Could not parse JSON report${NC}"
fi

echo ""
echo -e "Reports saved to: ${GREEN}$REPORT_DIR/${NC}"
echo -e "  - HTML Report: ${REPORT_FILE}.html"
echo -e "  - JSON Report: ${REPORT_FILE}.json"
echo -e "  - Markdown Report: ${REPORT_FILE}.md"
echo ""
echo -e "${GREEN}Open HTML report with:${NC}"
echo -e "  open $REPORT_DIR/${REPORT_FILE}.html  # macOS"
echo -e "  xdg-open $REPORT_DIR/${REPORT_FILE}.html  # Linux"
echo -e "  start $REPORT_DIR/${REPORT_FILE}.html  # Windows"
echo ""
