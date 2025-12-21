# AWS Systems Manager Setup Guide

## Overview
This guide shows how to set up AWS Systems Manager (SSM) to run ZAP scans on your Windows EC2 instance without exposing SSH ports.

## Prerequisites
✅ SSM Agent running on Windows instance (already verified)
✅ Windows instance has internet connectivity

## Step 1: Create IAM User for GitHub Actions

1. **Go to AWS IAM Console**
   - AWS Console → Services → IAM

2. **Create New User**
   - Click "Users" → "Create user"
   - User name: `github-actions-zap`
   - Click "Next"

3. **Attach Policies**
   - Select "Attach policies directly"
   - Search and select these policies:
     - `AmazonSSMManagedInstanceCore` (for SSM access)
     - `AmazonSSMFullAccess` (for sending commands)
   - Click "Next" → "Create user"

4. **Create Access Keys**
   - Click on the user you just created
   - Go to "Security credentials" tab
   - Click "Create access key"
   - Select "Application running outside AWS"
   - Click "Next" → "Create access key"
   - **IMPORTANT**: Copy the Access Key ID and Secret Access Key

## Step 2: Attach IAM Role to Windows Instance

1. **Create IAM Role for EC2**
   - IAM Console → Roles → "Create role"
   - Select "AWS service" → "EC2"
   - Click "Next"

2. **Attach Policy**
   - Search and select: `AmazonSSMManagedInstanceCore`
   - Click "Next"

3. **Name the Role**
   - Role name: `EC2-SSM-Role`
   - Click "Create role"

4. **Attach Role to Windows Instance**
   - Go to EC2 Console → Instances
   - Select your Windows ZAP instance
   - Actions → Security → Modify IAM role
   - Select `EC2-SSM-Role`
   - Click "Update IAM role"

## Step 3: Get Windows Instance ID

On your Windows server, run:
```powershell
Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/instance-id
```

Example output: `i-0123456789abcdef0`

## Step 4: Add Secrets to GitHub

1. **Go to your GitHub repository**
   - https://github.com/lonerleo/Thesis

2. **Add the following secrets** (Settings → Secrets and variables → Actions → New repository secret):

   **Secret 1: AWS_ACCESS_KEY_ID**
   - Value: (The Access Key ID from Step 1)

   **Secret 2: AWS_SECRET_ACCESS_KEY**
   - Value: (The Secret Access Key from Step 1)

   **Secret 3: WINDOWS_INSTANCE_ID**
   - Value: (The instance ID from Step 3, e.g., `i-0123456789abcdef0`)

## Step 5: Verify SSM Connectivity

After attaching the IAM role, wait 2-3 minutes, then verify the instance appears in SSM:

1. **AWS Console → Systems Manager → Fleet Manager**
2. Look for your Windows instance
3. It should show as "Online" or "Managed"

If it doesn't appear, restart the SSM Agent on Windows:
```powershell
Restart-Service AmazonSSMAgent
Get-Service AmazonSSMAgent
```

## Step 6: Test SSM Command (Optional)

Test if SSM can execute commands on your instance:

```bash
aws ssm send-command \
  --instance-ids i-YOUR_INSTANCE_ID \
  --document-name "AWS-RunPowerShellScript" \
  --parameters 'commands=["Get-Service AmazonSSMAgent"]' \
  --region eu-north-1
```

## Advantages of SSM vs SSH

| Feature | SSH | AWS SSM |
|---------|-----|---------|
| Port exposure | Requires port 22 open | No ports needed |
| Security | Firewall rules needed | IAM-based auth |
| Network config | Complex (SG, NACL, Routes) | Simple |
| Audit trail | Manual logging | Built-in CloudTrail |
| Works in private subnet | No | Yes |
| Best practice | Legacy | Cloud-native |

## Security Benefits

1. **No port 22 exposure** - Reduces attack surface
2. **IAM-based authentication** - Fine-grained permissions
3. **Audit trail** - All commands logged in CloudTrail
4. **Session encryption** - Automatic TLS encryption
5. **No key management** - No SSH keys to rotate

## Troubleshooting

### Instance not appearing in Fleet Manager
- Verify IAM role is attached to EC2 instance
- Restart SSM Agent: `Restart-Service AmazonSSMAgent`
- Check instance has internet connectivity
- Wait 5 minutes for registration

### Command execution fails
- Verify IAM user has SSM permissions
- Check AWS region matches (eu-north-1)
- Verify instance ID is correct

### Report download fails
- Ensure ZAP reports directory exists: `C:\zap-reports`
- Check ZAP scan completed successfully
- Verify file permissions

## Next Steps

After completing this setup:
1. Push the updated workflow to GitHub
2. Trigger a test run
3. Monitor in GitHub Actions: https://github.com/lonerleo/Thesis/actions
4. Download reports from Artifacts
5. View detailed results in ZAP GUI via RDP
