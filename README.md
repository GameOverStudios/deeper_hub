# DeeperHub

**DeeperHub** é uma aplicação Elixir projetada para fornecer uma plataforma escalável e resiliente para conectividade e colaboração em tempo real. Baseada na plataforma OTP, a aplicação segue princípios de design funcional, concorrência e tolerância a falhas.

## Características Principais

- **Arquitetura Baseada em OTP**: Utiliza processos leves e árvores de supervisão para máxima estabilidade
- **Sistema de Cache Otimizado**: Com Cachex integrado a telemetria para monitoramento em tempo real
- **Banco de Dados SQLite**: Através de Exqlite com pool de conexões gerenciado
- **EventBus Centralizado**: Para comunicação desacoplada entre componentes da aplicação
- **Telemetria Completa**: Sistema avançado de métricas e monitoramento de desempenho
- **Logging Robusto**: Sistema hierárquico com diferentes níveis e emissão de eventos para logs críticos

## Pré-requisitos

- Elixir 1.18 ou superior
- Erlang/OTP 26 ou superior
- SQLite 3.x

## Instalação e Configuração

### Ambiente de Desenvolvimento

1. Clone o repositório:
   ```bash
   git clone https://github.com/seu-usuario/deeper_hub.git
   cd deeper_hub
   ```

2. Instale as dependências:
   ```bash
   mix deps.get
   ```

3. Configure o ambiente (opcional):
   Edite os arquivos em `/config` conforme necessário.

4. Inicie a aplicação no modo de desenvolvimento:
   ```bash
   mix run --no-halt
   # ou para console interativo
   iex -S mix
   ```

### Ambiente de Produção

1. Crie uma release:
   ```bash
   MIX_ENV=prod mix release
   ```

2. Transfira a release para o servidor de produção

3. Configure as variáveis de ambiente:
   ```bash
   export DEEPER_HUB_DB_PATH="/data/databases"
   export DEEPER_HUB_DB_NAME="deeper_hub_prod.db"
   export DEEPER_HUB_DB_POOL_SIZE="10"
   ```

4. Execute a release:
   ```bash
   _build/prod/rel/deeper_hub/bin/deeper_hub start
   ```

## Estrutura do Projeto

O projeto está organizado em contextos dentro de `lib/deeper_hub/`:

- **Core**: Módulos fundamentais da aplicação
  - **Cache**: Sistema de cache com integração de eventos e telemetria
  - **Data**: Operações de banco de dados e migrações
  - **EventManager**: Sistema centralizado de eventos
  - **Logger**: Sistema avançado de logging
  - **Telemetry**: Métricas e monitoramento

## Integração EventBus

O sistema utiliza EventBus para comunicação entre diferentes módulos. Principais eventos:

- **Eventos de Sistema**: `system_started`, `system_stopping`
- **Eventos de Dados**: `data_created`, `data_updated`, `data_deleted`
- **Eventos de Log**: `log_error`, `log_alert`, `log_critical`, `log_emergency`

Subscribers podem observar estes eventos e reagir conforme necessário.

## Telemetria

O sistema de telemetria registra métricas em tempo real sobre:

- Operações de cache (hits, misses, expirations)
- Consultas ao banco de dados (duração, contagem)
- Status do pool de conexões
- Desempenho geral do sistema

## Comandos Úteis

```bash
# Iniciar em ambiente de desenvolvimento
mix run --no-halt

# Verificação de qualidade do código
mix code.check

# Formatar código automaticamente
mix code.fix

# Resetar banco de dados
mix db.reset

# Executar testes
mix test

# Executar testes com cobertura
mix test.all
```

## Licença

Copyright © 2025 - DeeperHub
