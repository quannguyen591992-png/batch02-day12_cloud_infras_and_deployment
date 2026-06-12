# Day 12 Lab Report — Cloud Infrastructure and Deployment

**Student project repo:** https://github.com/quannguyen591992-png/batch02-day12_cloud_infras_and_deployment  
**Railway public URL for Part 3:** https://batch02-day12cloudinfrasanddeployment-production-7970.up.railway.app

---

## 1. Overview

This report summarizes the work completed for Day 12: deploying an AI Agent to production/cloud.

The lab was completed sequentially from Part 1 to Part 5:

1. Localhost vs Production
2. Docker Containerization
3. Cloud Deployment
4. API Security
5. Scaling and Reliability

For the final project direction, the original sample project `06-lab-complete/` is treated only as instructor reference. The personal project intended for final deployment is:

```text
07-lab-ca-nhan-day-8/
```

This project is a Streamlit-based Vietnamese legal/news RAG application.

---

## 2. Repository Changes

The repository was pushed to the student's GitHub account:

```text
https://github.com/quannguyen591992-png/batch02-day12_cloud_infras_and_deployment
```

Important commits made during the lab:

```text
79b7c83 add personal day 8 lab project
0915b8c configure railway nixpacks deploy
717f865 add root Dockerfile for railway deploy
0cd8320 add railway start scripts
021e458 fix part 4 security headers middleware
5aced95 fix part 5 scaling and reliability stack
```

Notable fixes added during the lab:

- Added Railway deployment support files.
- Added a root Dockerfile for Railway deployment.
- Added `start.sh` scripts for Railway/Railpack compatibility.
- Fixed Part 4 security headers middleware bug.
- Fixed Part 5 Docker Compose production stack.
- Added missing Dockerfile and requirements for Part 5 production.
- Fixed Windows UTF-8 output issue in Part 5 stateless test.

---

## 3. Part 1 — Localhost vs Production

### Goal

Understand why an app that works on localhost is not necessarily production-ready.

### Files reviewed

```text
01-localhost-vs-production/develop/app.py
01-localhost-vs-production/production/app.py
01-localhost-vs-production/production/config.py
```

### Anti-patterns found in the basic app

The basic app contains several production anti-patterns:

1. Hardcoded API key.
2. Hardcoded database URL and password.
3. Configuration values defined directly in code.
4. Uses `print()` instead of structured logging.
5. Logs secrets to the console.
6. No `/health` endpoint.
7. No `/ready` endpoint.
8. Host is hardcoded as `localhost`.
9. Port is hardcoded as `8000`.
10. Debug reload is enabled for runtime.

Example:

```python
OPENAI_API_KEY = "sk-hardcoded-fake-key-never-do-this"
DATABASE_URL = "postgresql://admin:password123@localhost:5432/mydb"
```

### Test result

The production version was tested successfully:

```text
GET  /health  -> 200 OK
GET  /ready   -> 200 OK
POST /ask     -> 200 OK
```

The basic version exposed a Windows encoding issue when printing Vietnamese text, which further demonstrated why simple local/debug logging is not reliable for production.

### Key lesson

Production applications should use environment variables, structured logging, health/readiness checks, graceful shutdown, and `0.0.0.0` binding with dynamic cloud ports.

---

## 4. Part 2 — Docker Containerization

### Goal

Understand Dockerfile basics, Docker image build/run workflow, multi-stage builds, and Docker Compose.

### Files reviewed

```text
02-docker/develop/Dockerfile
02-docker/develop/app.py
02-docker/production/Dockerfile
02-docker/production/docker-compose.yml
02-docker/production/nginx/nginx.conf
```

### Basic Dockerfile concepts

The basic Dockerfile uses:

```dockerfile
FROM python:3.11
WORKDIR /app
COPY 02-docker/develop/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY 02-docker/develop/app.py .
CMD ["python", "app.py"]
```

Important observations:

- `python:3.11` is easy to use but large.
- `WORKDIR /app` sets the working directory inside the container.
- Copying `requirements.txt` before source code allows Docker layer caching.
- `CMD` defines the default command for the container.

### Test result

The basic Docker image was built and tested successfully.

```text
Image: agent-develop
Size: 1.66GB
GET  /health -> 200 OK
POST /ask    -> 200 OK
```

Example `/health` response:

```json
{
  "status": "ok",
  "container": true
}
```

Example `/ask` response:

```json
{
  "answer": "Container là cách đóng gói app để chạy ở mọi nơi. Build once, run anywhere!"
}
```

### Multi-stage build

The production Dockerfile demonstrates a builder stage and runtime stage:

```dockerfile
FROM python:3.11-slim AS builder
FROM python:3.11-slim AS runtime
```

The purpose is to keep build tools out of the final runtime image.

### Issue found

The original production Docker build failed because `02-docker/production/requirements.txt` was missing. This was documented as an important lesson about Docker build context and dependency files.

### Key lesson

