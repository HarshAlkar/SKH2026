#!/bin/sh
set -e
python manage.py migrate --noinput
python manage.py collectstatic --noinput
# Seed staff admin + demo inventory when empty (safe to re-run)
python manage.py ensure_admin || true
python manage.py seed_demo_users || true
python manage.py seed_inventory || true
exec gunicorn config.wsgi:application \
  --bind "0.0.0.0:${PORT:-8000}" \
  --timeout 120 \
  --workers 2
