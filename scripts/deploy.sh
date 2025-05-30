#!/bin/bash

# Script de deploy para produção do DeeperHub
# Este script automatiza o processo de deploy

set -e

echo "🚀 Iniciando deploy do DeeperHub..."

# Verificar se estamos no ambiente correto
if [ "$MIX_ENV" != "prod" ]; then
    echo "⚠️  Definindo MIX_ENV=prod"
    export MIX_ENV=prod
fi

# Verificar se as variáveis de ambiente estão definidas
required_vars=("SECRET_KEY_BASE" "GUARDIAN_SECRET_KEY" "DATABASE_PATH")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Variável de ambiente $var não definida"
        exit 1
    fi
done

echo "✅ Variáveis de ambiente verificadas"

# Limpar builds anteriores
echo "🧹 Limpando builds anteriores..."
mix clean
rm -rf _build/prod

# Instalar dependências de produção
echo "📦 Instalando dependências de produção..."
mix deps.get --only prod
mix deps.compile

# Compilar assets (se houver)
echo "🎨 Compilando assets..."
# mix assets.deploy (descomente se tiver assets)

# Compilar aplicação
echo "🔨 Compilando aplicação..."
mix compile

# Executar testes antes do deploy
echo "🧪 Executando testes..."
MIX_ENV=test mix test

# Criar release
echo "📦 Criando release..."
mix release --overwrite

# Backup do banco de dados atual (se existir)
if [ -f "$DATABASE_PATH" ]; then
    echo "💾 Fazendo backup do banco de dados..."
    cp "$DATABASE_PATH" "${DATABASE_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Executar migrações
echo "🗄️  Executando migrações..."
_build/prod/rel/deeper_hub/bin/deeper_hub eval "DeeperHub.Core.Data.Migrations.Initializer.run()"

# Verificar saúde da aplicação
echo "🏥 Verificando saúde da aplicação..."
timeout 30 _build/prod/rel/deeper_hub/bin/deeper_hub rpc "DeeperHub.health_check()" || {
    echo "❌ Health check falhou"
    exit 1
}

echo "✅ Deploy concluído com sucesso!"
echo ""
echo "🎯 Próximos passos:"
echo "1. Inicie a aplicação: _build/prod/rel/deeper_hub/bin/deeper_hub start"
echo "2. Monitore os logs: tail -f $LOG_FILE_PATH"
echo "3. Verifique a saúde: curl http://localhost:$PORT/health"
echo ""