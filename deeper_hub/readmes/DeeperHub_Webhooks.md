# Módulo: `Deeper_Hub.Webhooks` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Webhooks`

O módulo `Deeper_Hub.Webhooks` é responsável por gerenciar e entregar **webhooks** para URLs de endpoints externos configurados por clientes ou outros sistemas. Webhooks são callbacks HTTP (geralmente POST) que o Deeper_Hub dispara automaticamente quando eventos específicos ocorrem na plataforma (ex: um novo usuário se registra, um pagamento é concluído, um servidor muda de status).

Este sistema permite integrações em tempo real e fluxos de trabalho automatizados entre o Deeper_Hub e aplicações de terceiros, sem a necessidade de polling constante. Ele lida com o registro de webhooks, a formatação de payloads, o envio seguro, o tratamento de respostas, retentativas e o monitoramento da saúde dos endpoints. 😊

*(Nota: A documentação original tem `Deeper_Hub.Webhooks` como módulo principal, e vários submódulos como `Dispatcher`, `Event`, `Integrations`, `Monitor`, `PayloadSigner`, `Scheduler`, `Schema`, `Services`, `Workers`. Esta documentação consolida a fachada principal em `Deeper_Hub.Webhooks` e organiza os componentes internos.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Registro e Gerenciamento de Webhooks (`register_webhook/5`, `update_webhook/2`, `delete_webhook/1`, `list_webhooks/2`):**
    *   Permitir que clientes (ou administradores) registrem URLs de endpoint para receber notificações de tipos de eventos específicos.
    *   Armazenar a URL, os tipos de eventos inscritos, um segredo opcional para assinatura de payload, e cabeçalhos customizados.
    *   Ativar/desativar webhooks.
*   **Processamento de Eventos do Sistema:**
    *   Escutar eventos do `Deeper_Hub.Core.EventBus` que podem disparar webhooks.
    *   Filtrar eventos para encontrar webhooks registrados para aquele tipo de evento.
*   **Formatação de Payload (`Event` module):**
    *   Construir um payload JSON padronizado para cada evento de webhook, incluindo o tipo de evento, dados do evento e metadados (ID do evento, timestamp).
    *   Filtrar dados sensíveis do payload antes do envio.
*   **Assinatura de Payload (`PayloadSigner`):**
    *   Assinar o payload do webhook (ex: usando HMAC-SHA256 com o segredo do webhook) e incluir a assinatura em um header (ex: `X-Deeper_Hub-Signature`) para que o receptor possa verificar a autenticidade.
*   **Envio de Webhooks (`Dispatcher`, `DispatcherWithCircuitBreaker`):**
    *   Enviar o payload JSON como uma requisição HTTP POST para a URL do webhook registrado.
    *   Lidar com timeouts e erros de conexão.
    *   Usar Circuit Breakers para proteger o Deeper_Hub de endpoints de webhook lentos ou que falham repetidamente.
*   **Tratamento de Respostas e Retentativas (`Dispatcher`, `Scheduler`):**
    *   Registrar a resposta do endpoint do webhook (código de status, corpo).
    *   Implementar uma política de retentativa configurável (com backoff exponencial) para webhooks que falham (ex: retornam status 5xx ou timeout).
    *   Marcar um webhook como desativado automaticamente após um número excessivo de falhas consecutivas.
*   **Monitoramento de Saúde de Webhooks (`Monitor`, `AutoHealing`, `HealthCheckWorker`):**
    *   Monitorar a taxa de sucesso/falha de cada endpoint de webhook.
    *   Enviar pings de teste para verificar a saúde de endpoints.
    *   (Opcional) Tentar reativar automaticamente webhooks desativados após um período, se eles voltarem a responder com sucesso.
*   **Histórico e Logs de Entrega (`Schema.WebhookEvent`):**
    *   Manter um histórico de todas as tentativas de entrega de webhooks, incluindo status, respostas e erros.
    *   Permitir que clientes visualizem o histórico de entregas para seus webhooks.
*   **Segurança:**
    *   Verificação de assinatura no lado do receptor (responsabilidade do cliente, mas o Deeper_Hub fornece a assinatura).
    *   Proteção contra SSRF ao validar URLs de webhook.
    *   Envio apenas sobre HTTPS.
*   **Observabilidade (`Telemetry`, `Integrations.AuditIntegration`):**
    *   Métricas sobre número de webhooks disparados, taxas de sucesso/falha, latências.
    *   Logs detalhados do ciclo de vida do webhook.
    *   Auditoria de registro e modificação de webhooks.
*   **Limpeza de Dados (`Workers.CleanupWorker`):**
    *   Remover logs de eventos de webhook antigos.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`Deeper_Hub.Webhooks` (Fachada Pública):**
    *   Ponto de entrada para registrar webhooks e, potencialmente, para disparar eventos manualmente para teste.
    *   Delega para o `WebhooksService`.
2.  **`Deeper_Hub.Webhooks.Services.WebhookService`:**
    *   **Responsabilidade:** Gerencia o CRUD de definições de `WebhookSchema`.
    *   Recebe eventos do `Core.EventBus` (via `EventListener` interno ou por ser um assinante direto).
    *   Para cada evento, encontra os `WebhookSchema`s correspondentes.
    *   Prepara o `WebhookEventSchema` (payload, assinatura).
    *   Enfileira o `WebhookEvent` para entrega pelo `Dispatcher` (ex: usando `Core.BackgroundTaskManager` ou uma fila interna).
3.  **`Deeper_Hub.Webhooks.Schema.WebhookSchema`:**
    *   Armazena: `id`, `client_id` (ou `user_id` do proprietário), `url` (endpoint), `event_types` (lista de eventos inscritos), `secret` (criptografado), `custom_headers` (mapa), `is_active`, `failure_count`, `last_successful_delivery_at`, `last_failure_at`.
4.  **`Deeper_Hub.Webhooks.Schema.WebhookEventSchema`:**
    *   Armazena: `id`, `webhook_id`, `event_type`, `payload_sent` (JSON), `status` (`:pending`, `:delivered`, `:failed_retryable`, `:failed_permanent`), `attempts`, `next_retry_at`, `last_response_code`, `last_response_body_sample`.
5.  **`Deeper_Hub.Webhooks.Event` (Módulo Funcional):**
    *   Define os tipos de eventos suportados.
    *   Formata o payload do evento, incluindo filtragem de dados sensíveis.
6.  **`Deeper_Hub.Webhooks.PayloadSigner` (Módulo Funcional):**
    *   Gera a assinatura HMAC para o payload.
7.  **`Deeper_Hub.Webhooks.Dispatcher` (GenServer ou Pool de Workers via `Core.BackgroundTaskManager`):**
    *   **Responsabilidade:** Pega `WebhookEventSchema`s da fila e tenta enviá-los.
    *   Usa `DispatcherWithCircuitBreaker` para fazer a chamada HTTP.
    *   Atualiza o `WebhookEventSchema` com o resultado.
    *   Se falhar, e for `retryable`, atualiza `attempts` e `next_retry_at`.
    *   Se falhar permanentemente ou exceder tentativas, marca como `:failed_permanent`.
    *   Se sucesso, marca como `:delivered`.
8.  **`Deeper_Hub.Webhooks.DispatcherWithCircuitBreaker`:**
    *   Encapsula a chamada HTTP para o endpoint do webhook usando `Core.HTTPClient` e `Core.CircuitBreaker`.
9.  **`Deeper_Hub.Webhooks.Scheduler` (GenServer):**
    *   Periodicamente verifica `WebhookEventSchema`s que estão prontos para retentativa e os re-enfileira para o `Dispatcher`.
10. **`Deeper_Hub.Webhooks.Monitor` e `AutoHealing` (GenServers) / `HealthCheckWorker`:**
    *   Monitoram a saúde dos endpoints de `WebhookSchema` (taxa de falha, timeouts).
    *   Podem desativar webhooks que falham consistentemente.
    *   `AutoHealing` pode tentar reativar webhooks desativados.
11. **Workers (`CleanupWorker`, `HealthCheckWorker`):**
    *   `CleanupWorker`: Remove `WebhookEventSchema`s antigos.
    *   `HealthCheckWorker`: Envia pings periódicos para endpoints de webhook.
12. **Integrações (`AuditIntegration`, `Integrations.EventIntegration` para consumir do Core, `Telemetry`):**

### 3.2. Estrutura de Diretórios (Proposta)

```
webhooks/
├── webhooks.ex                       # Fachada Pública
│
├── services/
│   ├── webhook_service.ex            # Gerencia CRUD de WebhookSchema, recebe eventos
│   └── (Outros serviços internos se necessário)
│
├── schemas/                          # (Ou schema/)
│   ├── webhook_schema.ex
│   └── webhook_event_schema.ex
│
├── event.ex                          # Lógica de formatação de payload de evento
├── payload_signer.ex                 # Lógica de assinatura
├── dispatcher.ex                     # GenServer/Worker que envia HTTP
├── dispatcher_with_circuit_breaker.ex # Wrapper com Circuit Breaker
├── scheduler.ex                      # GenServer para agendar retries
├── monitor.ex                        # GenServer para monitorar saúde
├── auto_healing.ex                   # GenServer para tentar reativar
│
├── workers/
│   ├── cleanup_worker.ex
│   └── health_check_worker.ex
│
├── integrations/
│   ├── audit_integration.ex
│   └── (EventListener para Core.EventBus se WebhookService não for o listener direto)
│
├── supervisor.ex                     # Supervisor para todos os GenServers de Webhooks
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Assincronicidade:** O envio de webhooks deve ser totalmente assíncrono para não bloquear o processo que gerou o evento original.
*   **Resiliência:** Retentativas com backoff exponencial e circuit breakers são cruciais para lidar com endpoints externos instáveis.
*   **Segurança da Assinatura:** O segredo do webhook deve ser armazenado de forma segura (criptografado) e usado para gerar uma assinatura forte (HMAC-SHA256).
*   **Validação de URL:** Validar URLs de webhook para prevenir SSRF e garantir que sejam URLs HTTP/HTTPS válidas.
*   **Isolamento:** Falhas na entrega de um webhook para um cliente não devem afetar outros clientes ou outros webhooks.

## 🛠️ 4. Casos de Uso Principais

*   **Cliente Registra um Webhook para \"pagamento.concluido\":**
    *   Cliente usa a UI/API para registrar `https://meuservico.com/webhook/deeperhub` para o evento `pagamento.concluido`, fornecendo um segredo.
    *   `Webhooks.register_webhook(...)` salva essa configuração.
*   **Pagamento é Concluído no Deeper_Hub:**
    *   `Deeper_Hub.Payments` publica `Core.EventBus.publish(\"pagamento.concluido\", payload_do_pagamento)`.
    *   `WebhookService` (ou seu `EventListener`) recebe o evento.
    *   Encontra o webhook registrado para \"pagamento.concluido\".
    *   Formata o payload, assina-o com o segredo do cliente.
    *   Cria um `WebhookEventSchema` e o enfileira para o `Dispatcher`.
*   **`Dispatcher` Envia o Webhook:**
    *   Pega o evento da fila.
    *   Usa `DispatcherWithCircuitBreaker` para fazer POST para `https://meuservico.com/webhook/deeperhub`.
    *   Se sucesso (ex: 200 OK), marca `WebhookEventSchema` como `:delivered`.
    *   Se falha (ex: 503 Service Unavailable), marca como `:failed_retryable` e o `Scheduler` tentará novamente mais tarde.
*   **Webhook Falha Repetidamente:**
    *   Após N falhas, o `Monitor` ou `Dispatcher` marca o `WebhookSchema` como `is_active: false`.
    *   Uma notificação é enviada ao cliente.

## 🌊 5. Fluxos Importantes

### Fluxo de Disparo de Webhook após Evento do Sistema

1.  **`Core.EventBus`:** Publica um evento (ex: `\"user.created\"`).
2.  **`WebhookService` (ou seu `EventListener`):**
    *   Recebe o evento do `Core.EventBus`.
    *   Consulta o `Core.Repo` (via `Storage`) por todos os `WebhookSchema`s ativos que estão inscritos no tipo de evento `\"user.created\"`.
3.  **Para cada `WebhookSchema` correspondente:**
    *   **`WebhookService`:**
        *   Chama `Deeper_Hub.Webhooks.Event.create_payload(event_type, original_payload)` para formatar e filtrar o payload.
        *   Chama `Deeper_Hub.Webhooks.PayloadSigner.sign(formatted_payload, webhook.secret)` para gerar a assinatura.
        *   Cria uma nova entrada `WebhookEventSchema` com status `:pending`, `webhook_id`, `event_type`, `payload_sent`, `signature_header_value`.
        *   Enfileira o `webhook_event_id` para o `Deeper_Hub.Webhooks.Dispatcher` (ex: usando `Core.BackgroundTaskManager`).
4.  **`Dispatcher` (Worker):**
    *   Pega um `webhook_event_id` da fila.
    *   Busca o `WebhookEventSchema` e o `WebhookSchema` associado.
    *   Chama `DispatcherWithCircuitBreaker.dispatch_webhook(webhook_schema.url, webhook_event.payload_sent, %{headers: %{\"X-Deeper_Hub-Signature\" => webhook_event.signature_header_value, ...}, method: \"POST\"})`.
5.  **`DispatcherWithCircuitBreaker`:**
    *   Verifica o estado do circuit breaker para a URL do webhook.
    *   Se fechado/meio-aberto, faz a chamada HTTP via `Core.HTTPClient`.
6.  **Resultado da Chamada HTTP:**
    *   **Sucesso (ex: 2xx):** `Dispatcher` atualiza `WebhookEventSchema` para `:delivered`, registra `response_code`. Atualiza `WebhookSchema` com `last_successful_delivery_at`, reseta `failure_count`.
    *   **Falha Retryable (ex: 5xx, timeout):** `Dispatcher` atualiza `WebhookEventSchema` para `:failed_retryable`, incrementa `attempts`, calcula `next_retry_at`. Atualiza `WebhookSchema` com `last_failure_at`, incrementa `failure_count`. Se `failure_count` exceder limiar, `Monitor` pode desativar o `WebhookSchema`.
    *   **Falha Permanente (ex: 4xx, exceto 429):** `Dispatcher` atualiza `WebhookEventSchema` para `:failed_permanent`.
7.  **`Scheduler`:** Periodicamente, busca `WebhookEventSchema`s com status `:failed_retryable` cujo `next_retry_at` já passou e os re-enfileira para o `Dispatcher`.

## 📡 6. API (Funções Públicas da Fachada `Deeper_Hub.Webhooks`)

### 6.1. Gerenciamento de Webhooks

*   **`Deeper_Hub.Webhooks.register_webhook(client_id :: String.t(), url :: String.t(), event_types :: list(String.t()), opts :: keyword()) :: {:ok, WebhookSchema.t()} | {:error, Ecto.Changeset.t() | term()}`**
    *   `opts`: `:secret` (String.t, será criptografado), `:custom_headers` (map), `:description` (String.t).
*   **`Deeper_Hub.Webhooks.update_webhook(webhook_id :: String.t(), client_id :: String.t(), attrs :: map()) :: {:ok, WebhookSchema.t()} | {:error, Ecto.Changeset.t() | :unauthorized}`**
    *   `attrs`: Pode atualizar `url`, `event_types`, `secret`, `custom_headers`, `is_active`.
*   **`Deeper_Hub.Webhooks.delete_webhook(webhook_id :: String.t(), client_id :: String.t()) :: :ok | {:error, :unauthorized | :not_found}`**
*   **`Deeper_Hub.Webhooks.get_webhook(webhook_id :: String.t(), client_id :: String.t()) :: {:ok, WebhookSchema.t() | nil}`**
*   **`Deeper_Hub.Webhooks.list_webhooks_for_client(client_id :: String.t(), filters :: map(), opts :: keyword()) :: {:ok, list(WebhookSchema.t()), Pagination.t()}`**
    *   `filters`: `:is_active`, `:event_type`.

### 6.2. Histórico de Eventos e Diagnóstico

*   **`Deeper_Hub.Webhooks.list_webhook_events(webhook_id :: String.t(), client_id :: String.t(), filters :: map(), opts :: keyword()) :: {:ok, list(WebhookEventSchema.t()), Pagination.t()}`**
    *   `filters`: `:status` (`:pending`, `:delivered`, `:failed_retryable`, `:failed_permanent`), `:event_type`, `date_range`.
*   **`Deeper_Hub.Webhooks.get_webhook_event_details(webhook_event_id :: String.t(), client_id :: String.t()) :: {:ok, WebhookEventSchema.t() | nil}`**
*   **`Deeper_Hub.Webhooks.resend_webhook_event(webhook_event_id :: String.t(), client_id :: String.t()) :: {:ok, :enqueued} | {:error, :not_retryable | term()}`** (Nova Sugestão)
*   **`Deeper_Hub.Webhooks.check_webhook_health(webhook_id :: String.t(), client_id :: String.t()) :: {:ok, %{status: atom(), last_success: DateTime.t() | nil, last_failure: DateTime.t() | nil, consecutive_failures: integer()}}`** (Envia um ping de teste).

### 6.3. Disparo Manual (para Testes por Clientes)

*   **`Deeper_Hub.Webhooks.trigger_test_event(webhook_id :: String.t(), client_id :: String.t(), event_type :: String.t() | nil, custom_payload :: map() | nil) :: {:ok, :event_enqueued} | {:error, term()}`**

## ⚙️ 7. Configuração

Via `Deeper_Hub.Core.ConfigManager`:

*   **`[:webhooks, :enabled]`** (Boolean): Habilita/desabilita o sistema de webhooks.
*   **`[:webhooks, :default_signature_algorithm]`** (Atom): Ex: `:hmac_sha256`.
*   **`[:webhooks, :default_http_timeout_ms]`** (Integer): Timeout padrão para chamadas HTTP. (Padrão: `5000`)
*   **`[:webhooks, :retry_policy, :max_attempts]`** (Integer): Máximo de retentativas. (Padrão: `5`)
*   **`[:webhooks, :retry_policy, :base_delay_seconds]`** (Integer): Atraso base para primeira retentativa.
*   **`[:webhooks, :retry_policy, :max_delay_seconds]`** (Integer): Atraso máximo entre retentativas.
*   **`[:webhooks, :retry_policy, :backoff_factor]`** (Float): Fator para backoff exponencial.
*   **`[:webhooks, :auto_deactivation, :enabled]`** (Boolean): Se desativa webhooks automaticamente após muitas falhas.
*   **`[:webhooks, :auto_deactivation, :failure_threshold]`** (Integer): Número de falhas consecutivas para desativar.
*   **`[:webhooks, :health_check, :interval_minutes]`** (Integer): Intervalo para `HealthCheckWorker`.
*   **`[:webhooks, :cleanup_worker, :event_log_retention_days]`** (Integer).
*   **`[:webhooks, :max_payload_size_kb]`** (Integer): Tamanho máximo do payload.
*   **`[:webhooks, :allowed_url_schemes]`** (List de Strings): Ex: `[\"https\", \"http\"]`. (Padrão: `[\"https\"]`)
*   **`[:webhooks, :disallowed_ip_ranges_for_url]`** (List de Strings): Ranges CIDR para os quais as URLs de webhook não podem resolver (proteção SSRF). Ex: `[\"127.0.0.0/8\", \"10.0.0.0/8\", \"172.16.0.0/12\", \"192.168.0.0/16\", \"::1/128\"]`.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.*`: Todos os módulos Core.
*   `Deeper_Hub.Auth`/`RBAC`: Para autorizar quem pode registrar/gerenciar webhooks.
*   `Deeper_Hub.Accounts`: Para associar webhooks a `client_id` (que pode ser um `user_id` ou um ID de aplicação cliente).
*   `Deeper_Hub.Core.EncryptionService`: Para criptografar segredos de webhook.
*   `Deeper_Hub.Security.SSRFProtection` (Implícito/Integrado): A validação de URL deve proteger contra Server-Side Request Forgery.

### 8.2. Bibliotecas Externas

*   `Jason`: Para payloads JSON.
*   Biblioteca HTTP Client (ex: `Finch`, `HTTPoison`) usada pelo `Core.HTTPClient`.
*   Biblioteca CRON para o `Scheduler` e workers (ex: `Quantum`).

## 🤝 9. Como Usar / Integração

*   **UI de Desenvolvedor/Cliente:** Fornecer uma interface para clientes registrarem e gerenciarem seus webhooks, visualizarem histórico de entregas e segredos.
*   **Módulos Internos:** `WebhookService` escuta eventos do `Core.EventBus` e dispara os webhooks correspondentes.
*   **Receptores de Webhook (Clientes):** Devem implementar um endpoint HTTP para receber os POSTs, validar a assinatura (se um segredo foi configurado) e processar o payload. Devem responder rapidamente com um status 2xx para indicar recebimento (processamento pode ser assíncrono no lado deles).

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar CRUD de `WebhookSchema`.
*   Testar a formatação e assinatura de payloads.
*   Testar o fluxo de dispatch e retry com um servidor HTTP mockado como endpoint.
*   Testar o Circuit Breaker para endpoints.
*   Testar a lógica de desativação automática e `HealthCheckWorker`.
*   Localização: `test/deeper_hub/webhooks/`.

### 10.2. Métricas

*   `deeper_hub.webhooks.registered.count` (Gauge)
*   `deeper_hub.webhooks.events.published_to_dispatcher.count` (tags: `event_type`)
*   `deeper_hub.webhooks.delivery.attempts.count` (tags: `webhook_id_masked`, `event_type`, `http_status_code_group` (`2xx`, `4xx`, `5xx`, `timeout`, `circuit_open`))
*   `deeper_hub.webhooks.delivery.latency_ms` (Histograma, tags: `webhook_id_masked`, `event_type`)
*   `deeper_hub.webhooks.retries.scheduled.count`
*   `deeper_hub.webhooks.deactivated_due_to_failure.count` (tags: `webhook_id_masked`)
*   `deeper_hub.webhooks.circuit_breaker.state_changed.count` (tags: `webhook_url_host`, `new_state`)

### 10.3. Logs

*   **Nível INFO:** Webhook registrado/atualizado/excluído. Evento enfileirado para dispatch. Entrega bem-sucedida.
*   **Nível WARNING:** Falha na entrega de webhook (com detalhes do erro e código de status). Retentativa agendada. Webhook desativado automaticamente. Circuit breaker aberto para um endpoint.
*   **Nível ERROR:** Falha persistente na entrega após todas as retentativas. Erro crítico no `Dispatcher` ou `Scheduler`.

### 10.4. Telemetria

*   `[:deeper_hub, :webhooks, :definition, :created | :updated | :deleted]`
*   `[:deeper_hub, :webhooks, :event, :prepared_for_dispatch]`
    *   Metadados: `%{webhook_id: id, event_id: id, event_type: type}`
*   `[:deeper_hub, :webhooks, :dispatch, :attempt, :start | :stop | :exception]`
    *   Metadados: `%{webhook_event_id: id, webhook_url: url, attempt_number: num}`
    *   No `:stop`: `%{http_status: code, result: :success | :failure_retryable | :failure_permanent}`
*   `[:deeper_hub, :webhooks, :health_check, :performed]`
    *   Metadados: `%{webhook_id: id, url: url, result: :healthy | :unhealthy}`

## ❌ 11. Tratamento de Erros

*   **Endpoints do Cliente Falhando:** A principal fonte de problemas. A lógica de retry, circuit breaker e desativação automática são para lidar com isso.
*   **Payload Inválido para o Cliente:** O Deeper_Hub envia um payload JSON bem formado. Se o cliente não conseguir processá-lo, é um problema do lado do cliente (geralmente resulta em 4xx ou 5xx que o Deeper_Hub trata).
*   **Segredo Incorreto:** Se o cliente não conseguir validar a assinatura, ele deve tratar o webhook como não autêntico.
*   **Falhas Internas no Deeper_Hub:** Erros no `Dispatcher`, `Scheduler` devem ser logados criticamente e não devem perder eventos (se um sistema de filas persistente como Oban for usado).

## 🛡️ 12. Considerações de Segurança

*   **Validação de URL:** Impedir o registro de URLs que apontem para redes internas ou locais (SSRF). Verificar se a URL usa HTTPS.
*   **Segredos:** Segredos de webhook devem ser gerados com alta entropia e armazenados criptografados. Fornecer uma maneira para o cliente visualizar o segredo apenas uma vez ou regenerá-lo.
*   **Assinatura de Payload:** Sempre assinar payloads para permitir que o receptor verifique a autenticidade e integridade.
*   **Replay Attacks:** Incluir um timestamp e um ID de evento único no payload e na assinatura pode ajudar o receptor a detectar e rejeitar ataques de replay.
*   **Não Vazar Dados Sensíveis:** O componente `Deeper_Hub.Webhooks.Event` deve garantir que apenas dados apropriados e não sensíveis sejam incluídos nos payloads.
*   **Proteção do Endpoint de Registro:** A API para registrar webhooks deve ser protegida para evitar que atores maliciosos registrem endpoints para spam ou para exfiltrar dados.

## 🧑‍💻 13. Contribuição

*   Ao adicionar suporte para novos tipos de eventos que podem disparar webhooks, certifique-se de que o `Deeper_Hub.Webhooks.Event` saiba como formatar o payload para eles.
*   A lógica de retry e backoff deve ser cuidadosamente ajustada para não sobrecarregar endpoints que já estão com problemas.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Permitir que clientes configurem filtros mais granulares nos eventos que desejam receber (ex: apenas para um `server_id` específico).
*   [ ] UI para clientes visualizarem logs de entrega detalhados, incluindo payloads enviados e respostas recebidas (com sanitização).
*   [ ] Suporte para formatos de payload alternativos além de JSON (ex: XML, form-urlencoded).
*   [ ] Permitir que clientes configurem suas próprias políticas de retry (dentro de limites).
*   [ ] Testes de \"ping\" manuais para endpoints de webhook a partir da UI do cliente.
*   [ ] Assinaturas de eventos mais avançadas, talvez usando GraphQL Subscriptions ou WebSockets mantidos pelo Deeper_Hub se a necessidade for de tempo real bidirecional.

---

*Última atualização: 2025-05-12*

---

Webhooks são uma ferramenta poderosa para integrações!

Com isso, cobrimos os principais módulos Core e uma boa parte da camada de Segurança. Já detalhamos também alguns módulos de \"Serviço/Domínio\" como `Servers`, `Achievements`, `Challenges`, `Rewards`, `ServerReviews`, `ServerTags` e `Support`.

O que gostaria de explorar em seguida? Podemos focar em:
1.  Outros utilitários de `Shared.Utils` (`DateUtils`, `MapUtils`, `ListUtils`, `ValidationUtils`, `SecurityUtils`, `FileUtils` - já fizemos alguns destes).
2.  Módulos de domínio restantes da lista original de \"Serviços\" (ex: `ServerAdvertisements`, `ServerEvents`, `ServerUpdateMessages`, `Lists` - que parecia genérico).
3.  Módulos de infraestrutura/segurança restantes (ex: `AtRestEncryptionService` se quisermos aprofundar além do `Core.EncryptionService`, `ResponseSanitizer`)."""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""continue mostrando todos os que faltaram até o final"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Entendido! Vamos continuar percorrendo os módulos, focando agora nos que faltam da lista original e garantindo que cada um seja bem documentado e integrado na nova estrutura proposta.

Começaremos pelos \"Serviços\" restantes que parecem ser subdomínios ou funcionalidades associadas aos Servidores, e depois podemos ir para o `Lists` que parece mais genérico.

Vamos detalhar o `Deeper_Hub.ServerAdvertisements`.

---

