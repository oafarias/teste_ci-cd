#!/bin/bash
VAULT_NAME="kv-django-alef"

echo "🔐 Buscando chaves no Azure Key Vault..."
# Faz login automático usando a Identidade da VM
az login --identity > /dev/null

# Puxa os segredos do cofre
DOMAIN=$(az keyvault secret show --name "DOMAIN" --vault-name $VAULT_NAME --query value -o tsv)
POSTGRES_DB=$(az keyvault secret show --name "POSTGRES-DB" --vault-name $VAULT_NAME --query value -o tsv)
POSTGRES_USER=$(az keyvault secret show --name "POSTGRES-USER" --vault-name $VAULT_NAME --query value -o tsv)
POSTGRES_PASSWORD=$(az keyvault secret show --name "POSTGRES-PASSWORD" --vault-name $VAULT_NAME --query value -o tsv)

echo "⚙️ Gerando .env temporário para o Docker..."
cat <<EOF > .env
DOMAIN=$DOMAIN
POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
KEY_VAULT_URL=https://$VAULT_NAME.vault.azure.net/
EOF

echo "🚀 Reconstruindo e subindo a infraestrutura..."
docker compose down
docker compose up -d --build

echo "🧹 Apagando rastros (Segurança 100%)..."
rm .env

echo "✅ Deploy blindado concluído!"