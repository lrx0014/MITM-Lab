FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY victim_site/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY victim_site/ /app/

EXPOSE 8000

CMD ["python", "app.py"]
