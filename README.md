# ShopSmart - Full Stack CI/CD Project

ShopSmart is a modern, production-ready web application built to demonstrate a complete DevSecOps pipeline using AWS, Docker, and Terraform.

## 🚀 Architecture Overview

### 1. Frontend
- **Framework**: React.js with Vite.
- **Testing**: Vitest for unit tests, Playwright for End-to-End (E2E) testing.
- **Styling**: Modern CSS with mobile-first responsiveness.

### 2. Backend
- **Engine**: Node.js / Express.js.
- **Security**: Non-root containerized execution, automated linting, and health checks.
- **Endpoints**: `/api/health` for monitoring.

### 3. Infrastructure (IaC)
- **Tool**: Terraform.
- **Compute**: AWS ECS Fargate (Serverless Containers).
- **Storage**: AWS S3 with versioning, SSE-S3 encryption, and blocked public access.
- **Networking**: VPC-integrated with security groups allowing traffic on port 5001.
- **Registry**: Amazon ECR (Elastic Container Registry).
- **Management**: Dedicated EC2 Management Server for remote status checks.

## ⚙️ CI/CD Workflow (.github/workflows/pipeline.yml)

The pipeline is triggered on every **Push** or **Pull Request** to the `main` branch:

1.  **Phase 1: Quality Control (Testing & Linting)**
    - Installs dependencies for Client and Server.
    - Runs **ESLint** to ensure code quality.
    - Runs **Unit Tests** (Jest/Vitest).
    - Runs **Integration Tests**.
2.  **Phase 2: Infrastructure Provisioning (Terraform)**
    - Initializes S3 Remote Backend.
    - Validates configuration.
    - Performs an idempotent `terraform apply` to provision AWS resources.
3.  **Phase 3: Containerization & Deployment**
    - Builds a secure, **multi-stage Docker image**.
    - Pushes image to Amazon ECR.
    - Deploys to **ECS Fargate** with rolling updates.
4.  **Phase 4: Verification (Bonus Marks)**
    - Runs **Playwright E2E tests** to verify user flows.
    - Performs an **SSH Status Check** on the EC2 Management Server.

## 🛡️ Design Decisions & Security

- **Multi-Stage Dockerfile**: Used to minimize the footprint of the final production image.
- **Non-Root User**: The container runs under a service user (`shopsmart`) to protect against privilege escalation.
- **Persistent State**: Terraform uses an S3 backend for state consistency across pipeline runs.
- **Idempotent Infrastructure**: Every script handles existing resources gracefully, preventing deployment crashes.

## 🛠️ Setup & Secrets

To run this project, configure the following **GitHub Secrets**:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`
- `AWS_REGION`
- `EC2_SSH_KEY` (Private key for Management Server)
- `EC2_HOST` (Public IP of Management Server)
