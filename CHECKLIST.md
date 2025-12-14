# ✅ Setup Checklist for DVWA DAST Automation

## 🔧 GitHub Secrets Setup (REQUIRED)

Go to: https://github.com/lonerleo/Thesis/settings/secrets/actions

### 1. Add EC2_SSH_KEY
```
Name: EC2_SSH_KEY
Value: [Your private SSH key for EC2 13.49.91.130]
```

To get your SSH key:
```bash
# On your local machine or wherever you have SSH access to EC2
cat ~/.ssh/id_rsa
# or
cat ~/.ssh/your-key-name.pem
```

Copy the entire content including:
```
-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
```

### 2. Add ZAP_API_KEY
```
Name: ZAP_API_KEY
Value: [Your ZAP API key from 51.21.57.0]
```

To get ZAP API key:
- Open ZAP UI at http://51.21.57.0:8080
- Go to: Tools → Options → API
- Copy the API Key value

OR check ZAP configuration file:
```bash
ssh ubuntu@51.21.57.0
cat ~/.ZAP/config.xml | grep api.key
```

---

## 🧪 Verification Steps

### 1. Test EC2 Connection
```bash
ssh ubuntu@13.49.91.130
sudo docker ps
```
Expected: You should see the DVWA container running on port 80

### 2. Test ZAP Connection
```bash
curl http://51.21.57.0:8080
```
Expected: You should get a response from ZAP

### 3. Test DVWA Accessibility
```bash
curl http://13.49.91.130
```
Expected: HTML response from DVWA

---

## 🚀 Trigger First Scan

### Option 1: Manual Trigger (Recommended for first run)
1. Go to: https://github.com/lonerleo/Thesis/actions
2. Click "OWASP ZAP DAST Scan" workflow
3. Click "Run workflow"
4. Leave target URL empty (uses default)
5. Click "Run workflow"

### Option 2: Push a Change
```bash
cd "c:\Users\ArunkumarK\Downloads\project Z"
echo "# Test" >> README.md
git add README.md
git commit -m "Test automated deployment and scan"
git push origin main
```

---

## 📊 Expected Workflow Behavior

1. **Deploy DVWA Job** (~2-3 minutes)
   - Connects to 13.49.91.130 via SSH
   - Pulls latest DVWA image
   - Restarts container
   - Verifies deployment

2. **ZAP Scan Job** (~10-30 minutes)
   - Connects to ZAP at 51.21.57.0
   - Runs spider scan
   - Runs active scan  
   - Generates reports

3. **Results** 
   - Check Actions tab for live logs
   - Download artifacts (HTML/JSON reports)
   - View summary in GitHub Actions
   - Issues created for vulnerabilities

---

## 🔍 Common Issues & Solutions

### ❌ "Permission denied (publickey)"
**Problem**: EC2_SSH_KEY not configured correctly

**Solution**:
1. Verify the SSH key is the PRIVATE key (not public .pub)
2. Ensure no extra spaces or newlines
3. Key must match the key pair used for EC2

### ❌ "Connection refused to ZAP"
**Problem**: ZAP server not accessible

**Solution**:
```bash
# SSH into ZAP server
ssh ubuntu@51.21.57.0

# Check if ZAP is running
ps aux | grep zap
netstat -tulpn | grep 8080

# Start ZAP in daemon mode if needed
zap.sh -daemon -host 0.0.0.0 -port 8080 -config api.key=YOUR_API_KEY_HERE
```

### ❌ "DVWA not responding"
**Problem**: Container not running or crashed

**Solution**:
```bash
ssh ubuntu@13.49.91.130
sudo docker ps -a
sudo docker logs <container-id>
sudo docker restart <container-id>
```

### ❌ "ModuleNotFoundError: No module named 'zapv2'"
**Problem**: Python ZAP module not installed

**Solution**: Already handled in workflow, but if running locally:
```bash
pip install python-owasp-zap-v2.4
```

---

## 📝 What to Change for Customization

### Change DVWA IP Address
Edit `.github/workflows/zap-scan.yml`:
```yaml
env:
  DVWA_HOST: 'NEW.IP.ADDRESS.HERE'
  TARGET_URL: 'http://NEW.IP.ADDRESS.HERE'
```

### Change ZAP Server
Edit `.github/workflows/zap-scan.yml`:
```yaml
env:
  ZAP_HOST: 'NEW.ZAP.IP.HERE'
  ZAP_PORT: '8080'  # or your custom port
```

### Change SSH User (if not 'ubuntu')
Edit workflow SSH commands:
```yaml
ssh -i ~/.ssh/id_rsa YOUR_USER@${{ env.DVWA_HOST }} << 'EOF'
```

### Add Custom Deployment Steps
Edit the `deploy-dvwa` job to include your application files:
```yaml
- name: Copy Custom DVWA Config
  run: |
    scp -i ~/.ssh/id_rsa ./config.inc.php ubuntu@${{ env.DVWA_HOST }}:/path/to/dvwa/
```

---

## 🎯 Next Actions

1. ✅ Set up both GitHub Secrets (EC2_SSH_KEY and ZAP_API_KEY)
2. ✅ Verify connections to both servers
3. ✅ Run manual workflow test
4. ✅ Check workflow logs
5. ✅ Download and review scan reports
6. ✅ Customize scan rules if needed

---

## 📚 Files in This Repository

- `.github/workflows/zap-scan.yml` - Main workflow configuration
- `zap-remote-scan.py` - Python script for ZAP scanning
- `zap-rules.tsv` - Scan rules configuration
- `SETUP-INSTRUCTIONS.md` - Detailed setup guide
- `ZAP-DAST-README.md` - General DAST documentation
- `Research_Paper_DAST_Automation.md` - Research paper content

---

## 🆘 Need Help?

1. Check workflow logs in Actions tab
2. Review `SETUP-INSTRUCTIONS.md` for detailed help
3. Verify both servers are accessible
4. Check GitHub Secrets are correctly set

**Repository**: https://github.com/lonerleo/Thesis
**Actions**: https://github.com/lonerleo/Thesis/actions
