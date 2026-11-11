# 🚀 Docker CI/CD Capstone | DevOps Winter Arc

## 📌 Project Overview

This project demonstrates an end-to-end CI/CD pipeline for a Dockerized Python Flask application using GitHub Actions, Docker Hub, and AWS EC2.

The objective is to automate application validation, container image creation, security scanning, image publishing, and deployment to a remote Ubuntu server.

The project also demonstrates manual rollback using Git SHA-tagged Docker images.

### Key Features

- **Containerization:** Multi-stage Dockerfile with a non-root application user.
- **Automated CI:** GitHub Actions runs Dockerfile linting, image builds, and application smoke tests.
- **Security Scanning:** Hadolint validates Dockerfile practices, while Trivy checks container images for HIGH and CRITICAL vulnerabilities.
- **Container Registry:** Docker images are published to Docker Hub using full Git commit SHA tags.
- **Automated CD:** GitHub Actions connects to AWS EC2 over SSH and executes a dedicated deployment script.
- **Health Checks:** Application health is verified after deployment.
- **Manual Rollback:** Previous Docker image versions can be redeployed using their Git SHA tags.

## 🛠️ Technology Stack

| Component | Technology |
|---|---|
| Application | Python, Flask |
| Containerization | Docker, multi-stage builds |
| CI/CD | GitHub Actions |
| Dockerfile Linting | Hadolint |
| Container Security | Trivy |
| Container Registry | Docker Hub |
| Cloud Infrastructure | AWS EC2 |
| Operating System | Ubuntu Linux |
| Remote Deployment | SSH |
| Automation | Bash |
| Version Control | Git and GitHub |

## 🏗️ CI/CD Architecture

```text
Developer
    |
    | git push origin main
    v
GitHub Repository
    |
    v
GitHub Actions
    |
    +-- Hadolint Dockerfile Linting
    |
    +-- Build Docker Image
    |
    +-- Run Container + Smoke Test
    |
    +-- Trivy Vulnerability Scan
    |
    +-- Authenticate to Docker Hub
    |
    +-- Publish Image with Git SHA Tag
    |
    v
Docker Hub
    |
    | anujjain21/winter-arc-app:<git-sha>
    |
    v
GitHub Actions Deployment Job
    |
    | SSH authentication
    | SSH host-key verification
    v
AWS EC2 (Ubuntu)
    |
    +-- Execute restricted deployment script
    |
    +-- Pull SHA-tagged Docker image
    |
    +-- Replace application container
    |
    +-- Start Flask application
    |
    +-- Verify /health endpoint
    |
    v
Deployment Successful
```

### Pipeline Execution

**Continuous Integration (CI)**

On pushes to `main` and pull requests targeting `main`, GitHub Actions validates the Dockerfile, builds the image, runs smoke tests, and performs vulnerability scanning.

**Image Publishing**

After successful validation, pushes to `main` publish the Docker image to Docker Hub using the full Git commit SHA.

**Continuous Deployment (CD)**

After the CI and publishing job succeeds on `main`, a separate deployment job connects to EC2 using SSH and invokes the deployment script with the corresponding Git SHA.

**Rollback**

An earlier SHA-tagged image can be deployed manually using the same script. This replaces the running container with one created from the selected image.

## 📁 Project Structure

```text
day7-cicd/
├── .github/
│   └── workflows/
│       └── docker-ci.yml
├── scripts/
│   └── smoke-test.sh
├── .dockerignore
├── .gitattributes
├── .gitignore
├── Dockerfile
├── app.py
├── requirements.txt
└── README.md
```

### Important Files

| File | Purpose |
|---|---|
| `app.py` | Flask application with `/` and `/health` endpoints |
| `requirements.txt` | Python application dependencies |
| `Dockerfile` | Multi-stage container image build |
| `.dockerignore` | Excludes unnecessary files from the Docker build context |
| `.gitignore` | Prevents local and sensitive files from being committed |
| `.gitattributes` | Enforces consistent line endings for selected files |
| `scripts/smoke-test.sh` | Verifies the application health endpoint |
| `.github/workflows/docker-ci.yml` | Defines the automated CI/CD pipeline |

## 🐳 Docker Containerization

The Flask application is packaged into a Docker image using a multi-stage Dockerfile.

### Multi-Stage Build

**Stage 1 — Dependency Installation**

```dockerfile
FROM python:3.12-slim AS build

WORKDIR /w

COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt
```

