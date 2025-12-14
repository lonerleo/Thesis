# DVWA DAST Automation Setup Instructions

## Overview
This workflow automatically deploys DVWA (Damn Vulnerable Web Application) changes and runs OWASP ZAP security scans.

**Infrastructure:**
- **DVWA Server**: 13.49.91.130 (running Docker container)
- **ZAP Server**: 51.21.57.0 (OWASP ZAP instance)

## Prerequisites

### 1. GitHub Secrets Configuration

Go to your repository → **Settings** → **Secrets and variables** → **Actions** and add:

#### Required Secrets:

1. **`EC2_SSH_KEY`** (Private SSH key for EC2 access)
   ```
   -----BEGIN RSA PRIVATE KEY-----
   Your private key content here...
   -----END RSA PRIVATE KEY-----
   ```

2. **`ZAP_API_KEY`** (ZAP API Key)
   - Get this from your ZAP instance at http://51.21.57.0:8080
   - ZAP → Tools → Options → API → API Key

#### Optional Secrets:

3. **`DVWA_SSH_USER`** (default: `ubuntu`)
4. **`DVWA_CONTAINER_NAME`** (default: auto-detected)

### 2. EC2 Server Setup (13.49.91.130)

SSH into your DVWA server:
```bash
ssh ubuntu@13.49.91.130
```

Ensure Docker is running and DVWA is accessible:
```bash
# Check Docker is running
sudo systemctl status docker

# Check DVWA container
sudo docker ps | grep dvwa

# Test DVWA accessibility
curl http://localhost
```

### 3. ZAP Server Setup (51.21.57.0)

Ensure ZAP is running in daemon mode:
```bash
# Check ZAP is running
curl http://51.21.57.0:8080

# If not running, start ZAP in daemon mode:
zap.sh -daemon -host 0.0.0.0 -port 8080 -config api.key=YOUR_API_KEY
```

## Workflow Behavior

### Triggers:
- **Push to main branch**: Deploys DVWA + runs baseline scan
- **Pull Request**: Preview scan without deployment
- **Manual trigger**: Full control over scan type
- **Schedule**: Daily full scans at 2 AM UTC

### Jobs:

1. **deploy-dvwa**
   - Connects to EC2 via SSH
   - Pulls latest DVWA Docker image
   - Restarts DVWA container
   - Verifies deployment

2. **zap-baseline-scan**
   - Uses remote ZAP instance (51.21.57.0)
   - Runs spider scan
   - Runs active scan
   - Generates reports

3. **process-results**
   - Parses scan results
   - Creates GitHub issues for vulnerabilities
   - Comments on PRs with summary

## Usage

### Making Changes to DVWA

1. **Modify your application code** (if customizing DVWA)
2. **Commit and push** to main branch:
   ```bash
   git add .
   git commit -m "Update DVWA configuration"
   git push origin main
   ```

3. **GitHub Actions will automatically**:
   - Deploy changes to 13.49.91.130
   - Wait for application to be ready
   - Run ZAP security scans
   - Generate reports

### Manual Scan Trigger

1. Go to **Actions** tab in GitHub
2. Select **OWASP ZAP DAST Scan** workflow
3. Click **Run workflow**
4. Optionally override target URL
5. Click **Run workflow** button

### View Results

1. Go to **Actions** tab
2. Click on the workflow run
3. View scan progress in real-time
4. Download reports from **Artifacts** section
5. Check **Issues** tab for created vulnerabilities

## Customizing Scans

### Edit Scan Rules

Modify [`zap-rules.tsv`](zap-rules.tsv) to:
- Disable specific vulnerability checks
- Adjust sensitivity levels
- Ignore false positives

Example:
```tsv
40012	HIGH	HIGH	# XSS Detection - High sensitivity
10202	OFF	DEFAULT	# CSRF - Disabled for testing
```

### Adjust Scan Targets

Edit [`.github/workflows/zap-scan.yml`](.github/workflows/zap-scan.yml):

```yaml
env:
  TARGET_URL: 'http://13.49.91.130/specific-path'  # Target specific path
  DVWA_HOST: '13.49.91.130'  # Change if IP changes
  ZAP_HOST: '51.21.57.0'  # Change if ZAP moves
```

## Troubleshooting

### Deployment Fails

**Issue**: Cannot connect to EC2
```
Solution:
1. Verify EC2_SSH_KEY secret is correct
2. Check EC2 security group allows SSH (port 22)
3. Verify IP address is correct (13.49.91.130)
```

**Issue**: Docker command fails
```
Solution:
1. SSH into EC2: ssh ubuntu@13.49.91.130
2. Check Docker service: sudo systemctl status docker
3. Check user permissions: sudo usermod -aG docker ubuntu
```

### ZAP Scan Fails

**Issue**: Cannot connect to ZAP server
```
Solution:
1. Verify ZAP is running: curl http://51.21.57.0:8080
2. Check ZAP_API_KEY secret is correct
3. Ensure ZAP allows remote connections
4. Check firewall/security group for port 8080
```

**Issue**: Scan timeout
```
Solution:
1. Increase timeout in workflow (edit sleep values)
2. Run lighter baseline scan instead of full scan
3. Exclude non-critical paths from scanning
```

### DVWA Not Responding

**Issue**: Deployment succeeds but DVWA unreachable
```
Solution:
1. Check container logs:
   sudo docker logs $(sudo docker ps -q --filter ancestor=vulnerables/web-dvwa)

2. Check container status:
   sudo docker ps -a

3. Manually restart:
   sudo docker restart <container-id>

4. Check port mapping:
   sudo docker port <container-id>
```

## Architecture Diagram

```
┌─────────────────┐
│   GitHub Repo   │
│   (Code Push)   │
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│  GitHub Actions     │
│  (Runner)           │
└──┬────────────┬─────┘
   │            │
   │ Deploy     │ Scan via API
   ▼            ▼
┌─────────┐  ┌──────────┐      ┌──────────────┐
│  EC2    │  │   ZAP    │──────▶│    DVWA      │
│ (SSH)   │  │51.21.57.0│ Scans │13.49.91.130  │
└─────────┘  └──────────┘      └──────────────┘
                  │
                  ▼
            ┌──────────────┐
            │   Reports    │
            │ (Artifacts)  │
            └──────────────┘
```

## Security Notes

⚠️ **Important Security Considerations:**

1. **Never commit sensitive data**:
   - SSH keys
   - API keys
   - Passwords

2. **Use GitHub Secrets** for all credentials

3. **Restrict EC2 Security Groups**:
   - Allow SSH only from GitHub Actions IPs
   - Restrict ZAP port 8080 access

4. **DVWA is intentionally vulnerable**:
   - Never expose to public internet in production
   - Use only for testing/training
   - Run in isolated environment

5. **ZAP Server Security**:
   - Set strong API key
   - Restrict network access
   - Keep ZAP updated

## Next Steps

1. ✅ Set up GitHub Secrets
2. ✅ Verify EC2 and ZAP connectivity
3. ✅ Test manual workflow run
4. ✅ Make a test commit to trigger automation
5. ✅ Review generated reports
6. ✅ Customize scan rules as needed
7. ✅ Set up notifications (Slack/Email)

## Support

For issues or questions:
1. Check workflow logs in Actions tab
2. Review this documentation
3. Check ZAP server logs
4. Verify EC2 container status

## References

- [OWASP ZAP Documentation](https://www.zaproxy.org/docs/)
- [DVWA Documentation](https://github.com/digininja/DVWA)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [ZAP Python API](https://github.com/zaproxy/zap-api-python)
