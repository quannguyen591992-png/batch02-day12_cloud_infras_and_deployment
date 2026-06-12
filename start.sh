#!/usr/bin/env sh
set -e

cd 03-cloud-deployment/railway
exec uvicorn app:app --host 0.0.0.0 --port "${PORT:-8000}"
