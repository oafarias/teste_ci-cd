# 1. Configuração de uma base comum
FROM python:3.12.10-slim as base
WORKDIR /app

# 2. Instalação de bibliotecas do Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3. Imagem de produçao
FROM base as prod
COPY . .
CMD ["sh", "-c", "python manage.py collectstatic --noinput && python manage.py migrate && gunicorn setup.wsgi:application --bind 0.0.0.0:8000 --workers 3"]

# 4. Imagem dde desenvolvimento
from base as dev
RUN apt-get update && apt-get install -y git
CMD ["sh", "-c", "python manage.py migrate && gunicorn setup.wsgi:application --bind 0.0.0.0:8000 --workers 3 --reload"]