This stage installs the application's Python dependencies into `/install`.

**Stage 2 — Runtime Image**

```dockerfile
FROM python:3.12-slim

RUN useradd -r -u 10001 app

WORKDIR /app

COPY --from=build /install /usr/local

COPY --chown=app:app app.py .

USER app

EXPOSE 5000
```

The runtime stage copies the installed dependencies from the build stage, adds the application, and runs it as a non-root user.

The final Dockerfile also includes the dependency security fix, application health check, and startup command.

### Important Docker Concepts

- `FROM` — Selects the base image.
- `WORKDIR` — Defines the working directory for subsequent instructions.
- `COPY` — Copies files into the image.
- `COPY --from=build` — Copies artifacts from another build stage.
- `COPY --chown` — Sets ownership of copied files.
- `USER` — Specifies the runtime user.
- `EXPOSE` — Documents the application's listening port.
- `HEALTHCHECK` — Configures Docker's application health monitoring.
- `CMD` — Defines the default container startup command.

### Security Improvements

The image applies several basic security practices:

1. Uses the smaller `python:3.12-slim` base image.
2. Separates dependency installation from the final runtime stage.
3. Runs the application using a non-root user with UID `10001`.
4. Avoids copying unnecessary local files through `.dockerignore`.
5. Uses Trivy to scan for HIGH and CRITICAL vulnerabilities.
6. Includes an updated `zlib1g` package to address vulnerabilities identified during CI.

## 🧪 Local Docker Testing

### Build the Application Image

```bash
docker build --pull -t winter-arc-app:v1 .
```

The `--pull` option requests newer versions of base images referenced by the Dockerfile.

### Start the Container

```bash
docker run -d \
  --name winter-arc-test \
  -p 5000:5000 \
  -e APP_ENV=test \
  winter-arc-app:v1
```

**Command explanation:**

| Option | Description |
|---|---|
| `-d` | Runs the container in detached mode |
| `--name` | Assigns a container name |
| `-p 5000:5000` | Publishes the container's port on the host |
| `-e APP_ENV=test` | Sets an application environment variable |

### Verify Application Health

```bash
curl -i http://localhost:5000/health
```

Expected HTTP status:

```text
HTTP/1.1 200 OK
```

### Test the Root Endpoint

```bash
curl http://localhost:5000/
```

Example response:

```json
{
  "environment": "test",
  "message": "Docker Day 7 Security Lab",
  "version": "v1"
}
```

### Run the Smoke Test

```bash
./scripts/smoke-test.sh
```

Successful output:

```text
Checking application health...
Smoke test passed.
```

### Useful Troubleshooting Commands

```bash
# Show running containers
docker ps

# Inspect container logs
docker logs winter-arc-test

# Inspect container health
docker inspect winter-arc-test \
  --format '{{.State.Health.Status}}'

# Inspect the runtime user
docker inspect winter-arc-test \
  --format '{{.Config.User}}'

# View image layers
docker history winter-arc-app:v1

# Remove the test container
docker rm -f winter-arc-test
```

## 🔐 Container Security Validation

The pipeline uses two complementary security tools.

**Hadolint** checks Dockerfile instructions against linting and best-practice rules.

**Trivy** scans the built container image for known vulnerabilities.

Example Trivy command:

```bash
trivy image \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  winter-arc-app:v1
```

During development, Trivy identified HIGH-severity vulnerabilities associated with `zlib1g`. The runtime Dockerfile was updated to install a patched package version.

A subsequent scan reported zero HIGH or CRITICAL findings within the configured scan scope.

**Note:** A clean scan is not proof that an image contains no vulnerabilities. Results depend on the vulnerability database, selected severities, scanner settings, and available fixes.

## ⚙️ GitHub Actions CI/CD Pipeline

The CI/CD pipeline is defined in:

`.github/workflows/docker-ci.yml`

GitHub Actions automatically validates the application, builds its Docker image, performs security checks, publishes the image to Docker Hub, and deploys it to an AWS EC2 test environment.

### Workflow Triggers

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

The workflow runs when:

- Code is pushed to the `main` branch.
- A pull request targets the `main` branch.

Pull requests run validation checks but do not publish images or trigger deployment.

### CI Pipeline Stages

#### 1. Source Code Checkout

```yaml
- name: Checkout repository
  uses: actions/checkout@v6
```

