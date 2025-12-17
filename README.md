# 📸 AWS LocalStack S3 Upload

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)

**Aplicação mobile Flutter integrada com AWS S3 via LocalStack para armazenamento de fotos na nuvem local**

[Sobre](#-sobre) •
[Arquitetura](#-arquitetura) •
[Instalação](#-instalação) •
[Execução](#-execução) •
[Evidências](#-evidências) •
[API](#-api)

</div>

---

## 📋 Sobre

Este projeto demonstra a integração de um aplicativo móvel Flutter com serviços AWS simulados localmente através do **LocalStack**. O objetivo principal é substituir o armazenamento local de fotos por um armazenamento em nuvem (S3), permitindo que as imagens capturadas no dispositivo móvel sejam persistidas em um bucket S3.

### 🎯 Objetivos do Projeto

- ✅ Configurar LocalStack para simular AWS S3 localmente
- ✅ Criar bucket S3 `shopping-images` automaticamente
- ✅ Implementar endpoint de upload no backend (Serverless)
- ✅ Integrar app Flutter com captura de fotos e upload para S3
- ✅ Validar funcionamento através de logs e evidências

### 📚 Contexto Acadêmico

| Instituição | PUC Minas |
|-------------|-----------|
| Curso | Engenharia de Software |
| Disciplina | Cloud AWS |
| Data | Dezembro 2025 |

---

## 🏗️ Arquitetura

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│   App Flutter   │────▶│  API Gateway    │────▶│   AWS Lambda    │
│   (Mobile)      │     │  (LocalStack)   │     │  uploadPhoto    │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                         │
                                                         ▼
                                                ┌─────────────────┐
                                                │                 │
                                                │   S3 Bucket     │
                                                │ shopping-images │
                                                │                 │
                                                └─────────────────┘
```

### Fluxo de Upload

1. **Usuário** tira foto no app Flutter
2. **App** converte imagem para Base64
3. **App** envia POST para endpoint `/photos/upload`
4. **Lambda** recebe e decodifica a imagem
5. **Lambda** salva no bucket S3 `shopping-images`
6. **Lambda** retorna URL da imagem salva

---

## 📁 Estrutura do Projeto

```
local_stack_aws/
│
├── 📱 lib/                          # App Flutter
│   ├── main.dart                    # Tela principal com câmera
│   ├── config/
│   │   └── app_config.dart          # Configurações centralizadas
│   └── services/
│       └── upload_service.dart      # Serviço de upload S3
│
├── ⚡ functions/                     # Funções Lambda (Node.js)
│   ├── uploadPhoto.js               # Upload de fotos para S3
│   ├── createItem.js                # CRUD - Criar item
│   ├── getItem.js                   # CRUD - Buscar item
│   ├── listItems.js                 # CRUD - Listar items
│   ├── updateItem.js                # CRUD - Atualizar item
│   ├── deleteItem.js                # CRUD - Deletar item
│   └── snsSubscriber.js             # Processar notificações SNS
│
├── 🐳 docker-compose.yml            # LocalStack + DynamoDB Admin
├── ⚙️ serverless.yml                # Configuração Serverless Framework
│
├── 📜 localstack/
│   └── init-scripts/
│       └── 10-create-bucket.sh      # Script de criação do bucket
│
├── 🧪 scripts/
│   └── test-upload.sh               # Script de teste de upload
│
├── 📊 evidencias/
│   └── logs-evidencia.txt           # Logs de validação
│
├── 📦 package.json                  # Dependências Node.js
├── 📦 pubspec.yaml                  # Dependências Flutter
└── 📖 README.md                     # Este arquivo
```

---

## 🔧 Pré-requisitos

### Ferramentas Necessárias

| Ferramenta | Versão Mínima | Instalação |
|------------|---------------|------------|
| Docker | 20.x | [Download](https://www.docker.com/products/docker-desktop) |
| Docker Compose | 2.x | Incluído no Docker Desktop |
| Node.js | 18.x | `brew install node` |
| Flutter | 3.x | [Guia](https://flutter.dev/docs/get-started/install) |
| AWS CLI | 2.x | `brew install awscli` |
| Serverless | 3.x | `npm install -g serverless` |

### Instalação Rápida (macOS)

```bash
# Instalar Homebrew (se necessário)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar dependências
brew install node awscli
npm install -g serverless

# Flutter - siga o guia oficial
# https://flutter.dev/docs/get-started/install/macos
```

---

## 🚀 Execução

### Passo 1: Clonar e Preparar

```bash
# Clonar repositório
git clone https://github.com/kaiohs333/crud_serveless.git
cd local_stack_aws

# Instalar dependências Node.js
npm install

# Instalar dependências Flutter
flutter pub get
```

### Passo 2: Iniciar Infraestrutura

```bash
# Subir LocalStack e DynamoDB Admin
docker-compose up -d

# Verificar se os containers estão rodando
docker-compose ps
```

**Saída esperada:**
```
NAME              STATUS          PORTS
localstack-main   Up (healthy)    127.0.0.1:4566->4566/tcp
dynamodb-admin    Up              127.0.0.1:8001->8001/tcp
```

### Passo 3: Verificar Bucket S3

```bash
# Configurar credenciais AWS (LocalStack)
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

# Listar buckets
aws s3 ls --endpoint-url http://localhost:4566
```

**Saída esperada:**
```
2025-12-17 18:40:43 shopping-images
```

> **Nota:** Se o bucket não existir, crie manualmente:
> ```bash
> aws s3 mb s3://shopping-images --endpoint-url http://localhost:4566
> ```

### Passo 4: Deploy das Funções Lambda

```bash
# Deploy para LocalStack
npm run deploy:local
# ou
serverless deploy --stage local
```

### Passo 5: Executar App Flutter

```bash
# Listar dispositivos disponíveis
flutter devices

# Executar no dispositivo/emulador
flutter run

# Ou especificar um dispositivo
flutter run -d <device-id>
```

---

## 🧪 Testando o Upload

### Via Terminal (curl)

```bash
# Criar imagem de teste
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==" | base64 -d > /tmp/test.png

# Upload para S3
aws s3 cp /tmp/test.png s3://shopping-images/photos/test-$(date +%s).png \
    --endpoint-url http://localhost:4566

# Verificar upload
aws s3 ls s3://shopping-images --recursive --endpoint-url http://localhost:4566
```

### Via Script de Teste

```bash
chmod +x scripts/test-upload.sh
./scripts/test-upload.sh
```

### Via App Flutter

1. Abra o app no emulador/dispositivo
2. Toque no botão da **câmera** (ou galeria)
3. Tire/selecione uma foto
4. Aguarde o upload (indicador de status)
5. Verifique no terminal:
   ```bash
   aws s3 ls s3://shopping-images --recursive --endpoint-url http://localhost:4566
   ```

---

## 📊 Evidências

Os logs completos de validação estão disponíveis em [`evidencias/logs-evidencia.txt`](evidencias/logs-evidencia.txt).

### Resumo das Evidências

| Validação | Status | Comando |
|-----------|--------|---------|
| Containers Docker | ✅ OK | `docker-compose ps` |
| LocalStack Health | ✅ OK | `curl http://localhost:4566/_localstack/health` |
| Bucket S3 Criado | ✅ OK | `aws s3 ls --endpoint-url http://localhost:4566` |
| Upload Funcionando | ✅ OK | `aws s3 ls s3://shopping-images --recursive` |
| Logs de Operações | ✅ OK | `docker logs localstack-main` |

### Logs do LocalStack (Operações S3)

```
2025-12-17T21:40:43.274  INFO --- AWS s3.CreateBucket => 200
2025-12-17T21:41:22.583  INFO --- AWS s3.PutObject => 200
2025-12-17T21:44:53.820  INFO --- AWS s3.PutObject => 200
2025-12-17T21:45:40.548  INFO --- AWS s3.PutObject => 200
2025-12-17T21:45:50.795  INFO --- AWS s3.ListObjectsV2 => 200
```

### Objetos no Bucket

```
2025-12-17 18:41:22    70 photos/test-1766007681.png
2025-12-17 18:44:53    70 photos/evidence-upload.png
2025-12-17 18:45:40    70 photos/mobile-upload-evidence.png
```

---

## 🔌 API

### Endpoints Disponíveis

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| `POST` | `/photos/upload` | Upload de foto para S3 |
| `POST` | `/items` | Criar novo item |
| `GET` | `/items` | Listar todos os items |
| `GET` | `/items/{id}` | Buscar item por ID |
| `PUT` | `/items/{id}` | Atualizar item |
| `DELETE` | `/items/{id}` | Deletar item |

### Upload de Foto

**Request:**
```bash
POST /photos/upload
Content-Type: application/json

{
  "base64Data": "<imagem-em-base64>",
  "fileName": "product-photo.jpg",
  "contentType": "image/jpeg"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Foto enviada com sucesso!",
  "url": "http://localhost:4566/shopping-images/photos/1702760400000-product-photo.jpg",
  "key": "photos/1702760400000-product-photo.jpg",
  "bucket": "shopping-images"
}
```

---

## 🛠️ Troubleshooting

### LocalStack não inicia

```bash
# Verificar logs
docker logs localstack-main

# Reiniciar
docker-compose down -v
docker-compose up -d
```

### Bucket não foi criado

```bash
# Criar manualmente
aws s3 mb s3://shopping-images --endpoint-url http://localhost:4566
```

### Erro de conexão no Flutter (Android)

O emulador Android usa `10.0.2.2` para acessar o localhost do host. Verifique o arquivo `lib/config/app_config.dart`.

### Permissão negada no script de inicialização

```bash
chmod +x localstack/init-scripts/10-create-bucket.sh
```

---

## 📝 Variáveis de Ambiente

```bash
# LocalStack
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_DEFAULT_REGION=us-east-1
LOCALSTACK_ENDPOINT=http://localhost:4566

# Bucket
BUCKET_NAME=shopping-images
```

---

## 🔐 Considerações de Segurança

> ⚠️ **ATENÇÃO:** Este projeto usa credenciais de teste e é destinado apenas para desenvolvimento local.

Para ambiente de produção:
- [ ] Usar IAM roles/policies reais
- [ ] Implementar autenticação (Cognito, JWT)
- [ ] Validar tipos de arquivo permitidos
- [ ] Implementar rate limiting
- [ ] Usar HTTPS
- [ ] Definir tamanho máximo de upload
- [ ] Sanitizar nomes de arquivo

---

## ✅ Checklist de Apresentação

### Roteiro Obrigatório

- [x] **Infraestrutura:** `docker-compose up` funcionando
- [x] **Configuração:** Bucket `shopping-images` existe
- [x] **Backend:** Endpoint `/photos/upload` implementado
- [x] **Mobile:** App Flutter com câmera integrada
- [x] **Validação:** Fotos aparecem no S3 local
- [x] **Evidências:** Logs documentados

### Comandos para Demonstração

```bash
# 1. Mostrar containers rodando
docker-compose ps

# 2. Mostrar bucket existe
aws s3 ls --endpoint-url http://localhost:4566

# 3. Rodar app e tirar foto
flutter run

# 4. Mostrar foto no S3
aws s3 ls s3://shopping-images --recursive --endpoint-url http://localhost:4566
```

---

## 📚 Referências

- [LocalStack Documentation](https://docs.localstack.cloud/)
- [AWS S3 SDK for JavaScript](https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/s3-examples.html)
- [Serverless Framework](https://www.serverless.com/framework/docs)
- [Flutter Image Picker](https://pub.dev/packages/image_picker)
- [Flutter HTTP Package](https://pub.dev/packages/http)

---

## 📄 Licença



---

<div align="center">

**Desenvolvido por Kaio H. Silveira para PUC Minas - Engenharia de Software**

Dezembro 2025

</div>
