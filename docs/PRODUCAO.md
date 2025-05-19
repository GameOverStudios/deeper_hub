# Guia de Produção para o DeeperHub

Este documento fornece instruções detalhadas para implantação, operação e manutenção do sistema DeeperHub em ambiente de produção.

## Índice

1. [Requisitos](#requisitos)
2. [Implantação](#implantação)
3. [Configuração](#configuração)
4. [Monitoramento](#monitoramento)
5. [Backup e Recuperação](#backup-e-recuperação)
6. [Solução de Problemas](#solução-de-problemas)
7. [Segurança](#segurança)

## Requisitos

### Hardware Recomendado

- CPU: 2+ núcleos
- Memória: 2GB+ RAM
- Armazenamento: 20GB+ SSD
- Rede: Conexão estável com baixa latência

### Software Necessário

- Sistema Operacional: Linux (Ubuntu 22.04 LTS ou superior recomendado)
- Erlang/OTP 26 ou superior
- Elixir 1.18 ou superior
- SQLite 3.35.0 ou superior

## Implantação

### Usando o Script de Deploy

O DeeperHub inclui um script de deploy automatizado que facilita a implantação em servidores de produção:

```bash
# Configure as variáveis de ambiente necessárias
export GUARDIAN_SECRET_KEY="sua_chave_secreta_muito_longa_e_aleatoria"
export DEPLOY_HOST="seu-servidor.com"
export DEPLOY_USER="deploy"
export DEPLOY_DIR="/opt/deeper_hub"

# Execute o script de deploy
./deploy.sh production
```

### Implantação Manual

Se preferir uma implantação manual, siga estes passos:

1. Compile e gere o release:
   ```bash
   MIX_ENV=prod mix deps.get --only prod
   MIX_ENV=prod mix compile
   MIX_ENV=prod mix release deeper_hub
   ```

2. Transfira o release para o servidor:
   ```bash
   tar -czf deeper_hub_release.tar.gz _build/prod/rel/deeper_hub/
   scp deeper_hub_release.tar.gz usuario@servidor:/caminho/destino/
   ```

3. No servidor, descompacte e configure:
   ```bash
   mkdir -p /opt/deeper_hub
   tar -xzf deeper_hub_release.tar.gz -C /opt/deeper_hub
   cd /opt/deeper_hub
   ```

4. Configure as variáveis de ambiente:
   ```bash
   export GUARDIAN_SECRET_KEY="sua_chave_secreta"
   export PORT="8080"
   ```

5. Inicie o serviço:
   ```bash
   bin/deeper_hub daemon
   ```

## Configuração

### Variáveis de Ambiente Essenciais

| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `GUARDIAN_SECRET_KEY` | Chave secreta para tokens JWT | `dBGr8WLRYrE6...` |
| `PORT` | Porta para o servidor HTTP | `8080` |
| `DEEPER_HUB_DB_PATH` | Caminho para o banco de dados | `/data/deeper_hub_prod.db` |
| `DEEPER_HUB_DB_POOL_SIZE` | Tamanho do pool de conexões | `20` |
| `DEEPER_HUB_LOG_LEVEL` | Nível de log | `info` |
| `MAX_CONNECTIONS` | Limite de conexões WebSocket | `10000` |
| `DEEPER_HUB_SECURITY_RATE_LIMIT_API` | Limite de requisições API por minuto | `60` |
| `DEEPER_HUB_SECURITY_RATE_LIMIT_WS` | Limite de mensagens WebSocket por minuto | `120` |
| `DEEPER_HUB_SECURITY_ALERT_WEBHOOK` | URL para webhook de alertas de segurança | `https://alertas.exemplo.com/webhook` |

### Arquivo de Configuração Runtime

Para configurações mais complexas, edite o arquivo `config/runtime.exs` no release:

```elixir
# Exemplo de configuração personalizada
config :deeper_hub, :network,
  max_connections: 20000,
  max_frame_size: 2097152  # 2MB
```

## Monitoramento

### Métricas Prometheus

O DeeperHub expõe métricas no formato Prometheus em `/metrics`. Configure o Prometheus para coletar estas métricas:

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'deeper_hub'
    scrape_interval: 15s
    static_configs:
      - targets: ['seu-servidor.com:8080']
```

### Dashboards Grafana

Recomendamos os seguintes painéis para monitoramento:

1. **Visão Geral do Sistema**:
   - Uso de CPU, memória e disco
   - Conexões ativas
   - Taxa de mensagens

2. **WebSockets**:
   - Conexões por segundo
   - Latência de mensagens
   - Taxa de erros

3. **Banco de Dados**:
   - Tempo de consulta
   - Uso do pool de conexões
   - Tamanho do banco de dados

### Alertas Recomendados

Configure alertas para:

- Uso de CPU acima de 80% por mais de 5 minutos
- Memória disponível abaixo de 20%
- Taxa de erros acima de 1%
- Tempo de resposta médio acima de 500ms

## Backup e Recuperação

### Backup Automático do Banco de Dados

Configure um job cron para backup diário:

```bash
# /etc/cron.daily/deeper_hub_backup
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR="/backups/deeper_hub"
DB_PATH="/opt/deeper_hub/databases/deeper_hub_prod.db"

mkdir -p $BACKUP_DIR
sqlite3 $DB_PATH ".backup '$BACKUP_DIR/deeper_hub_$DATE.db'"
gzip "$BACKUP_DIR/deeper_hub_$DATE.db"

# Manter apenas os últimos 30 backups
find $BACKUP_DIR -name "deeper_hub_*.db.gz" -type f -mtime +30 -delete
```

### Procedimento de Recuperação

Para restaurar a partir de um backup:

1. Pare o serviço:
   ```bash
   /opt/deeper_hub/bin/deeper_hub stop
   ```

2. Restaure o banco de dados:
   ```bash
   gunzip -c /backups/deeper_hub/deeper_hub_20250518.db.gz > /tmp/restored.db
   mv /tmp/restored.db /opt/deeper_hub/databases/deeper_hub_prod.db
   ```

3. Reinicie o serviço:
   ```bash
   /opt/deeper_hub/bin/deeper_hub start
   ```

## Solução de Problemas

### Logs do Sistema

Os logs são armazenados em:
- `/opt/deeper_hub/var/log/erlang.log` - Log do runtime Erlang
- `/opt/deeper_hub/var/log/deeper_hub.log` - Log da aplicação

### Problemas Comuns

#### Serviço não inicia

Verifique:
1. Permissões de arquivos e diretórios
2. Variáveis de ambiente configuradas corretamente
3. Logs de erro em `/opt/deeper_hub/var/log/`

#### Conexões WebSocket falham

Verifique:
1. Configurações de firewall (porta 8080 aberta)
2. Limite de conexões do sistema operacional (`sysctl -a | grep file-max`)
3. Logs para erros de autenticação

#### Desempenho lento

Verifique:
1. Uso de CPU e memória
2. Tamanho e fragmentação do banco de dados
3. Número de conexões ativas

### Comandos Úteis

```bash
# Verificar status do serviço
/opt/deeper_hub/bin/deeper_hub status

# Verificar versão em execução
/opt/deeper_hub/bin/deeper_hub version

# Iniciar console remoto
/opt/deeper_hub/bin/deeper_hub remote

# Reiniciar o serviço
/opt/deeper_hub/bin/deeper_hub restart
```

## Segurança

### Práticas Recomendadas

1. **Atualize regularmente**:
   - Verifique atualizações do DeeperHub
   - Mantenha o sistema operacional atualizado

2. **Proteja o acesso**:
   - Use firewall para limitar acesso às portas
   - Configure autenticação por chave SSH
   - Use HTTPS para todas as comunicações

3. **Monitore atividades suspeitas**:
   - Configure alertas para tentativas de login inválidas
   - Monitore uso anormal de recursos
   - Verifique logs regularmente

### Configuração de Recursos Avançados de Segurança

#### Detector de Anomalias

O detector de anomalias pode ser configurado no arquivo `runtime.exs`:

```elixir
config :deeper_hub, :anomaly_detection, [
  login_failure_threshold: 5,  # Limite de tentativas de login falhas
  login_failure_window: 300,    # Janela de tempo em segundos
  not_found_threshold: 10,      # Limite de requisições 404
  not_found_window: 60,         # Janela de tempo em segundos
  malicious_payload_threshold: 3,  # Limite de payloads maliciosos
  malicious_payload_window: 600    # Janela de tempo em segundos
]
```

#### Sistema de Reputação de IPs

O sistema de reputação de IPs é configurado automaticamente, mas você pode ajustar os limites de risco:

```elixir
config :deeper_hub, :ip_reputation, [
  high_risk_threshold: 30,    # Pontuação abaixo da qual um IP é considerado de alto risco
  medium_risk_threshold: 60,  # Pontuação abaixo da qual um IP é considerado de médio risco
  check_interval: 300_000     # Intervalo de verificação de reputação em milissegundos
]
```

#### Sistema de Alertas

Configure os canais de notificação para alertas de segurança:

```elixir
config :deeper_hub, :security_alerts, [
  notification_channels: [
    {:log, []},  # Sempre registra em log
    {:webhook, "https://seu-servidor.com/webhooks/security"},  # Webhook para integração
    {:email, [recipients: ["admin@exemplo.com", "seguranca@exemplo.com"]]}
  ]
]
```

### Monitoramento de Segurança

Recomendamos configurar alertas específicos para eventos de segurança:

1. **Tentativas de login falhas** - Alerta quando houver mais de 10 falhas em 5 minutos
2. **Bloqueios de IP** - Notificação imediata quando um IP for bloqueado automaticamente
3. **Detecção de anomalias** - Alerta para padrões suspeitos de tráfego
4. **Reputação de IPs** - Relatório diário de IPs com baixa reputação

### Rotação de Chaves

Recomendamos a rotação periódica das chaves de segurança:

1. Gere uma nova chave secreta:
   ```bash
   mix phx.gen.secret
   ```

2. Atualize a variável de ambiente:
   ```bash
   export GUARDIAN_SECRET_KEY="nova_chave_secreta"
   ```

3. Reinicie o serviço:
   ```bash
   /opt/deeper_hub/bin/deeper_hub restart
   ```

4. Revogue todos os tokens antigos (opcional, mas recomendado)

---

Para suporte adicional, consulte a documentação completa ou entre em contato com a equipe de desenvolvimento.
