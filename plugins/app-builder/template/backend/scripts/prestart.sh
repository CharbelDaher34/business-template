#! /usr/bin/env bash
# Runs once every time the app starts, before the backend:
# 1. bring the database structure up to date, 2. insert any missing seed data.

set -e

echo "Updating the database structure (alembic upgrade head)..."
alembic upgrade head

echo "Adding missing seed data (app/seed.py)..."
python -m app.seed
