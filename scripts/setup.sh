#!/bin/bash

# Script de setup para o DeeperHub
# Este script configura o ambiente de desenvolvimento

set -e

echo "🚀 Configurando DeeperHub..."

# Verificar se o Elixir está instalado
if ! command -v elixir &> /dev/null; then
    echo "❌ Elixir não encontrado. Por favor, instale o Elixir primeiro."
    exit 1
fi

# Verificar se o Mix está disponível
if ! command -v mix &> /dev/null; then
    echo "❌ Mix não encontrado. Por favor, instale o Elixir corretamente."
    exit 1
fi

echo "✅ Elixir encontrado: $(elixir --version | head -n1)"

# Instalar Hex se não estiver instalado
echo "📦 Instalando Hex..."
mix local.hex --force

# Instalar Rebar se não estiver instalado
echo "🔧 Instalando Rebar..."
mix local.rebar --force

# Criar diretórios necessários
echo "📁 Criando diretórios..."
mkdir -p databases
mkdir -p logs
mkdir -p priv/data
mkdir -p ssl

# Copiar arquivo de ambiente se não existir
if [ ! -f .env ]; then
    echo "📋 Criando arquivo .env..."
    cp .env.example .env
    echo "⚠️  Por favor, edite o arquivo .env com suas configurações"
fi

# Instalar dependências
echo "📦 Instalando dependências..."
mix deps.get

# Compilar o projeto
echo "🔨 Compilando projeto..."
mix compile

# Executar migrações (se necessário)
echo "🗄️  Executando migrações..."
mix run -e "DeeperHub.Core.Data.Migrations.Initializer.run()"

# Gerar chaves secretas se não existirem no .env
if ! grep -q "SECRET_KEY_BASE=" .env || [ -z "$(grep SECRET_KEY_BASE .env | cut -d'=' -f2)" ]; then
    echo "🔐 Gerando SECRET_KEY_BASE..."
    SECRET_KEY=$(mix phx.gen.secret)
    sed -i "s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$SECRET_KEY/" .env
fi

if ! grep -q "GUARDIAN_SECRET_KEY=" .env || [ -z "$(grep GUARDIAN_SECRET_KEY .env | cut -d'=' -f2)" ]; then
    echo "🔐 Gerando GUARDIAN_SECRET_KEY..."
    GUARDIAN_SECRET=$(mix guardian.gen.secret)
    sed -i "s/GUARDIAN_SECRET_KEY=.*/GUARDIAN_SECRET_KEY=$GUARDIAN_SECRET/" .env
fi

echo "✅ Setup concluído!"
echo ""
echo "🎯 Próximos passos:"
echo "1. Edite o arquivo .env com suas configurações"
echo "2. Execute 'mix run --no-halt' para iniciar o servidor"
echo "3. Acesse http://localhost:4000 para testar"
echo ""
echo "📚 Comandos úteis:"
echo "  mix test              - Executar testes"
echo "  mix format            - Formatar código"
echo "  mix credo             - Análise de código"
echo "  mix deps.update --all - Atualizar dependências"
echo ""