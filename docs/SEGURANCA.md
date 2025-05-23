# Guia de Segurança para o DeeperHub

Este documento detalha as práticas de segurança implementadas no sistema DeeperHub e fornece recomendações para manter o sistema seguro em ambiente de produção.

## Índice

1. [Visão Geral de Segurança](#visão-geral-de-segurança)
2. [Autenticação e Autorização](#autenticação-e-autorização)
3. [Proteção de Dados](#proteção-de-dados)
4. [Segurança de WebSockets](#segurança-de-websockets)
5. [Detecção de Anomalias](#detecção-de-anomalias)
6. [Sistema de Reputação de IPs](#sistema-de-reputação-de-ips)
7. [Sistema de Alertas](#sistema-de-alertas)
8. [Monitoramento e Auditoria](#monitoramento-e-auditoria)
9. [Configurações Recomendadas](#configurações-recomendadas)
10. [Resposta a Incidentes](#resposta-a-incidentes)

## Visão Geral de Segurança

O DeeperHub foi projetado com segurança em mente, implementando diversas camadas de proteção:

- **Autenticação robusta** com tokens JWT
- **Validação rigorosa** de entradas do usuário
- **Limites de taxa** para prevenir abusos
- **Proteção contra ataques comuns** (CSRF, XSS, injeção SQL)
- **Detecção de anomalias** para identificar padrões de ataque
- **Sistema de reputação de IPs** para gerenciar endereços suspeitos
- **Sistema de alertas** para notificar sobre eventos de segurança
- **Logging detalhado** para auditoria e detecção de intrusões

## Autenticação e Autorização

### Sistema JWT

O DeeperHub utiliza o Guardian para implementar autenticação baseada em JWT (JSON Web Tokens):

- **Tokens de acesso** com vida curta (1 hora por padrão)
- **Tokens de atualização** para renovação sem re-autenticação (30 dias por padrão)
- **Identificadores únicos (JTI)** para cada token, permitindo revogação
- **Assinatura criptográfica** para garantir integridade

### Armazenamento de Senhas

As senhas dos usuários são protegidas com:

- **Hashing PBKDF2** com fatores de custo elevados
- **Salt único** para cada senha
- **Proteção contra timing attacks** durante verificação
- **Validação robusta** de força de senha

### Boas Práticas

1. **Rotação de chaves**: Altere a chave secreta do Guardian periodicamente
2. **Revogação de tokens**: Implemente um sistema para revogar tokens comprometidos
3. **Autenticação de dois fatores**: Considere implementar 2FA para maior segurança

## Proteção de Dados

### Banco de Dados

O SQLite é configurado com:

- **Write-Ahead Logging (WAL)** para integridade de dados
- **Foreign keys** habilitadas para integridade referencial
- **Validação de entrada** para prevenir injeção SQL
- **Acesso controlado** através do pool de conexões

### Dados Sensíveis

- **Não armazene** dados sensíveis em texto puro
- **Use variáveis de ambiente** para segredos, não hardcode
- **Sanitize logs** para remover informações sensíveis
- **Implemente criptografia** para dados confidenciais em repouso

## Segurança de WebSockets

### Limitação de Taxa

O DeeperHub implementa controles para prevenir abusos:

- **Limite de mensagens**: 120 mensagens por minuto por usuário
- **Limite de tamanho**: Máximo de 16KB por mensagem
- **Limite de subscrições**: Máximo de 50 canais por usuário
- **Limite de conexões**: Configurável por usuário e global

### Validação de Mensagens

Todas as mensagens WebSocket passam por validação rigorosa:

- **Validação de formato**: Garante que a mensagem é JSON válido
- **Validação de estrutura**: Verifica campos obrigatórios e tipos
- **Validação de conteúdo**: Limita tamanho e caracteres permitidos
- **Sanitização**: Remove ou escapa conteúdo potencialmente perigoso

### Autenticação Contínua

- **Tokens JWT** são validados em cada conexão WebSocket
- **Verificação de tipo de token** para garantir uso apropriado
- **Verificação de expiração** em cada operação sensível
- **Associação de mensagens** ao usuário autenticado

## Detecção de Anomalias

### Funcionalidades Principais

O DeeperHub implementa um sistema de detecção de anomalias para identificar padrões suspeitos:

- **Monitoramento de tentativas de login**: Detecta múltiplas falhas de autenticação
- **Detecção de varredura de endpoints**: Identifica requisições 404 em sequência
- **Análise de payloads**: Detecta conteúdo potencialmente malicioso
- **Janelas de tempo configuráveis**: Permite ajustar a sensibilidade da detecção

### Configuração

O detector de anomalias pode ser configurado via variáveis de ambiente:

```elixir
config :deeper_hub, :anomaly_detection, [
  login_failure_threshold: 5,  # Limite de tentativas de login falhas
  login_failure_window: 300,   # Janela de tempo em segundos
  not_found_threshold: 10,     # Limite de requisições 404
  not_found_window: 60,        # Janela de tempo em segundos
  malicious_payload_threshold: 3,  # Limite de payloads maliciosos
  malicious_payload_window: 600    # Janela de tempo em segundos
]
```

### Ações Automáticas

Quando anomalias são detectadas, o sistema pode tomar ações automáticas:

- **Bloqueio temporário de IP**: Bloqueia IPs que excedem os limites configurados
- **Geração de alertas**: Notifica administradores sobre atividades suspeitas
- **Registro detalhado**: Armazena informações sobre o evento para análise posterior
- **Ajuste de reputação**: Reduz a pontuação de reputação do IP envolvido

## Sistema de Reputação de IPs

### Visão Geral

O sistema de reputação de IPs atribui uma pontuação dinâmica a cada endereço IP:

- **Escala de 0-100**: Onde 0 representa alto risco e 100 representa baixo risco
- **Pontuação adaptativa**: Ajusta-se com base no comportamento observado
- **Persistência em memória**: Utiliza tabelas ETS para armazenamento eficiente
- **Recuperação gradual**: IPs podem recuperar reputação ao longo do tempo

### Níveis de Risco

Os IPs são classificados em três níveis de risco:

- **Alto risco (0-30)**: IPs com comportamento claramente malicioso, bloqueados automaticamente
- **Médio risco (31-60)**: IPs suspeitos, sob vigilancia constante
- **Baixo risco (61-100)**: IPs com comportamento normal, permitidos sem restrições

### Fatores que Afetam a Reputação

A pontuação de reputação é influenciada por diversos fatores:

- **Tentativas de login falhas**: Reduz a pontuação (-5 por tentativa)
- **Requisições 404 em sequência**: Reduz a pontuação (-2 por requisição)
- **Payloads maliciosos**: Reduz significativamente a pontuação (-10 por ocorrência)
- **Bloqueios anteriores**: Forte impacto negativo (-20 por bloqueio)
- **Comportamento normal**: Recuperação gradual da pontuação ao longo do tempo

## Sistema de Alertas

### Tipos de Alertas

O DeeperHub implementa um sistema de alertas para notificar sobre eventos de segurança:

- **Alertas de autenticação**: Tentativas de login suspeitas ou falhas em sequência
- **Alertas de varredura**: Detecção de varredura de endpoints ou diretórios
- **Alertas de payload**: Detecção de conteúdo potencialmente malicioso
- **Alertas de bloqueio**: Notificações sobre IPs bloqueados automaticamente

### Níveis de Severidade

Os alertas são classificados em três níveis de severidade:

- **Info**: Eventos informativos que não representam ameaça imediata
- **Warning**: Eventos suspeitos que merecem atenção
- **Critical**: Eventos graves que exigem ação imediata

### Canais de Notificação

O sistema suporta múltiplos canais de notificação:

- **Logs**: Todos os alertas são registrados nos logs do sistema
- **Webhooks**: Notificações podem ser enviadas para endpoints HTTP externos
- **Email**: Alertas críticos podem ser enviados por email para administradores

### Configuração

Os canais de notificação podem ser configurados via variáveis de ambiente:

```elixir
config :deeper_hub, :security_alerts, [
  notification_channels: [
    {:log, []},
    {:webhook, "https://seu-servidor.com/webhooks/security"},
    {:email, [recipients: ["admin@exemplo.com"]]}
  ]
]
```

## Monitoramento e Auditoria

### Logging de Segurança

O sistema registra eventos de segurança importantes:

- **Tentativas de autenticação** (bem-sucedidas e falhas)
- **Operações sensíveis** em dados do usuário
- **Violações de limite de taxa**
- **Conexões e desconexões** de WebSockets
- **Erros de validação** de mensagens

### Monitoramento em Tempo Real

Utilize as métricas expostas para monitorar:

- **Padrões anormais** de autenticação
- **Picos de tráfego** que podem indicar ataques
- **Taxa de erros** elevada em endpoints específicos
- **Uso de recursos** do sistema

## Configurações Recomendadas

### Firewall

Configure seu firewall para:

- Permitir apenas tráfego necessário (portas 80/443 para HTTP/HTTPS, 8080 para WebSocket)
- Bloquear acesso direto ao banco de dados
- Implementar proteção contra DDoS
- Limitar tentativas de conexão por IP

### HTTPS

Sempre use HTTPS em produção:

- Configure TLS 1.3 ou superior
- Use certificados válidos (Let's Encrypt é uma opção gratuita)
- Configure HSTS para forçar conexões seguras
- Desative protocolos e cifras obsoletos

### Headers de Segurança

Adicione headers HTTP de segurança:

```
Content-Security-Policy: default-src 'self'; connect-src 'self' wss://seu-servidor.com;
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
```

## Resposta a Incidentes

### Plano de Resposta

Desenvolva um plano para responder a incidentes de segurança:

1. **Detecção**: Monitore logs e alertas para identificar incidentes
2. **Contenção**: Isole sistemas comprometidos para limitar danos
3. **Erradicação**: Remova a causa raiz do incidente
4. **Recuperação**: Restaure sistemas para operação normal
5. **Análise**: Documente o incidente e implemente melhorias

### Passos Imediatos em Caso de Comprometimento

Se suspeitar que o sistema foi comprometido:

1. **Revogue todos os tokens JWT** em uso
2. **Altere a chave secreta** do Guardian
3. **Force redefinição de senha** para todos os usuários
4. **Verifique logs** para identificar o escopo do comprometimento
5. **Notifique usuários afetados** conforme exigido por regulamentações

---

Este documento deve ser revisado e atualizado regularmente para refletir as melhores práticas de segurança e as mudanças no sistema DeeperHub.
