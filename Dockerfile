# Railway deployment Dockerfile for Day 12 Part 3.
# Builds the FastAPI app located in 03-cloud-deployment/railway.

FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY 03-cloud-deployment/railway/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY 03-cloud-deployment/railway/ ./

EXPOSE 8000

CMD sh -c "uvicorn app:app --host 0.0.0.0 --port ${PORT:-8000}"
