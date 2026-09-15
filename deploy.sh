#!/bin/bash

VAULT_NAME="kv-django-alef"

echo "🔐 Detectando ambiente..."
# Se o nome da máquina contiver "VM-", sabemos que é a produção no Azure
if [[ $(hostname) == *"VM-"* ]]; then
    echo "☁️ Ambiente de Produção detectado (VM)."
    az login --identity > /dev/null 2>&1
    DOMAIN=$(az keyvault secret show --name "DOMAIN" --vault-name $VAULT_NAME --query value -o tsv)
    IS_DEBUG="False"
else
    echo "💻 Ambiente Local detectado (Notebook)."
    # Opcional: Garante que o az local já tem login
    if ! az account show > /dev/null 2>&1; then
        echo "❌ Faça 'az login' no terminal antes de rodar o script."
        exit 1
    fi
    DOMAIN="localhost"
    IS_DEBUG="True"
fi

echo "Buscando segredos do banco de dados..."
POSTGRES_DB=$(az keyvault secret show --name "POSTGRES-DB" --vault-name $VAULT_NAME --query value -o tsv)
POSTGRES_USER=$(az keyvault secret show --name "POSTGRES-USER" --vault-name $VAULT_NAME --query value -o tsv)
POSTGRES_PASSWORD=$(az keyvault secret show --name "POSTGRES-PASSWORD" --vault-name $VAULT_NAME --query value -o tsv)

echo "⚙️ Gerando .env para o Docker..."
cat <<EOF > .env
DOMAIN=$DOMAIN
DEBUG=$IS_DEBUG
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

echo "✅ Deploy concluído com sucesso!"