Downloads the repository contents into the GitHub-hosted runner so the subsequent steps can access the Dockerfile, application code, and test scripts.

#### 2. Dockerfile Linting

```yaml
- name: Lint Dockerfile
  uses: hadolint/hadolint-action@v3.1.0
```

Hadolint checks the Dockerfile for common mistakes and recommended practices.

During development, we addressed linting concerns related to package version pinning.

#### 3. Docker Image Build

```bash
docker build --pull -t winter-arc-app:ci .
```

Builds the application image inside the GitHub Actions runner.

The `:ci` tag is a temporary local image tag used during pipeline validation.

#### 4. Container Smoke Testing

The pipeline starts the newly built Docker image, waits for the application to respond, and executes:

```bash
./scripts/smoke-test.sh
```

The smoke test checks the `/health` endpoint.

If the application does not pass the test, the pipeline fails and image publishing does not proceed.

#### 5. Container Vulnerability Scanning

```yaml
- name: Scan Docker image
  uses: aquasecurity/trivy-action@v0.36.0
  with:
    image-ref: winter-arc-app:ci
    severity: HIGH,CRITICAL
    ignore-unfixed: true
    exit-code: '1'
```

Trivy scans the container image for known vulnerabilities.

The configuration instructs the pipeline to fail when qualifying HIGH or CRITICAL vulnerabilities are detected.

**Security issue encountered:**

Trivy initially identified vulnerabilities associated with the `zlib1g` package in the runtime image.

We updated the Dockerfile to use a patched package version, rebuilt the image, and verified that the configured scan no longer reported HIGH or CRITICAL findings.

#### 6. Docker Hub Authentication

After successful validation, the workflow authenticates to Docker Hub using repository secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

Credentials are stored in GitHub Actions secrets rather than being hardcoded in the repository.

Docker Hub authentication and image publishing occur only on pushes to `main`.

#### 7. Docker Image Tagging and Publishing

```bash
docker tag winter-arc-app:ci "$IMAGE:$SHA"
docker push "$IMAGE:$SHA"
```

Where:

- `IMAGE` is the Docker Hub repository.
- `SHA` is the full Git commit SHA.

Example published image:

```text
anujjain21/winter-arc-app:1e659fe0ed0dd8a1daca7f8fa1943ae29097e4d5
```

This tagging strategy makes it possible to identify and redeploy images associated with specific Git commits.

### GitHub Actions Job Dependencies

The workflow separates validation and publishing from deployment.

```yaml
jobs:
  lint:
    runs-on: ubuntu-24.04
    steps:
      # Build, test, scan and publish

  deploy-test:
    needs: lint
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-24.04
    steps:
      # SSH deployment to EC2
```

The `needs: lint` directive ensures that the deployment job runs only after the upstream CI job has completed successfully.

The `if` condition prevents the deployment job from executing during pull-request validation.

### GitHub Actions Concepts Practiced

| Concept | Purpose |
|---|---|
| `on` | Defines events that trigger the workflow |
| `jobs` | Groups related automation tasks |
| `runs-on` | Selects the runner environment |
| `steps` | Defines commands and actions executed within a job |
| `uses` | Invokes a reusable GitHub Action |
| `run` | Executes shell commands |
| `env` | Defines environment variables |
| `secrets` | Supplies sensitive configuration values |
| `github.sha` | Provides the triggering commit's SHA |
| `needs` | Defines job dependencies |
| `if` | Controls conditional execution |

### CI/CD Failure Handling

The pipeline is designed to stop or skip downstream work when required validation stages fail.

| Failure scenario | Outcome |
|---|---|
| Dockerfile lint error | CI fails |
| Docker image build failure | CI fails |
| Smoke test failure | CI fails |
| Trivy policy violation | CI fails |
| Docker Hub authentication failure | Publishing fails |
| Image push failure | Deployment job is skipped |
| EC2 SSH failure | Deployment job fails |
| EC2 health-check failure | Deployment job fails |

A deployment failure is reported by GitHub Actions, but the current implementation does not automatically restore the previous application image.

## ☁️ AWS EC2 Deployment

The application is deployed to an Ubuntu EC2 instance using GitHub Actions, SSH authentication, Docker Hub, and a dedicated Bash deployment script.

### EC2 Infrastructure

