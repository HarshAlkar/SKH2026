FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app:/app/django_api

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY backend/django_api/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY backend/django_api /app/django_api
COPY ai_engine /app/ai_engine

WORKDIR /app/django_api
RUN chmod +x start.sh

EXPOSE 8000
CMD ["./start.sh"]
