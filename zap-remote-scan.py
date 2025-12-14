#!/usr/bin/env python3
"""
ZAP Remote Scanner
Connects to remote ZAP instance and runs security scans
"""

import os
import sys
import time
import json
from zapv2 import ZAPv2

# Configuration from environment
ZAP_HOST = os.getenv('ZAP_HOST', '51.21.57.0')
ZAP_PORT = os.getenv('ZAP_PORT', '8080')
ZAP_API_KEY = os.getenv('ZAP_API_KEY', '')
TARGET_URL = os.getenv('TARGET_URL', 'http://13.49.91.130')
SCAN_TYPE = os.getenv('SCAN_TYPE', 'baseline')  # baseline, full, spider-only

def main():
    print(f"=== OWASP ZAP Remote Scanner ===")
    print(f"ZAP Server: {ZAP_HOST}:{ZAP_PORT}")
    print(f"Target: {TARGET_URL}")
    print(f"Scan Type: {SCAN_TYPE}")
    print("=" * 40)
    
    # Connect to ZAP
    zap_proxy = f'http://{ZAP_HOST}:{ZAP_PORT}'
    zap = ZAPv2(apikey=ZAP_API_KEY, proxies={'http': zap_proxy, 'https': zap_proxy})
    
    try:
        # Test connection
        print("\n[1/5] Testing connection to ZAP...")
        version = zap.core.version
        print(f"✓ Connected to ZAP version: {version}")
        
        # Access target
        print(f"\n[2/5] Accessing target: {TARGET_URL}")
        zap.urlopen(TARGET_URL)
        time.sleep(2)
        print("✓ Target accessed")
        
        # Spider scan
        print(f"\n[3/5] Running spider scan...")
        scan_id = zap.spider.scan(TARGET_URL)
        print(f"Spider scan ID: {scan_id}")
        
        while int(zap.spider.status(scan_id)) < 100:
            progress = zap.spider.status(scan_id)
            print(f"  Spider progress: {progress}%")
            time.sleep(5)
        
        print("✓ Spider scan completed")
        print(f"  URLs found: {len(zap.spider.results(scan_id))}")
        
        # Active scan (if not spider-only)
        if SCAN_TYPE in ['baseline', 'full']:
            print(f"\n[4/5] Running active scan...")
            scan_id = zap.ascan.scan(TARGET_URL)
            print(f"Active scan ID: {scan_id}")
            
            while int(zap.ascan.status(scan_id)) < 100:
                progress = zap.ascan.status(scan_id)
                print(f"  Active scan progress: {progress}%")
                time.sleep(10)
            
            print("✓ Active scan completed")
        else:
            print("\n[4/5] Skipping active scan (spider-only mode)")
        
        # Get results
        print(f"\n[5/5] Collecting results...")
        alerts = zap.core.alerts(baseurl=TARGET_URL)
        
        # Analyze results
        risk_counts = {
            'High': 0,
            'Medium': 0,
            'Low': 0,
            'Informational': 0
        }
        
        for alert in alerts:
            risk = alert.get('risk', 'Informational')
            risk_counts[risk] = risk_counts.get(risk, 0) + 1
        
        # Print summary
        print("\n" + "=" * 40)
        print("SCAN RESULTS SUMMARY")
        print("=" * 40)
        print(f"Total Alerts: {len(alerts)}")
        print(f"  🔴 High:     {risk_counts['High']}")
        print(f"  🟠 Medium:   {risk_counts['Medium']}")
        print(f"  🟡 Low:      {risk_counts['Low']}")
        print(f"  ℹ️  Info:     {risk_counts['Informational']}")
        print("=" * 40)
        
        # Save detailed results
        output_dir = 'zap-reports'
        os.makedirs(output_dir, exist_ok=True)
        
        # JSON report
        json_file = f'{output_dir}/zap-results.json'
        with open(json_file, 'w') as f:
            json.dump(alerts, f, indent=2)
        print(f"\n✓ JSON report saved: {json_file}")
        
        # HTML report
        html_file = f'{output_dir}/zap-results.html'
        html_report = zap.core.htmlreport()
        with open(html_file, 'w') as f:
            f.write(html_report)
        print(f"✓ HTML report saved: {html_file}")
        
        # Summary for GitHub Actions
        if os.getenv('GITHUB_ACTIONS'):
            with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as f:
                f.write('\n## 🔒 ZAP Scan Results\n\n')
                f.write('| Severity | Count |\n')
                f.write('|----------|-------|\n')
                f.write(f"| 🔴 High | {risk_counts['High']} |\n")
                f.write(f"| 🟠 Medium | {risk_counts['Medium']} |\n")
                f.write(f"| 🟡 Low | {risk_counts['Low']} |\n")
                f.write(f"| ℹ️ Info | {risk_counts['Informational']} |\n\n")
                f.write(f"**Total Alerts:** {len(alerts)}\n\n")
        
        # Exit code based on findings
        if risk_counts['High'] > 0:
            print(f"\n⚠️  WARNING: {risk_counts['High']} high-risk vulnerabilities found!")
            return 1
        elif risk_counts['Medium'] > 5:
            print(f"\n⚠️  WARNING: {risk_counts['Medium']} medium-risk vulnerabilities found!")
            return 1
        else:
            print(f"\n✓ Scan completed successfully")
            return 0
            
    except Exception as e:
        print(f"\n❌ Error: {str(e)}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