| Component | Configuration |
|---|---|
| Cloud provider | AWS |
| Compute | EC2 |
| Operating system | Ubuntu Linux |
| Container runtime | Docker Engine |
| SSH port | TCP 22 |
| Deployment account | `deploy` |
| Application container | `winter-arc-app` |
| Application port | 5000 |
| Host port binding | `127.0.0.1:5000:5000` |
| Container restart policy | `unless-stopped` |

The application is bound to the EC2 host's loopback interface rather than exposed directly through its public network interface.

**Security limitation:** For this learning environment, the EC2 security group currently permits inbound SSH connections from `0.0.0.0/0`. This should be restricted or replaced with a more controlled remote-access approach before production use.

### Dedicated Deployment User

A separate Linux user named `deploy` was created for automated deployment.

```bash
sudo useradd -m -s /bin/bash deploy
```

The deployment account uses SSH public-key authentication and is not granted unrestricted Docker or sudo access.

The account's SSH configuration uses:

```text
/home/deploy/.ssh/authorized_keys
```

Recommended permissions:

```bash
sudo chmod 700 /home/deploy/.ssh
sudo chmod 600 /home/deploy/.ssh/authorized_keys
sudo chown -R deploy:deploy /home/deploy/.ssh
```

### SSH Authentication

A dedicated Ed25519 SSH key pair was generated for the GitHub Actions deployment process.

```bash
ssh-keygen -t ed25519 -f ~/.ssh/github-actions-ec2-deploy
```

The public key was installed in the deployment user's `authorized_keys` file.

The private key was stored as a GitHub Actions repository secret.

**Security practice:** SSH private keys must never be committed to Git repositories, included in Docker images, or printed in CI/CD logs.

### GitHub Actions Deployment Secrets

The following repository secrets are configured:

| Secret | Purpose |
|---|---|
| `TEST_HOST` | EC2 public IP address or DNS hostname |
| `TEST_USER` | SSH deployment username |
| `TEST_SSH_KEY` | SSH private key used for authentication |
| `TEST_KNOWN_HOSTS` | Trusted EC2 SSH host-key entry |

The workflow uses strict SSH host-key verification to authenticate the remote server.

This prevents the deployment job from blindly trusting an unknown SSH server.

### Restricted Deployment Permissions

Instead of giving the deployment user unrestricted Docker access, a root-owned deployment script is made available at:

```text
/usr/local/bin/deploy-winter-arc
```

A sudoers configuration grants the `deploy` account permission to execute that script without an interactive password.

Example authorization:

```text
deploy ALL=(root) NOPASSWD: /usr/local/bin/deploy-winter-arc *
```

The deployment script validates the supplied Git SHA argument.

**Important:** This configuration is intended for the learning environment. Script ownership, argument validation, sudoers matching, and protection against unauthorized script modification remain critical security controls.

### Automated Deployment Process

After the CI job successfully publishes a Docker image, the `deploy-test` GitHub Actions job starts.

The job:

1. Retrieves deployment credentials from GitHub Actions secrets.
2. Creates temporary SSH configuration on the runner.
3. Configures the trusted EC2 host key.
4. Connects to EC2 as the `deploy` user.
5. Invokes the permitted deployment script using the triggering Git commit SHA.
6. Reports deployment success or failure based on the remote script's exit status.

Example remote deployment command:

```bash
sudo -n /usr/local/bin/deploy-winter-arc <full-git-sha>
```

The `-n` option prevents sudo from prompting interactively for a password.

### Deployment Script

The EC2 instance uses a root-owned Bash script to deploy the requested Docker image.

```bash
#!/usr/bin/env bash
set -euo pipefail

SHA="${1:-}"

if [[ ! "$SHA" =~ ^[a-f0-9]{40}$ ]]; then
    echo "ERROR: Expected a full 40-character Git SHA"
    exit 2
fi

IMAGE="anujjain21/winter-arc-app:${SHA}"
CONTAINER="winter-arc-app"

echo "Deploying image: $IMAGE"

docker pull "$IMAGE"

docker rm -f "$CONTAINER" 2>/dev/null || true

docker run -d \
    --name "$CONTAINER" \
    --restart unless-stopped \
    -p 127.0.0.1:5000:5000 \
    -e APP_ENV=test \
    "$IMAGE"

echo "Waiting for application health..."

for i in {1..15}; do
    if curl --fail --silent --show-error \
        http://127.0.0.1:5000/health >/dev/null 2>&1; then
        echo "Deployment successful: $SHA"
        exit 0
    fi
    sleep 2
done

echo "ERROR: Application health check failed"
docker logs --tail 50 "$CONTAINER" || true
exit 1
```

