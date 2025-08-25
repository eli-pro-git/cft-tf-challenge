

````markdown
## Part 2 — SRE Operations, Analysis, and Improvements
Architecture Diagram
![new design](https://github.com/eli-pro-git/cft-tf-challenge/blob/cfc-challenge-part-2/image-4.png?raw=true)

> **Scope:** Operate the Terraform PoC as an SRE. Document risks, availability, cost, and ops gaps; propose and prioritize improvements; implement at least two; provide runbooks and evidence.

---

### What changed in Part 2 (summary)

- **Network hardening & HA**
  - Expanded to **6 subnets** (2x management/public, 2x application/private, 2x backend/private) across **us-east-1a & 1b**.
  - **One NAT Gateway per AZ** (egress survives single-AZ failure).
- **Security**
  - **IMDSv2 enforced** on bastion + app instances.
- **Observability**
  - **CloudWatch alarms + SNS** (ASG health, bastion health/CPU).
  - **VPC Flow Logs → CloudWatch Logs** (30-day retention).
- **Operations**
  - **SSM Session Manager** enabled (keyless access & audit trail).

---

## A. Analysis of Deployed Infrastructure

### Security gaps
- **Human SSH exposure** on bastion (keys can be mishandled; no session recording by default).  
  *Mitigation:* Prefer **SSM Session Manager** for routine access; keep SSH for break-glass.
- **Broad egress** (0.0.0.0/0) on app/bastion SGs (common for PoC).  
  *Mitigation:* Restrict egress by destination (VPC endpoints, proxy).
- **No WAF/HTTPS termination** (internal ALB; when made public, add ACM + WAF + TLS).
- **No organization-wide audit** (CloudTrail org trail not configured here).  
  *Mitigation:* Central CloudTrail + S3 immutable bucket (Object Lock).

### Availability issues
- App ASG now **multi-AZ** (application_a + application_b).  
- NAT now **per AZ**; private egress remains during single-AZ impairment.  
- Internal ALB (by design). If public access is required, add **2 public subnets** and flip ALB to internet-facing.

### Cost optimization opportunities
- **NAT Gateway x2**: hourly + data processing. In dev, consider:
  - SSM/CloudWatch **Interface Endpoints** to reduce NAT traffic.
  - Scheduled **ASG scale-in** off hours (min=1).
- Use **t3.micro** (cheaper/more efficient) if performance acceptable.
- Set **log retention** deliberately (30 days now; tune per policy).
- Avoid idle EIPs/ALB in non-testing windows.

### Operational shortcomings
- No automated patching baseline (Patch Manager).  
- No **backup plan** for app data (PoC serves static Apache page).  
- No continuous config/compliance checks (AWS Config, tfsec/tflint in CI).  
- Limited runbooks (addressed below).

---

## B. Improvement Plan (prioritized)

| Priority | Improvement | Rationale | Status / Where |
|---|---|---|---|
| **P0** | **Enforce IMDSv2** on all EC2 | Reduce metadata/credential theft risk |  Implemented (`bastion` & `app` launch template) |
| **P0** | **Baseline alarms + SNS** (ASG InService, bastion status/CPU) | Detect failures early |  Implemented (`observability` module) |
| **P1** | **SSM Session Manager** | Keyless access, audit, no public SSH needed |  Implemented (`ssm` module) |
| **P1** | **VPC Flow Logs → CW Logs** | Forensics, traffic anomaly detection |  Implemented (`vpc_flow_logs` module) |
| **P1** | **Interface Endpoints** (SSM, SSM Messages, EC2 Messages, S3) | Reduce NAT cost/dependency | Next |
| **P1** | **Public ALB option** (if needed): 2 public subnets, HTTPS (ACM), WAF | Internet exposure w/ security | Next |
| **P2** | **Restrict egress** in SGs / use egress proxy | Least privilege | Next |
| **P2** | **AWS Backup** plans for EBS/S3 (if state/data added) | Recoverability | Next |
| **P2** | **Config + GuardDuty + Security Hub** | Continuous monitoring | Next |
| **P3** | **CI checks** (tflint/tfsec), drift detection | Maintainability | Next |

> **Implemented improvements (code):**  
> 1) IMDSv2 enforcement (bastion + app LT)  
> 2) CloudWatch alarms + SNS topic  
> 3) SSM Session Manager (role/profile + attachments)  
> 4) VPC Flow Logs (log group + role + flow log)

---

## C. Runbook (deploy, operate, outage, restore)