Docker improves deployment consistency. Multi-stage builds reduce image size and improve production security.

---

## 5. Part 3 — Cloud Deployment

### Goal

Deploy the AI Agent to a public cloud platform and verify the public URL.

### Files reviewed

```text
03-cloud-deployment/railway/app.py
03-cloud-deployment/railway/railway.toml
03-cloud-deployment/render/render.yaml
03-cloud-deployment/production-cloud-run/cloudbuild.yaml
03-cloud-deployment/production-cloud-run/service.yaml
```

### Deployment platform used

Railway was used for deployment.

Railway CLI could not be installed because of a local SSL/certificate issue, so deployment was done through Railway Dashboard connected to GitHub.

### Additional deployment support files added

```text
nixpacks.toml
Dockerfile
start.sh
03-cloud-deployment/railway/start.sh
```

These files were added to make Railway/Railpack build and start the application correctly from the repository.

### Public URL

```text
https://batch02-day12cloudinfrasanddeployment-production-7970.up.railway.app
```

### Public endpoint test results

#### Health check

```text
GET /health -> 200 OK
```

Response:

```json
{
  "status": "ok",
  "platform": "Railway"
}
```

#### Agent endpoint

```text
POST /ask -> 200 OK
```

Response:

```json
{
  "question": "hello cloud",
  "answer": "Đây là câu trả lời từ AI agent (mock). Trong production, đây sẽ là response từ OpenAI/Anthropic.",
  "platform": "Railway"
}
```

### Railway vs Render

| Item | Railway | Render |
|---|---|---|
| Config file | `railway.toml` | `render.yaml` |
| Deployment style | Dashboard/CLI | Dashboard Blueprint |
| Start command | `uvicorn app:app --host 0.0.0.0 --port $PORT` | same |
| Health check | `/health` | `/health` |
| Best for | fast demo/MVP | clearer Infrastructure-as-Code |

### Key lesson

Cloud platforms inject runtime configuration such as `PORT`; production apps must read these values from environment variables.

---

## 6. Part 4 — API Security

### Goal

Protect the public AI Agent API with authentication, rate limiting, and cost guard.

### Files reviewed

```text
04-api-gateway/develop/app.py
04-api-gateway/production/app.py
04-api-gateway/production/auth.py
04-api-gateway/production/rate_limiter.py
04-api-gateway/production/cost_guard.py
```

### API key authentication

The basic version protects `/ask` using the `X-API-Key` header.

Test results:

| Test | Status |
|---|---:|
| Missing API key | 401 |
| Wrong API key | 403 |
| Correct API key | 200 |

### JWT authentication

The production version uses JWT authentication.

Demo users:

```text
student / demo123  -> role=user
teacher / teach456 -> role=admin
```

Flow:

```text
POST /auth/token -> returns access_token
POST /ask with Authorization: Bearer <token>
```

### Rate limiting

Rate limiting algorithm:

```text
Sliding Window Counter
```

Limits:

| Role | Limit |
|---|---:|
| user | 10 requests/minute |
| admin | 100 requests/minute |

The test successfully returned:

```text
429 Too Many Requests
```

when the user exceeded the request limit.

### Cost guard

The production version tracks:

- input tokens,
- output tokens,
- request count,
- user daily budget,
- global daily budget.

Usage endpoint was tested successfully:

```text
GET /me/usage -> 200 OK
```

Example response:

```json
{
  "user_id": "student",
  "requests": 10,
  "cost_usd": 0.000184,
  "budget_usd": 1.0,
  "budget_remaining_usd": 0.999816
}
```

### Bug fixed

The production middleware originally used:

```python
response.headers.pop("server", None)
```

This caused a runtime error because Starlette `MutableHeaders` does not support `.pop()`.

Fixed with:

```python
if "server" in response.headers:
    del response.headers["server"]
```

Commit:

```text
021e458 fix part 4 security headers middleware
```

### Key lesson

Public AI endpoints must be protected because unrestricted access can lead to abuse and unexpected LLM costs.

---

## 7. Part 5 — Scaling and Reliability

### Goal

Implement and test health checks, readiness checks, graceful shutdown, stateless design, Redis-backed session storage, and load balancing.

### Files reviewed

```text
05-scaling-reliability/develop/app.py
05-scaling-reliability/production/app.py
05-scaling-reliability/production/docker-compose.yml
05-scaling-reliability/production/nginx.conf
05-scaling-reliability/production/test_stateless.py
```

### Develop version tests

The develop version was tested successfully:

```text
GET  /health -> 200 OK
GET  /ready  -> 200 OK
POST /ask    -> 200 OK
```

Example `/health` response:

```json
{
  "status": "ok",
  "version": "1.0.0",
  "checks": {
    "memory": {
      "status": "ok"
    }
  }
}
```

### Graceful shutdown

The develop version uses:

```python
timeout_graceful_shutdown=30
```

and tracks in-flight requests before shutdown.

