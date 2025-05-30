# DeeperHub

Sistema de comunicação em tempo real construído com Elixir, focado em performance, segurança e escalabilidade.

## 🚀 Funcionalidades

- **Autenticação Segura**: JWT com suporte a 2FA
- **Comunicação em Tempo Real**: WebSockets com canais
- **Sistema de Presença**: Rastreamento de usuários online
- **Cache Distribuído**: Sistema de cache avançado com Cachex
- **Segurança Robusta**: Detecção de anomalias e proteção contra ataques
- **Monitoramento**: Telemetria e métricas integradas
- **Escalabilidade**: Suporte a clustering e load balancing

## 📋 Pré-requisitos

- Elixir 1.18+
- Erlang/OTP 26+
- SQLite 3
- Redis (opcional, para cache distribuído)
- Docker (opcional, para containerização)

## 🛠️ Instalação

### Desenvolvimento Local

1. Clone o repositório:
```bash
git clone <repository-url>
cd deeper_hub
```

2. Execute o script de setup:
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

3. Configure as variáveis de ambiente:
```bash
cp .env.example .env
# Edite o arquivo .env com suas configurações
```

4. Inicie o servidor:
```bash
mix run --no-halt
```

### Docker

1. Build da imagem:
```bash
docker build -t deeper_hub .
```

2. Execute com docker-compose:
```bash
docker-compose up -d
```

## ⚙️ Configuração

### Variáveis de Ambiente

Consulte o arquivo `.env.example` para todas as variáveis disponíveis:

- `SECRET_KEY_BASE`: Chave secreta para sessões
- `GUARDIAN_SECRET_KEY`: Chave secreta para JWT
- `DATABASE_PATH`: Caminho para o banco SQLite
- `PORT`: Porta do servidor (padrão: 4000)
- `SMTP_*`: Configurações de email

### Configuração por Ambiente

- **Desenvolvimento**: `config/dev.exs`
- **Produção**: `config/prod.exs`
- **Testes**: `config/test.exs`
- **Runtime**: `config/runtime.exs`

## 🧪 Testes

```bash
# Executar todos os testes
mix test

# Testes com coverage
mix test --cover

# Testes em modo watch
mix test.watch
```

## 📊 Monitoramento

### Health Check

```bash
curl http://localhost:4000/health
```

### Métricas

O sistema expõe métricas Prometheus em `/metrics` (quando configurado).

### Logs

- **Desenvolvimento**: Console colorido
- **Produção**: JSON estruturado em arquivo

## 🔒 Segurança

### Funcionalidades Implementadas

- Rate limiting por endpoint
- Headers de segurança (HSTS, CSP, etc.)
- Sanitização de dados sensíveis nos logs
- Detecção de anomalias
- Proteção contra ataques comuns (XSS, CSRF, SQL Injection)

### Auditoria

Todas as ações importantes são auditadas automaticamente:

```elixir
DeeperHub.Core.Logger.audit("user_login", 
  user_id: user.id, 
  ip_address: conn.remote_ip
)
```

## 🚀 Deploy

### Produção Manual

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### Docker em Produção

```bash
docker-compose -f docker-compose.yml up -d
```

### Variáveis de Produção

Certifique-se de configurar:
- `MIX_ENV=prod`
- `SECRET_KEY_BASE` (gerado com `mix phx.gen.secret`)
- `GUARDIAN_SECRET_KEY` (gerado com `mix guardian.gen.secret`)
- `DATABASE_PATH` (caminho persistente)
- Configurações SMTP para emails

## 📚 API

### Autenticação

```bash
# Login
POST /auth/login
{
  "email": "user@example.com",
  "password": "password"
}

# Refresh token
POST /auth/refresh
{
  "refresh_token": "..."
}
```

### WebSockets

```javascript
// Conectar ao socket
const socket = new WebSocket('ws://localhost:4000/socket');

// Entrar em um canal
socket.send(JSON.stringify({
  topic: "room:lobby",
  event: "phx_join",
  payload: {},
  ref: "1"
}));
```

## 🏗️ Arquitetura

```
lib/
├── deeper_hub/
│   ├── accounts/          # Gerenciamento de usuários
│   ├── core/
│   │   ├── cache/         # Sistema de cache
│   │   ├── data/          # Banco de dados
│   │   ├── http/          # Endpoints HTTP
│   │   ├── logger/        # Sistema de logging
│   │   ├── mail/          # Sistema de email
│   │   ├── network/       # WebSockets e canais
│   │   ├── security/      # Segurança
│   │   └── telemetry/     # Métricas
│   └── web_interface/     # Controllers e rotas
```

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

### Padrões de Código

```bash
# Formatar código
mix format

# Análise de código
mix credo --strict

# Verificação de segurança
mix sobelow
```

## 📄 Licença

Este projeto está licenciado sob a MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🆘 Suporte

- **Issues**: [GitHub Issues](https://github.com/your-repo/deeper_hub/issues)
- **Documentação**: [Docs](https://your-docs-url.com)
- **Email**: support@deeperhub.com

## 🎯 Roadmap

- [ ] Interface web completa
- [ ] Mobile app
- [ ] Integração com terceiros
- [ ] Machine learning para detecção de anomalias
- [ ] Suporte a múltiplos bancos de dados
- [ ] Clustering automático

---

Feito com ❤️ pela equipe DeeperHub
