# Sistema de Email do DeeperHub

Este documento descreve o sistema de email implementado no DeeperHub, incluindo sua arquitetura, configuração, uso e melhores práticas.

## Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura](#arquitetura)
3. [Configuração](#configuração)
4. [Uso](#uso)
5. [Filas de Email](#filas-de-email)
6. [Templates](#templates)
7. [Monitoramento](#monitoramento)
8. [Segurança](#segurança)
9. [Resolução de Problemas](#resolução-de-problemas)

## Visão Geral

O sistema de email do DeeperHub fornece uma infraestrutura robusta para o envio de emails transacionais e notificações. Ele suporta:

- Envio síncrono e assíncrono de emails
- Filas persistentes para garantir a entrega mesmo em caso de falhas
- Templates HTML e texto plano
- Priorização de mensagens
- Retry automático em caso de falha
- Integração com o sistema de alertas de segurança

## Arquitetura

O sistema é composto pelos seguintes módulos:

- `DeeperHub.Core.Mail`: Módulo principal que expõe a API pública
- `DeeperHub.Core.Mail.Sender`: Responsável pelo envio de emails via SMTP
- `DeeperHub.Core.Mail.Queue`: Implementa a fila persistente de emails
- `DeeperHub.Core.Mail.Templates`: Gerencia a renderização de templates
- `DeeperHub.Core.Mail.Templates.*`: Templates específicos para diferentes tipos de email

A árvore de supervisão garante que os componentes sejam inicializados na ordem correta e supervisionados para tolerância a falhas.

## Configuração

A configuração do sistema de email é feita no arquivo `config/config.exs` e pode ser sobrescrita em arquivos específicos de ambiente:

```elixir
config :deeper_hub, :mail, 
  sender_email: System.get_env("MAIL_SENDER", "noreply@deeperhub.com"),
  support_email: System.get_env("MAIL_SUPPORT", "suporte@deeperhub.com"),
  test_mode: System.get_env("MAIL_TEST_MODE", "true") == "true",
  smtp: [
    server: System.get_env("SMTP_SERVER", "smtp.exemplo.com"),
    port: String.to_integer(System.get_env("SMTP_PORT", "587")),
    username: System.get_env("SMTP_USERNAME", ""),
    password: System.get_env("SMTP_PASSWORD", ""),
    ssl: System.get_env("SMTP_SSL", "false") == "true",
    tls: System.get_env("SMTP_TLS", "true") == "true",
    auth: System.get_env("SMTP_AUTH", "true") == "true"
  ]
```

### Variáveis de Ambiente

| Variável | Descrição | Valor Padrão |
|----------|-----------|--------------|
| `MAIL_SENDER` | Email do remetente | `noreply@deeperhub.com` |
| `MAIL_SUPPORT` | Email de suporte | `suporte@deeperhub.com` |
| `MAIL_TEST_MODE` | Modo de teste (não envia emails reais) | `true` |
| `SMTP_SERVER` | Servidor SMTP | `smtp.exemplo.com` |
| `SMTP_PORT` | Porta do servidor SMTP | `587` |
| `SMTP_USERNAME` | Nome de usuário para autenticação SMTP | `""` |
| `SMTP_PASSWORD` | Senha para autenticação SMTP | `""` |
| `SMTP_SSL` | Usar SSL para conexão SMTP | `false` |
| `SMTP_TLS` | Usar TLS para conexão SMTP | `true` |
| `SMTP_AUTH` | Usar autenticação SMTP | `true` |

## Uso

### Envio Básico

```elixir
DeeperHub.Core.Mail.send_email(
  "usuario@exemplo.com",
  "Assunto do Email",
  :welcome,
  %{username: "Nome do Usuário"}
)
```

### Envio via Fila

```elixir
DeeperHub.Core.Mail.send_email(
  "usuario@exemplo.com",
  "Assunto do Email",
  :welcome,
  %{username: "Nome do Usuário"},
  [use_queue: true, priority: :normal]
)
```

### Envio Assíncrono

```elixir
DeeperHub.Core.Mail.send_email(
  "usuario@exemplo.com",
  "Assunto do Email",
  :welcome,
  %{username: "Nome do Usuário"},
  [async: true]
)
```

### Alertas de Segurança

```elixir
DeeperHub.Core.Mail.send_security_alert(
  "admin@exemplo.com",
  "Tentativa de Login Suspeita",
  "Múltiplas tentativas de login falhas detectadas",
  %{
    ip: "192.168.1.100",
    tentativas: 5,
    timestamp: DateTime.utc_now()
  },
  :warning
)
```

### Emails de Boas-vindas

```elixir
DeeperHub.Core.Mail.send_welcome_email(
  "novo@exemplo.com",
  "Nome do Usuário",
  "https://deeperhub.com/verificar/token123"
)
```

### Emails de Redefinição de Senha

```elixir
DeeperHub.Core.Mail.send_password_reset(
  "usuario@exemplo.com",
  "Nome do Usuário",
  "https://deeperhub.com/redefinir/token456",
  24  # horas de validade
)
```

## Filas de Email

O sistema implementa uma fila persistente para garantir que emails não sejam perdidos em caso de falha do sistema. A fila suporta:

- Priorização (alta, normal, baixa)
- Retry automático em caso de falha
- Persistência em disco
- Limpeza automática de emails antigos

### Monitoramento da Fila

```elixir
# Obter estatísticas da fila
stats = DeeperHub.Core.Mail.Queue.get_stats()

# Limpar emails antigos já enviados (mais de 1 dia)
DeeperHub.Core.Mail.Queue.clean_sent_emails(86400)
```

## Templates

Os templates de email são definidos como módulos Elixir separados, o que facilita a manutenção e a organização. Cada template implementa funções para renderizar versões HTML e texto plano.

Templates disponíveis:

- `SecurityAlert`: Alertas de segurança
- `Welcome`: Boas-vindas para novos usuários
- `PasswordReset`: Redefinição de senha
- `Fallback`: Template genérico para casos não cobertos

### Criando Novos Templates

Para criar um novo template:

1. Crie um arquivo em `lib/deeper_hub/core/mail/templates/nome_do_template.ex`
2. Implemente as funções `render_html/1` e `render_text/1`
3. Atualize o módulo `DeeperHub.Core.Mail.Templates` para incluir o novo template

## Monitoramento

O sistema de email inclui logs detalhados para facilitar o monitoramento e a depuração:

- Logs de envio de email
- Logs de processamento da fila
- Logs de erros e retries

Recomenda-se configurar alertas para monitorar:

- Falhas de envio de email
- Crescimento anormal da fila
- Emails que excederam o número máximo de tentativas

## Segurança

Considerações de segurança:

- **Credenciais SMTP**: Armazenadas como variáveis de ambiente, não hardcoded
- **Modo de Teste**: Evita envio acidental de emails em ambientes de desenvolvimento
- **Sanitização**: Todos os dados inseridos em templates são sanitizados automaticamente
- **Rate Limiting**: Implementado no nível da aplicação para evitar abuso

## Resolução de Problemas

### Emails não estão sendo enviados

1. Verifique se o modo de teste está desativado (`MAIL_TEST_MODE=false`)
2. Verifique as credenciais SMTP
3. Verifique os logs para erros específicos
4. Verifique se o servidor SMTP está acessível

### Emails estão na fila mas não são processados

1. Verifique se o supervisor de email está rodando
2. Verifique se há erros nos logs
3. Reinicie o aplicativo para forçar o reprocessamento da fila

### Problemas de Renderização de Template

1. Verifique se todos os assigns necessários estão sendo fornecidos
2. Verifique se o template existe e está registrado
3. Teste o template isoladamente
