# OWASP ZAP DAST Automation with GitHub Actions

This project automates Dynamic Application Security Testing (DAST) using OWASP ZAP against your Pet Clinic application hosted on EC2.

## 🚀 Quick Start

### Prerequisites

1. **EC2 Instance**: Running with Pet Clinic app deployed
2. **GitHub Repository**: Where these scripts will be committed
3. **GitHub Secrets**: Configure the target URL

### Setup Instructions

#### 1. Configure GitHub Secrets

Navigate to your GitHub repository:
- Go to **Settings** → **Secrets and variables** → **Actions**
- Click **New repository secret**
- Add the following secret:

```
Name: PET_CLINIC_URL
Value: http://your-ec2-public-ip:8080
```

Replace `your-ec2-public-ip` with your actual EC2 public IP or domain.

#### 2. Update Security Group (EC2)

Ensure your EC2 security group allows inbound traffic from GitHub Actions runners:
- Go to EC2 → Security Groups
- Add inbound rule: **Custom TCP** on port **8080** from **0.0.0.0/0** (or restrict to GitHub's IP ranges)

Alternatively, use GitHub's IP ranges: https://api.github.com/meta

#### 3. Commit and Push

```bash
git add .github/workflows/zap-scan.yml zap-rules.tsv
git commit -m "Add OWASP ZAP DAST automation"
git push origin main
```

## 📋 Workflow Types

### 1. **Baseline Scan** (Default - Fast)
- Runs on every push to `main` branch
- Runs on pull requests
- Duration: ~5-10 minutes
- Passive scanning only (no active attacks)
- Good for continuous integration

### 2. **Full Scan** (Comprehensive - Slow)
- Runs on manual trigger or daily schedule (2 AM UTC)
- Duration: 30 minutes - 2 hours (depending on app size)
- Active scanning with spider and attacks
- Use for thorough security testing

### 3. **API Scan** (API Focused)
- Runs on manual trigger only
- Requires OpenAPI/Swagger definition
- Tests API endpoints specifically

### 4. **Custom Docker Scan** (Advanced)
- Runs on manual trigger
- Full control over ZAP Docker commands
- Customizable scan parameters

## 🎯 Usage

### Automatic Scans

Scans run automatically on:
- Push to `main` branch (Baseline scan)
- Pull requests (Baseline scan)
- Daily at 2 AM UTC (Full scan)

### Manual Trigger

1. Go to **Actions** tab in your GitHub repository
2. Select **OWASP ZAP DAST Scan** workflow
3. Click **Run workflow**
4. (Optional) Enter a custom target URL
5. Click **Run workflow** button

### View Results

#### In GitHub Actions
1. Go to **Actions** tab
2. Click on the latest workflow run
3. Scroll down to **Artifacts** section
4. Download `zap-baseline-report` or `zap-full-scan-report`

#### Reports Generated
- `report_html.html` - Detailed HTML report with all findings
- `report_json.json` - JSON format for integration with other tools
- `report_md.md` - Markdown summary for GitHub

#### GitHub Issues
The workflow automatically creates GitHub issues for findings (if `allow_issue_writing: true`).

## ⚙️ Configuration

### Customize Scan Rules

Edit `zap-rules.tsv` to:
- Disable specific rules (set threshold to `OFF`)
- Adjust sensitivity (LOW, MEDIUM, HIGH)
- Ignore false positives

Example:
```tsv
10202	OFF	DEFAULT	# Disable Anti-CSRF check
40012	HIGH	HIGH	# Increase XSS detection sensitivity
```

### Modify Workflow Triggers

Edit `.github/workflows/zap-scan.yml`:

```yaml
on:
  push:
    branches:
      - main
      - develop  # Add more branches
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
    - cron: '0 14 * * 1'  # Weekly on Monday at 2 PM
```

### Adjust Scan Options

In the workflow file, modify `cmd_options`:

```yaml
cmd_options: '-a -j -l INFO -d'
```

Options:
- `-a` : Include alpha (experimental) checks
- `-j` : Use AJAX spider
- `-l INFO` : Log level (INFO, DEBUG, WARN, ERROR)
- `-d` : Show debug messages
- `-m 5` : Maximum scan duration in minutes

## 🔧 Advanced Configuration

### Run ZAP Locally (for testing)

```bash
# Pull ZAP Docker image
docker pull ghcr.io/zaproxy/zaproxy:stable

# Run baseline scan
docker run -v $(pwd):/zap/wrk:rw ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py \
  -t http://your-ec2-ip:8080 \
  -r zap-report.html \
  -J zap-report.json

# Run full scan
docker run -v $(pwd):/zap/wrk:rw ghcr.io/zaproxy/zaproxy:stable \
  zap-full-scan.py \
  -t http://your-ec2-ip:8080 \
  -r zap-full-report.html
```

### Authentication (for protected apps)

If your Pet Clinic requires authentication, add a ZAP context file:

1. Create `zap-context.xml` with authentication details
2. Update workflow to use: `-n zap-context.xml`

### Fail Build on Findings

To fail the build if vulnerabilities are found, modify the workflow:

```yaml
- name: ZAP Baseline Scan
  uses: zaproxy/action-baseline@v0.12.0
  with:
    target: ${{ env.TARGET_URL }}
    fail_action: true  # Change to true
```

## 📊 Understanding Results

### Risk Levels

| Level | Description | Action |
|-------|-------------|--------|
| 🔴 **High** | Critical vulnerabilities requiring immediate attention | Fix ASAP |
| 🟠 **Medium** | Significant issues that should be addressed | Fix soon |
| 🟡 **Low** | Minor issues or hardening recommendations | Fix when possible |
| ℹ️ **Info** | Informational findings, not vulnerabilities | Review and consider |

### Common Findings in Pet Clinic

1. **Missing Security Headers**
   - X-Frame-Options
   - Content-Security-Policy
   - Strict-Transport-Security

2. **Cookie Issues**
   - Missing HttpOnly flag
   - Missing Secure flag

3. **SQL Injection** (if found, high priority!)
4. **Cross-Site Scripting (XSS)**
5. **Information Disclosure**

## 🛠️ Troubleshooting

### Scan Fails with Connection Error

**Issue**: Cannot connect to target URL

**Solutions**:
1. Verify EC2 instance is running: `aws ec2 describe-instances`
2. Check security group allows port 8080
3. Ensure Pet Clinic app is running: `curl http://your-ec2-ip:8080`
4. Check GitHub secret `PET_CLINIC_URL` is set correctly

### Scan Takes Too Long

**Solutions**:
1. Use baseline scan instead of full scan for quick checks
2. Add timeout: `cmd_options: '-a -j -l INFO -m 10'` (10 min max)
3. Reduce scan scope with exclusions

### False Positives

**Solutions**:
1. Review findings in the HTML report
2. Update `zap-rules.tsv` to disable specific rules
3. Add exclusions for specific URLs

## 📚 Resources

- [OWASP ZAP Documentation](https://www.zaproxy.org/docs/)
- [ZAP GitHub Actions](https://github.com/zaproxy/action-baseline)
- [ZAP Docker Images](https://hub.docker.com/r/zaproxy/zap-stable/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

## 🔐 Security Best Practices

1. **Never commit sensitive data** (passwords, API keys) to the repository
2. **Use GitHub Secrets** for all sensitive configuration
3. **Rotate credentials** regularly
4. **Review scan reports** after each run
5. **Fix High/Medium findings** before deploying to production
6. **Keep ZAP updated** by using the latest Docker image

## 📝 CI/CD Integration

### Integrate with Deployment Pipeline

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to EC2
        run: |
          # Your deployment steps
          
  security-scan:
    needs: deploy
    uses: ./.github/workflows/zap-scan.yml
    secrets: inherit
```

### Slack/Email Notifications

Add notification step to workflow:

```yaml
- name: Send Slack Notification
  if: always()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "ZAP Scan completed with ${{ steps.parse_results.outputs.high }} high findings"
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

## 🤝 Contributing

To improve this automation:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `act` or push to a test branch
5. Submit a pull request

## 📄 License

This configuration is provided as-is for educational and development purposes.

---

**Need Help?** Open an issue in this repository or consult the [OWASP ZAP documentation](https://www.zaproxy.org/docs/).
