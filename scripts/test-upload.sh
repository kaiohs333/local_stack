#!/bin/bash

# Script para testar o upload de fotos para S3 via LocalStack
# Execute: chmod +x scripts/test-upload.sh && ./scripts/test-upload.sh

echo "🧪 Testando upload de foto para S3 via LocalStack..."
echo ""

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configurações
LOCALSTACK_URL="http://localhost:4566"
BUCKET_NAME="shopping-images"

# 1. Verificar se LocalStack está rodando
echo "1️⃣  Verificando LocalStack..."
HEALTH=$(curl -s ${LOCALSTACK_URL}/_localstack/health)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ LocalStack está rodando${NC}"
    echo "   Health: $HEALTH"
else
    echo -e "${RED}❌ LocalStack não está acessível em ${LOCALSTACK_URL}${NC}"
    echo "   Execute: docker-compose up -d"
    exit 1
fi
echo ""

# 2. Verificar se o bucket existe
echo "2️⃣  Verificando bucket S3..."
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

BUCKETS=$(aws s3 ls --endpoint-url ${LOCALSTACK_URL} 2>/dev/null)
if echo "$BUCKETS" | grep -q "$BUCKET_NAME"; then
    echo -e "${GREEN}✅ Bucket '${BUCKET_NAME}' existe${NC}"
else
    echo -e "${YELLOW}⚠️  Bucket '${BUCKET_NAME}' não encontrado. Criando...${NC}"
    aws s3 mb s3://${BUCKET_NAME} --endpoint-url ${LOCALSTACK_URL}
fi
echo ""

# 3. Criar uma imagem de teste (1x1 pixel PNG em base64)
echo "3️⃣  Preparando imagem de teste..."
# PNG 1x1 pixel vermelho em base64
TEST_IMAGE_BASE64="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="
TEST_FILENAME="test-image-$(date +%s).png"
echo -e "${GREEN}✅ Imagem de teste preparada: ${TEST_FILENAME}${NC}"
echo ""

# 4. Fazer upload direto para S3 (sem passar pela Lambda)
echo "4️⃣  Fazendo upload direto para S3..."
echo "$TEST_IMAGE_BASE64" | base64 -d > /tmp/${TEST_FILENAME}
aws s3 cp /tmp/${TEST_FILENAME} s3://${BUCKET_NAME}/photos/${TEST_FILENAME} \
    --endpoint-url ${LOCALSTACK_URL} \
    --content-type "image/png"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Upload direto bem-sucedido!${NC}"
else
    echo -e "${RED}❌ Falha no upload direto${NC}"
fi
rm /tmp/${TEST_FILENAME}
echo ""

# 5. Listar objetos no bucket
echo "5️⃣  Listando objetos no bucket..."
OBJECTS=$(aws s3 ls s3://${BUCKET_NAME} --recursive --endpoint-url ${LOCALSTACK_URL})
if [ -n "$OBJECTS" ]; then
    echo -e "${GREEN}📂 Objetos no bucket:${NC}"
    echo "$OBJECTS"
else
    echo -e "${YELLOW}⚠️  Bucket está vazio${NC}"
fi
echo ""

# 6. Testar endpoint da Lambda (se disponível)
echo "6️⃣  Testando endpoint da Lambda..."
API_URL="${LOCALSTACK_URL}/restapis/local/local/_user_request_/photos/upload"

RESPONSE=$(curl -s -X POST ${API_URL} \
    -H "Content-Type: application/json" \
    -d "{
        \"base64Data\": \"${TEST_IMAGE_BASE64}\",
        \"fileName\": \"curl-test-$(date +%s).png\",
        \"contentType\": \"image/png\"
    }" 2>/dev/null)

if echo "$RESPONSE" | grep -q "success"; then
    echo -e "${GREEN}✅ Endpoint da Lambda funcionando!${NC}"
    echo "   Response: $RESPONSE"
else
    echo -e "${YELLOW}⚠️  Endpoint da Lambda pode não estar configurado${NC}"
    echo "   URL: ${API_URL}"
    echo "   Response: $RESPONSE"
    echo ""
    echo "   Para configurar, execute:"
    echo "   npm install && serverless deploy --stage local"
fi
echo ""

# 7. Resumo final
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RESUMO DO TESTE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "LocalStack URL:  ${LOCALSTACK_URL}"
echo "Bucket:          ${BUCKET_NAME}"
echo ""
echo "Para listar fotos manualmente:"
echo "  aws s3 ls s3://${BUCKET_NAME} --recursive --endpoint-url ${LOCALSTACK_URL}"
echo ""
echo "Para acessar uma foto via URL:"
echo "  ${LOCALSTACK_URL}/${BUCKET_NAME}/photos/<nome-do-arquivo>"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