### Deployment Script Concepts

| Command | Purpose |
|---|---|
| `set -euo pipefail` | Enables stricter Bash error handling |
| `docker pull` | Retrieves the requested image |
| `docker rm -f` | Removes the previous application container |
| `docker run -d` | Starts a new container in detached mode |
| `--restart unless-stopped` | Configures Docker restart behavior |
| `-p 127.0.0.1:5000:5000` | Publishes the container port on localhost |
| `curl --fail` | Checks HTTP response success |
| `docker logs --tail 50` | Displays recent container logs when health verification fails |
| `exit 1` | Reports deployment failure to the calling process |

The script performs a replace-and-restart deployment. It does not support zero-downtime deployments or automatic rollback.

### Manual Deployment

A specific image can be deployed by passing its full Git SHA:

```bash
sudo /usr/local/bin/deploy-winter-arc \
  1e659fe0ed0dd8a1daca7f8fa1943ae29097e4d5
```

### Deployment Verification

Inspect the running container:

```bash
sudo docker ps --filter "name=^/winter-arc-app$"
```

Inspect its image, runtime status, and health:

```bash
sudo docker inspect winter-arc-app \
  --format 'Image={{.Config.Image}} | Status={{.State.Status}} | Health={{.State.Health.Status}}'
```

Test the application locally on EC2:

```bash
curl -i http://127.0.0.1:5000/
```

Expected successful response:

```json
{
  "environment": "test",
  "message": "Docker Day 7 Security Lab",
  "version": "v1"
}
```

## 🔄 Manual Rollback

The project demonstrates rollback by redeploying a previously published SHA-tagged Docker image.

### Example Deployment History

| Release | Git SHA |
|---|---|
| Earlier image | `de28d68f02f42ad1e586b56ffe2a5c76fd8768d4` |
| Newer image | `1e659fe0ed0dd8a1daca7f8fa1943ae29097e4d5` |

### Roll Back to the Earlier Image

```bash
sudo /usr/local/bin/deploy-winter-arc \
  de28d68f02f42ad1e586b56ffe2a5c76fd8768d4
```

The script pulls the earlier image, replaces the existing container, starts the application, and verifies the health endpoint.

### Verify Rollback

```bash
sudo docker inspect winter-arc-app \
  --format 'Image={{.Config.Image}} | Status={{.State.Status}} | Health={{.State.Health.Status}}'
```

The inspected image tag should match the earlier Git SHA.

### Restore the Newer Image

```bash
sudo /usr/local/bin/deploy-winter-arc \
  1e659fe0ed0dd8a1daca7f8fa1943ae29097e4d5
```

This restores the latest successfully published image from the exercise.

### Rollback Limitations

- Rollback is initiated manually.
- The running container is removed before its replacement becomes healthy.
- No automatic recovery occurs if a deployment fails.
- Database and persistent-volume state are not rolled back.
- Docker image tags are not guaranteed immutable unless registry policies enforce immutability.

For production deployments, additional reliability controls would be necessary.

## 🔍 Troubleshooting & Debugging

During this project, several issues were investigated and resolved across Docker, GitHub Actions, container security, and AWS EC2.

### 1. Trivy Detected HIGH-Severity Vulnerabilities

**Problem:** The CI pipeline failed because Trivy identified HIGH-severity vulnerabilities associated with the `zlib1g` package.

**Root cause:** The runtime image contained a vulnerable version of the package.

**Resolution:** Updated the Dockerfile to install an available patched package version and rebuilt the image.

**Verification:**

```bash
trivy image \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  winter-arc-app:ci
```

The updated image passed the configured security scan.

**Lesson:** A successful image build does not guarantee that the container meets security requirements.

### 2. Dockerfile Linting and Package Version Pinning

**Problem:** Hadolint flagged package installation practices that did not explicitly pin the installed package version.

**Resolution:** Used an explicit package version for the required runtime security update.

**Lesson:** Dockerfile linting helps identify potentially unreliable or non-reproducible build instructions before deployment.

### 3. GitHub Actions Deployment Authentication

**Challenge:** GitHub Actions needed secure, noninteractive access to the Ubuntu EC2 instance.

**Implementation:**

- Created a dedicated `deploy` Linux account.
- Configured Ed25519 public-key authentication.
- Stored the private key in GitHub Actions secrets.
- Configured trusted SSH host-key verification.
- Restricted sudo access to a root-owned deployment script.