### Deploy / Update (operator steps)
1. **Initialize & plan**
   ```bash
   terraform init
   terraform plan \
     -var 'aws_region=us-east-1' \
     -var 'vpc_cidr=10.1.0.0/16' \
     -var 'project=cpmc' \
     -var 'environment=dev' \
     -var 'bastion_allowed_ssh_cidr=YOUR.IP/32' \
     -var 'bastion_key_name=YOUR_KEYPAIR_NAME' \
     -var 'alerts_email=YOUR.EMAIL@example.com'
````

2. **Apply**

   ```bash
   terraform apply -auto-approve ... (same vars)
   ```
3. **Post-apply**

   * Confirm **SNS subscription email** (check inbox).
   * Record outputs: `bastion_public_ip`, `alb_dns_name`, `alerts_topic_arn`, flow-logs log group.

### Day-2 Ops (access, logs, checks)

* **Access (preferred):** SSM

  ```bash
  aws ssm describe-instance-information --query 'InstanceInformationList[].InstanceId'
  aws ssm start-session --target i-XXXXXXXXXXXX
  ```
* **Access (break-glass):** SSH to bastion, then to app.
* **App health:** from bastion

  ```bash
  curl -s http://$(terraform output -raw alb_dns_name)
  systemctl status httpd
  ```
* **Logs & network:** CloudWatch Logs → `/vpc/<project>/<env>/flow-logs`; instance `/var/log/cloud-init*`.

### EC2 (App) outage response

1. **Alarm fires** (ASG InService low). Check **Auto Scaling events** for failed launches/terminations.
2. Verify **subnet/NAT** in affected AZ; check AMI accessibility, SG rules, instance profile.
3. **Mitigate quickly:** temporarily increase desired capacity; if LT broken, roll back to last known good AMI/LT version.
4. If ALB is used: check **Target health** and health check path `/`.

### “S3 bucket deleted” restore (when S3 is in scope)

* **Prevention to implement:** S3 **Versioning**, **SSE**, **Block Public Access**, optional **MFA Delete**, **Object Lock** (compliance).
* **Investigate:** CloudTrail to identify actor/time.
* **Restore path:**

  * If only objects deleted → **undelete** prior versions.
  * If bucket deleted → recreate (name may be held briefly), **restore from backup/replica**, re-apply bucket policies/lifecycle & producers.

---

## D. Evidence of Deployment

Place screenshots/outputs under `docs/assets/` and reference here:

* **Subnets & routing (multi-AZ)** – console screenshots
* **NAT per AZ** – console list (IDs in each AZ)
* **ASG (min=2) across 1a/1b** – EC2 Auto Scaling view
* **ALB (internal) active** – Target Group healthy targets
* **Bastion reachable** – CLI output (public IP + SSM session)
* **CloudWatch alarms** – list + one alarm test (see below)
* **VPC Flow Logs** – log group with active streams
* **Terraform apply logs** – excerpt showing created resources

> **Alarm test (optional):** temporarily set ASG `desired_capacity=0`, apply, wait for alarm, then revert to `2`.

---

## E. Design decisions & assumptions

* **Internal ALB** by default: meets “ALB → ASG” privately; easily switchable to public when desired (add 2nd public subnet + ACM + WAF).
* **NAT per AZ:** higher cost, higher resilience; chosen for **availability** of private egress.
* **IMDSv2 enforced:** modern baseline to limit credential exposure vectors.
* **SSM** over SSH for routine ops: central audit, least exposure.
* **Broad egress for PoC:** retained for speed; plan to constrain with endpoints/proxy.
* **No persistent app data** in PoC: Apache static page; backups marked as future work.

---

## F. How to reproduce the implemented improvements

* **IMDSv2:**

  * Bastion: `aws_instance.bastion.metadata_options.http_tokens = "required"`
  * App LT: `aws_launch_template.app.metadata_options.http_tokens = "required"`
* **Observability:**

  * `modules/observability` → SNS topic + 3 alarms (ASG in-service low, bastion status check fail, bastion CPU high).
* **SSM:**

  * `modules/ssm` → role + instance profile; attached to bastion & app LT.
  * Test: `aws ssm start-session --target <InstanceId>`
* **VPC Flow Logs:**

  * `modules/vpc_flow_logs` → log group (30 days), IAM role/policy, flow log resource (ALL traffic).

---

## G. References

* AWS Well-Architected Framework (Security, Reliability, Cost)
* Amazon EC2 Instance Metadata Service v2 (IMDSv2)
* Amazon CloudWatch Alarms & Auto Scaling metrics
* AWS Systems Manager Session Manager
* Amazon VPC Flow Logs

> See repository `modules/*` for exact Terraform implementation.

```
