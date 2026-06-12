FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

WORKDIR /app

COPY 05-scaling-reliability/production/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY 05-scaling-reliability/production/app.py ./app.py
RUN mkdir -p utils
COPY utils/mock_llm.py ./utils/mock_llm.py

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
