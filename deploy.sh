#!/bin/bash
# Script de deploy automatizado para o DeeperHub
# Uso: ./deploy.sh [ambiente]
# Exemplo: ./deploy.sh production

set -e  # Encerra o script se qualquer comando falhar

# Verifica argumentos
AMBIENTE=${1:-production}
echo "Iniciando deploy para ambiente: $AMBIENTE"

# Configurações
APP_NAME="deeper_hub"
RELEASE_DIR="_build/$AMBIENTE/rel/$APP_NAME"
REMOTE_USER=${DEPLOY_USER:-"deploy"}
REMOTE_HOST=${DEPLOY_HOST:-"seu-servidor.com"}
REMOTE_DIR=${DEPLOY_DIR:-"/opt/deeper_hub"}
RELEASE_COOKIE=${RELEASE_COOKIE:-"deeper_hub_release_cookie"}

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Funções auxiliares
function step() {
  echo -e "${GREEN}==>${NC} $1"
}

function warn() {
  echo -e "${YELLOW}AVISO:${NC} $1"
}

function error() {
  echo -e "${RED}ERRO:${NC} $1"
  exit 1
}

# Verifica dependências
command -v mix >/dev/null 2>&1 || error "Elixir/Mix não encontrado. Instale o Elixir antes de continuar."
command -v ssh >/dev/null 2>&1 || error "SSH não encontrado. Instale o SSH antes de continuar."
command -v scp >/dev/null 2>&1 || error "SCP não encontrado. Instale o SCP antes de continuar."

# Verifica variáveis de ambiente necessárias
if [ "$AMBIENTE" = "production" ]; then
  [ -z "$GUARDIAN_SECRET_KEY" ] && error "Variável de ambiente GUARDIAN_SECRET_KEY não definida"
  [ -z "$DEPLOY_HOST" ] && warn "Variável DEPLOY_HOST não definida, usando valor padrão: $REMOTE_HOST"
  [ -z "$DEPLOY_USER" ] && warn "Variável DEPLOY_USER não definida, usando valor padrão: $REMOTE_USER"
fi

# Etapa 1: Compilação e geração do release
step "Limpando compilações anteriores..."
mix deps.clean --all
mix clean

step "Obtendo dependências..."
MIX_ENV=$AMBIENTE mix deps.get --only $AMBIENTE

step "Compilando aplicação..."
MIX_ENV=$AMBIENTE mix compile

step "Executando testes..."
if [ "$AMBIENTE" = "production" ]; then
  MIX_ENV=test mix test || warn "Testes falharam, mas continuando deploy..."
fi

step "Gerando release..."
MIX_ENV=$AMBIENTE mix release $APP_NAME

# Verifica se o release foi gerado com sucesso
if [ ! -d "$RELEASE_DIR" ]; then
  error "Falha ao gerar o release. Diretório $RELEASE_DIR não encontrado."
fi

# Etapa 2: Empacotamento
TIMESTAMP=$(date +%Y%m%d%H%M%S)
RELEASE_FILENAME="${APP_NAME}_${AMBIENTE}_${TIMESTAMP}.tar.gz"

step "Empacotando release: $RELEASE_FILENAME"
cd "$RELEASE_DIR"
tar -czf "../../../$RELEASE_FILENAME" .
cd -

# Etapa 3: Deploy para servidor remoto (se em produção)
if [ "$AMBIENTE" = "production" ]; then
  step "Preparando servidor remoto..."
  ssh $REMOTE_USER@$REMOTE_HOST "mkdir -p $REMOTE_DIR/releases"

  step "Enviando release para o servidor remoto..."
  scp "$RELEASE_FILENAME" $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/releases/

  step "Descompactando release no servidor remoto..."
  ssh $REMOTE_USER@$REMOTE_HOST "cd $REMOTE_DIR && \
    mkdir -p $TIMESTAMP && \
    tar -xzf releases/$RELEASE_FILENAME -C $TIMESTAMP && \
    ln -sfn $TIMESTAMP current && \
    echo 'Definindo variáveis de ambiente...' && \
    echo 'export RELEASE_COOKIE=\"$RELEASE_COOKIE\"' > current/env.sh && \
    echo 'export GUARDIAN_SECRET_KEY=\"$GUARDIAN_SECRET_KEY\"' >> current/env.sh && \
    echo 'export PORT=\"8080\"' >> current/env.sh && \
    chmod +x current/env.sh"

  step "Reiniciando serviço..."
  ssh $REMOTE_USER@$REMOTE_HOST "cd $REMOTE_DIR && \
    source current/env.sh && \
    if pgrep -f \"$APP_NAME\"; then \
      echo 'Parando serviço existente...' && \
      current/bin/$APP_NAME stop || true; \
    fi && \
    echo 'Iniciando novo serviço...' && \
    current/bin/$APP_NAME daemon"

  step "Verificando status do serviço..."
  ssh $REMOTE_USER@$REMOTE_HOST "cd $REMOTE_DIR && \
    current/bin/$APP_NAME pid && \
    current/bin/$APP_NAME version"
else
  step "Release gerado com sucesso: $RELEASE_FILENAME"
  echo "Para iniciar o release localmente, execute:"
  echo "./$RELEASE_DIR/bin/$APP_NAME start"
fi

step "Deploy concluído com sucesso!"
