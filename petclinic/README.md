# PetClinic ZAP DAST Pipeline

This folder exists to trigger the PetClinic-specific GitHub Actions workflow. The workflow deploys PetClinic to the EC2 host and runs a ZAP baseline scan from the Windows ZAP server via AWS Systems Manager.

Key details:
- Host: 13.49.91.130
- Port: 8082
- App path: /petclinic
- Workflow: .github/workflows/zap-scan-petclinic.yml
- Trigger: any change under petclinic/**, PRs touching petclinic/**, manual dispatch, or scheduled cron.

Runbook summary:
1) GitHub Actions deploys PetClinic to EC2 (docker run -p 8082:9966 springcommunity/spring-petclinic-rest:latest).
2) Health check: http://13.49.91.130:8082/petclinic
3) ZAP baseline scan executed via SSM on the Windows ZAP server using zap.bat, report saved to C:\zap-reports.
4) Reports (HTML + log) are downloaded as artifacts.

Trigger note: Editing this README under petclinic/** is sufficient to fire the PetClinic workflow on push/PR....