**Useful verification commands:**

```bash
# Check SSH service status
sudo systemctl status ssh

# Inspect authorized SSH keys
sudo ls -l /home/deploy/.ssh/authorized_keys

# Validate sudoers configuration
sudo visudo -c

# Inspect SSH host-key fingerprint
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

**Lesson:** SSH network connectivity, client authentication, server identity verification, and sudo authorization are separate security controls.

### 4. Deployment Health Verification

**Challenge:** A successfully started container may still fail to serve HTTP requests.

**Implementation:** The deployment script checks `/health` repeatedly and fails if the application does not become responsive within the configured retry window.

**Useful commands:**

```bash
sudo docker ps -a

sudo docker logs --tail 50 winter-arc-app

sudo docker inspect winter-arc-app \
  --format '{{.State.Status}} | {{.State.Health.Status}}'

curl -i http://127.0.0.1:5000/health
```

**Lesson:** Container creation, container health, and application functionality should be verified independently.

### 5. Manual Rollback Verification

**Challenge:** Confirm that an earlier Docker image actually replaced the running version.

**Resolution:** Redeployed a previously published Git SHA-tagged image and inspected the new container's image reference.

**Verification:**

```bash
sudo docker inspect winter-arc-app \
  --format '{{.Config.Image}}'
```

**Lesson:** Application responses may remain identical between image versions. Inspecting the deployed image reference provides better release traceability.

## 🚧 Production-Readiness Improvements

This project is a working learning environment, not a production-ready application deployment platform.

| Area | Current implementation | Recommended improvement |
|---|---|---|
| Deployment availability | Remove and replace container | Blue-green or rolling deployment |
| Failure recovery | Manual rollback | Automatic rollback to last healthy release |
| SSH exposure | Port 22 publicly accessible | Restrict access or use AWS Systems Manager |
| Application server | Flask development server | Gunicorn or another production WSGI server |
| Traffic routing | Localhost port binding | Nginx reverse proxy or AWS Application Load Balancer |
| Secrets | GitHub Actions repository secrets | Environment-scoped secrets and least-privilege access |
| Image traceability | Git SHA tags | Immutable image references or digest-based deployment |
| Monitoring | Docker logs and health checks | Centralized logs, metrics, alerts, and dashboards |
| Deployment reliability | Basic `/health` polling | Readiness checks, release validation, and recovery controls |
| Pipeline security | CI linting and vulnerability scanning | Least-privilege workflow permissions and pinned third-party actions |

## 📚 Key Concepts Learned

### Docker

- Multi-stage Docker image builds
- Dockerfile instructions and build context
- Non-root container execution
- Container health checks
- Image tagging and publishing
- Image inspection and debugging

### GitHub Actions

- Workflow triggers
- Jobs and steps
- Hosted runners
- Job dependencies using `needs`
- Conditional execution using `if`
- GitHub Actions secrets
- Automated testing and image publishing

### Container Security

- Dockerfile linting using Hadolint
- Image vulnerability scanning with Trivy
- Patched dependency installation
- Restricted Linux user privileges
- SSH authentication and host-key verification

### AWS EC2 and Linux

- Docker Engine installation
- Linux users and file permissions
- SSH configuration
- Restricted sudo permissions
- Bash deployment scripts
- Container troubleshooting and health verification

### Deployment and Release Management

- Continuous integration
- Continuous deployment to a test environment
- SHA-tagged Docker image releases
- Automated remote deployment
- Manual rollback
- Deployment verification

## ✅ Project Outcome

Successfully built and tested an end-to-end CI/CD pipeline that:

1. Validates a Dockerized Flask application.
2. Builds and smoke-tests the container image.
3. Scans the image for HIGH and CRITICAL vulnerabilities.
4. Publishes Git SHA-tagged Docker images to Docker Hub.
5. Automatically deploys successful builds to an AWS EC2 test environment.
6. Verifies application health after deployment.
7. Supports manual rollback to previously published images.

The project demonstrates the integration of Docker, GitHub Actions, Docker Hub, Linux, SSH, security scanning, and AWS EC2 into a practical automated deployment workflow.

**GitHub Repository:** https://github.com/Anujjain2101/docker-cicd-capstone

**Docker Hub Repository:** https://hub.docker.com/r/anujjain21/winter-arc-app