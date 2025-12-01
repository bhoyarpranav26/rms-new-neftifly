# Infra (terraform) — short README

This README explains the current Terraform workspace (C:\RestoM-11\mern_infra\terraform), what was applied, key outputs, and next steps for working with the infra and CI/CD.

## What was applied
- VPC with public and private subnets (private subnets used by RDS).
- ECS cluster and Fargate service (task definition created).
- ECR repository for backend images.
- S3 bucket for frontend (unique random suffix).
- RDS PostgreSQL (private, multi-AZ-aware subnets).
- IAM roles/policies and CloudWatch log group.

Note: ALB and CloudFront are disabled by default because the current AWS account blocked those services earlier; they are gated by `create_alb` and `create_cloudfront` variables.

## Important outputs (from most recent apply)
- ECR repo: `111227928158.dkr.ecr.us-east-1.amazonaws.com/restom-app`
- RDS endpoint: `restom-db.c23wy8yue23f.us-east-1.rds.amazonaws.com`
- S3 bucket: `restom-frontend-<suffix>` (the exact name is recorded in the Terraform state)
- ALB / CloudFront outputs are empty because they were not created in this account.

To view outputs yourself:

```powershell
terraform -chdir=C:\RestoM-11\mern_infra\terraform output
```

## Quick Terraform commands
- Validate and plan:

```powershell
terraform -chdir=C:\RestoM-11\mern_infra\terraform init
terraform -chdir=C:\RestoM-11\mern_infra\terraform plan -var-file=terraform.tfvars
```

- Apply (current defaults disable ALB/CloudFront):

```powershell
terraform -chdir=C:\RestoM-11\mern_infra\terraform apply -var-file=terraform.tfvars -auto-approve
```

- Destroy (will remove resources — confirm before running):

```powershell
terraform -chdir=C:\RestoM-11\mern_infra\terraform destroy -var-file=terraform.tfvars -auto-approve
```

## Enabling ALB and CloudFront
If you want ALB and/or CloudFront created, update `terraform.tfvars` (or pass variables on the command line) and ensure your AWS account supports these services:

```
create_alb = true
create_cloudfront = true
```

Notes:
- CloudFront may require AWS account verification with Support before creating distributions.
- Some AWS accounts disallow ELB/ALB creation; enable it or use a different account if needed.

After enabling, run `terraform plan` and `terraform apply` to create those resources.

## Pushing your backend image to ECR and updating ECS
1. Authenticate Docker to ECR (PowerShell):

```powershell
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 111227928158.dkr.ecr.us-east-1.amazonaws.com
```

2. Build and tag (example):

```powershell
docker build -t restom-app:latest ../..\backend\
docker tag restom-app:latest 111227928158.dkr.ecr.us-east-1.amazonaws.com/restom-app:latest
```

3. Push:

```powershell
docker push 111227928158.dkr.ecr.us-east-1.amazonaws.com/restom-app:latest
```

4. Update ECS service to use the new image: either use the GitHub Actions workflow (already added) or update the task definition image and run `terraform apply` (if you keep image tag variables), or use `aws ecs update-service --cluster restom-cluster --service restom-service --force-new-deployment`.

## Connecting to RDS (private)
RDS is private inside the VPC. Options to connect:
- Use a bastion EC2 in the same VPC (not provisioned by default).
- Use AWS Session Manager and an instance with the SSM agent.
- Use a VPN or Direct Connect into the VPC network.

If you want a quick temporary public-facing access (not recommended for production), we can modify the DB to be publicly accessible (infrastructure change + security controls).

Example local psql command (works only if you have network access to the DB):

```powershell
psql "host=restom-db.c23wy8yue23f.us-east-1.rds.amazonaws.com port=5432 user=<db_user> dbname=<db_name> password=<db_password> sslmode=require"
```

The DB credentials are stored as Terraform outputs/secrets in state; if you used `random_password` they are in the state or secrets manager depending on the config.

## Cost & cleanup
This deployment includes RDS and Fargate — both incur charges. If you want to avoid ongoing costs, run the destroy command above.

## Next steps I can do for you
- Attempt a connectivity test to the RDS instance from this environment (requires network/bastion access) — tell me to try.
- Enable ALB/CloudFront and re-run apply (you must confirm account support).
- Create a small README in the repo (done) and expand with CI/CD instructions (I can add more).
- Tear down resources with `terraform destroy` (explicit confirmation required).

---
File created: `C:\RestoM-11\mern_infra\terraform\README.md` — short ops/readme for the Terraform workspace.
