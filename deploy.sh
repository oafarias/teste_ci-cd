#!/bin/bash

VAULT_NAME="kv-django-alef"

echo "🔐 Detectando ambiente..."
# Se o nome da máquina contiver "VM-" ou responder aos metadados do Azure, estamos na VM da Azure
if [[ $(hostname) == *"VM-"* ]] || curl -s -m 1 -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2021-02-01" > /dev/null 2>&1; then
    echo "☁️ Ambiente de Produção detectado (Azure VM)."
    az login --identity > /dev/null 2>&1
    DOMAIN=$(az keyvault secret show --name "DOMAIN" --vault-name "$VAULT_NAME" --query value -o tsv 2>/dev/null)
    IS_DEBUG="False"
else
    echo "💻 Ambiente Local detectado (Desenvolvimento)."
    if ! az account show > /dev/null 2>&1; then
        echo "❌ Faça 'az login' no terminal antes de rodar o script."
        exit 1
    fi
    DOMAIN="localhost"
    IS_DEBUG="True"
fi

# Fallbacks defensivos para garantir que nunca fiquem vazias
DOMAIN="${DOMAIN:-localhost}"
IS_DEBUG="${IS_DEBUG:-True}"

echo "🔑 Buscando segredos no cofre ($VAULT_NAME)..."
POSTGRES_DB=$(az keyvault secret show --name "POSTGRES-DB" --vault-name "$VAULT_NAME" --query value -o tsv)
POSTGRES_USER=$(az keyvault secret show --name "POSTGRES-USER" --vault-name "$VAULT_NAME" --query value -o tsv)
POSTGRES_PASSWORD=$(az keyvault secret show --name "POSTGRES-PASSWORD" --vault-name "$VAULT_NAME" --query value -o tsv)
SECRET_KEY=$(az keyvault secret show --name "SECRET-KEY" --vault-name "$VAULT_NAME" --query value -o tsv 2>/dev/null)
SECRET_KEY="${SECRET_KEY:-django-insecure-chave-temporaria-local}"

echo "⚙️ Gerando .env para o Docker..."
cat <<EOF > .env
DOMAIN=$DOMAIN
DEBUG=$IS_DEBUG
SECRET_KEY=$SECRET_KEY
POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
DATABASE_URL=postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@db:5432/$POSTGRES_DB
EOF

echo "🚀 Reconstruindo e subindo a infraestrutura..."
docker compose down
docker compose up -d --build

echo "🔒 Protegendo arquivo .env..."
chmod 600 .env

echo "✅ Concluído com sucesso!"