### Production fixes added

The production stack initially lacked some files/configuration. These were added/fixed:

```text
05-scaling-reliability/production/Dockerfile
05-scaling-reliability/production/requirements.txt
05-scaling-reliability/production/docker-compose.yml
05-scaling-reliability/production/app.py
05-scaling-reliability/production/test_stateless.py
```

Commit:

```text
5aced95 fix part 5 scaling and reliability stack
```

### Production Docker Compose stack

The stack was run with:

```bash
docker compose up --build --scale agent=3 -d
```

Running services:

```text
production-nginx-1
production-agent-1
production-agent-2
production-agent-3
production-redis-1
```

### Architecture

```text
Client
  |
  v
Nginx :8080
  |
  +--> Agent 1 :8000
  +--> Agent 2 :8000
  +--> Agent 3 :8000
        |
        v
      Redis
```

### Load balancing test

Requests to `/health` and `/ready` were routed to different agent instances through Nginx.

Example:

```text
x-served-by: 172.18.0.3:8000
x-served-by: 172.18.0.5:8000
```

### Stateless test

`test_stateless.py` was fixed to support UTF-8 output on Windows and then tested successfully.

Result:

```text
Instances used: {'instance-93e3c0', 'instance-28c76e', 'instance-aa9742'}
All requests served despite different instances.
Session history preserved across all instances via Redis.
```

Conversation history contained 10 messages after 5 turns, proving Redis-backed state was shared across all instances.

### Key lesson

State should not be kept in local process memory when scaling horizontally. Redis allows multiple app instances to share conversation history safely.

---

## 8. Part 6 — Personal Final Project Deployment

The final personal project uses:

```text
07-lab-ca-nhan-day-8/
```

This is a personal Vietnamese legal/news RAG project with:

- Streamlit UI,
- hybrid retrieval,
- citation display,
- security guardrails,
- evaluation scripts,
- frontend assets,
- RAG pipeline source modules.

The project was added to this repository as a normal folder, not as a nested Git repository.

Files included:

```text
07-lab-ca-nhan-day-8/app.py
07-lab-ca-nhan-day-8/src/
07-lab-ca-nhan-day-8/tests/
07-lab-ca-nhan-day-8/frontend/
07-lab-ca-nhan-day-8/group_project/
07-lab-ca-nhan-day-8/requirements.txt
07-lab-ca-nhan-day-8/.env.example
```

Files intentionally not committed:

```text
.env
.git/
__pycache__/
.pytest_cache/
.ocr_tmp/
logs
large local data ignored by gitignore
```

The deployment approach was Option A:

```text
Deploy the Streamlit app first for a fast working public demo.
```

Deployment files and runtime data were added:

```text
07-lab-ca-nhan-day-8/Dockerfile
07-lab-ca-nhan-day-8/railway.toml
07-lab-ca-nhan-day-8/.streamlit/config.toml
07-lab-ca-nhan-day-8/requirements.deploy.txt
07-lab-ca-nhan-day-8/data/index/
07-lab-ca-nhan-day-8/data/standardized/
```

Personal project Railway URL:

```text
https://batch02-day12cloudinfrasanddeployment-production-2365.up.railway.app
```

Validation results:

```text
GET /_stcore/health -> 200 ok
GET /                -> 200 Streamlit UI loaded
```

This confirms the personal Streamlit RAG app was deployed successfully and is reachable through a public Railway domain.

---

## 9. Final Status

| Part | Topic | Status |
|---|---|---|
| Part 1 | Localhost vs Production | Completed |
| Part 2 | Docker Containerization | Completed |
| Part 3 | Railway Cloud Deployment | Completed |
| Part 4 | API Security | Completed |
| Part 5 | Scaling & Reliability | Completed |
| Part 6 | Personal project deployment | Completed |
| Final report | DAY12_LAB_REPORT.md | Updated with both public URLs |

**Overall status:** All Day 12 requirements are completed and deployed.

- Part 3 demo URL: `https://batch02-day12cloudinfrasanddeployment-production-7970.up.railway.app`
- Personal project 07 URL: `https://batch02-day12cloudinfrasanddeployment-production-2365.up.railway.app`

---

## 10. Summary

The lab successfully demonstrated the full path from a local-only AI Agent to a production-aware cloud deployment:

- identified localhost anti-patterns,
- containerized an app with Docker,
- deployed a FastAPI agent to Railway,
- added API security patterns,
- implemented rate limiting and cost tracking,
- tested scaling with Nginx, Redis, and multiple agent instances,
- prepared a personal RAG project for final deployment.

The most important production lessons were:

1. Never hardcode secrets.
2. Read runtime configuration from environment variables.
3. Always expose health/readiness endpoints.
4. Use Docker for reproducible deployments.
5. Protect public APIs with auth, rate limits, and cost guards.
6. Store shared state outside the app process when scaling horizontally.
7. Validate deployment with real public URLs, not only local tests.
