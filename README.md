#  CI/CD Pipeline – GitHub Actions (Build Once, Promote Safely)

##  Overview

This repository implements a **build-once, promote-many** CI/CD pipeline using **GitHub Actions**, **AWS EKS**, **Helm**, and **Amazon ECR**.

The pipeline guarantees:

-  Single build per release
-  Same commit SHA promoted across DEV → BETA → PROD
-  Strict environment order enforcement
-  Manual approvals for all deployments
-  Full audit and traceability
-  GitOps-friendly versioning

This design intentionally prevents:
- rebuilding in downstream environments
- skipping environments
- deploying unapproved artifacts

---

##  Core Design Principles

### 1️⃣ Build Once, Version Once
- Application is built only **one time**
- A semantic version (`vX.Y.Z`) is generated
- Docker image is tagged with:
  - semantic version
  - commit SHA

### 2️⃣ Promote, Don’t Rebuild
- DEV, BETA, and PROD reuse the **same Docker image**
- No environment-specific rebuilds
- No mutable tags like `latest`

### 3️⃣ GitHub Release = Promotion Anchor
GitHub Releases act as the **single source of truth** and store:
- Docker image reference
- Commit SHA
- Promotion status (DEV/BETA/PROD)

### 4️⃣ Hard Environment Ordering
Promotion order is strictly enforced:
```
Pre-Deploy → DEV → BETA → PROD
```

Each environment validates that the **previous environment** was successfully deployed.

---

## 🗂 Workflow Structure
```
.github/workflows/
│
├── 01-pre-deploy-env.yml
├── 02-deploy-dev.yml
├── 03-deploy-beta.yml
└── 04-deploy-prod.yml
```

---

## 🔁 Promotion Flow

```
pre-deploy-env
↓
deploy-dev → marks DEV_DEPLOYED=true
↓
deploy-beta → checks DEV, marks BETA_DEPLOYED=true
↓
deploy-prod → checks BETA, marks PROD_DEPLOYED=true
```

#- Skipping environments is impossible  
#- Rebuilding after pre-deploy is impossible  

---

## 📄 Workflow Details

---

## 01️⃣ Pre-Deploy Environment  
**`pre-deploy-env.yml`**

**Trigger:** Manual  
**Purpose:** Build and version the application exactly once

### Jobs

#### Versioning
- Reads `version.txt`
- Auto-increments patch version
- Commits version bump
- Creates semantic Git tag (`vX.Y.Z`)

#### Build Image
- Builds Docker image
- Tags image as:
  - `<version>_<commitSHA>`
- Pushes image to Amazon ECR

#### Post-Build Scan
- Scans container image for vulnerabilities
- Fails pipeline on critical/high issues

#### Release Creation
- Creates GitHub Release for `vX.Y.Z`
- Stores:
  - Docker image reference
  - Commit SHA

> This release becomes the promotion anchor for all environments.

---

## 02️⃣ Deploy to DEV  
**`deploy-dev.yml`**

**Trigger:** Manual  
**Environment:** `dev`

### Responsibilities
- Validates GitHub Release exists
- Extracts Docker image from release
- Deploys to DEV EKS cluster using Helm
- Runs post-deploy smoke tests
- Marks release as:

- Sends DEV deployment notification

---
## 03️⃣ Deploy to BETA  
**`deploy-beta.yml`**

**Trigger:** Manual  
**Environment:** `beta`

### Hard Gate
Before deploying, the workflow verifies:

DEV_DEPLOYED=true

If DEV is not deployed, the workflow fails immediately.

### Responsibilities
- Deploys the same image used in DEV
- Runs:
  - readiness checks
  - E2E tests
  - DAST scans
  - performance tests
- Marks release as:
BETA_DEPLOYED=true
- Sends BETA deployment notification

---

## 04️⃣ Deploy to PROD  
**`deploy-prod.yml`**

**Trigger:** Manual  
**Environment:** `prod`

### Hard Gate
Before deploying, the workflow verifies:
BETA_DEPLOYED=true

If BETA is not deployed, the workflow fails immediately.

### Jobs

#### Pre-Deploy Validation (Non-Blocking)
- Captures PROD SLO/SLA baseline
- Failures do not block deployment

#### Deploy to PROD
- Deploys the same Docker image built in pre-deploy
- No rebuilds or retagging

#### Post-Deploy Validation (Blocking)
- Health checks
- Performance tests
- SLO/SLA comparison
- Fails on unacceptable regression

####  Notification
- Marks release as: PROD_DEPLOYED=true
- Sends PROD deployment notification

---

##  Environment & Secrets

### Common Environment Variables
Defined at the top of every workflow:

```yml
env:
AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
AWS_REGION: us-east-1
```
##Audit & Traceability

#For every deployment, you can trace:

- Git tag (vX.Y.Z)

- Commit SHA

- Docker image

- Scan results

- Environment promotion history

- All information is available via GitHub Releases.
 
