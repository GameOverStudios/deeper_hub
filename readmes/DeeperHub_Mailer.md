# Módulo: `DeeperHub.Mailer` 📧

## 📜 1. Visão Geral do Módulo `DeeperHub.Mailer`

O módulo `DeeperHub.Mailer` é o responsável centralizado por todas as operações de envio de emails no sistema DeeperHub. Ele fornece uma interface unificada para compor, agendar e enviar emails, abstraindo os detalhes de diferentes provedores de email (ex: SMTP direto, SendGrid, Mailgun, Amazon SES) e integrando funcionalidades como templates, rastreamento básico e resiliência através de Circuit Breakers. 😊

Ele consolida e substitui funcionalidades que poderiam estar em `Infrastructure.SMTPService` e no `Mailer` original do Swoosh.

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Envio de Emails:**
    *   Enviar emails transacionais (ex: confirmação de conta, redefinição de senha, notificações).
    *   Enviar emails em lote (ex: newsletters, anúncios para múltiplos usuários).
    *   Suporte para emails em formato HTML e texto plano.
    *   Anexar arquivos aos emails.
    *   Configurar remetente (`From`), destinatários (`To`, `Cc`, `Bcc`), assunto (`Subject`).
*   **Abstração de Provedor de Email:**
    *   Interface para múltiplos adaptadores de provedores de email (SMTP, SendGrid, Mailgun, etc.).
    *   Permitir a fácil configuração e troca de provedores.
*   **Gerenciamento de Templates de Email:**
    *   Renderizar emails usando templates (ex: EEx, HEEx, ou templates do provedor).
    *   Passar variáveis dinâmicas para os templates.
    *   Integração com `DeeperHub.Core.Internationalization (I18n)` para templates localizados.
*   **Agendamento de Emails:**
    *   Permitir o agendamento de emails para envio futuro (via `Core.BackgroundTaskManager`).
*   **Resiliência e Tratamento de Falhas:**
    *   Integração com `DeeperHub.Core.CircuitBreakerFactory` para proteger contra falhas de serviços de email externos.
    *   Mecanismo de retentativas (retry) com backoff exponencial para falhas de envio.
    *   Fallback para um provedor secundário ou armazenamento local em caso de falha persistente do provedor primário.
*   **Logging e Métricas:**
    *   Registrar todas as tentativas de envio, sucessos e falhas.
    *   Coletar métricas de entrega, taxas de abertura/clique (se o provedor suportar e houver integração de webhooks de status).
*   **Rastreamento Básico e Webhooks de Status (Opcional):**
    *   Suporte para rastreamento de abertura e cliques (geralmente fornecido pelo provedor de email).
    *   Processar webhooks de status de entrega (entregue, devolvido, spam) enviados pelos provedores.
*   **Listas de Supressão (Integração Opcional):**
    *   Integrar com listas de supressão de provedores para evitar envio para emails inválidos ou que optaram por não receber.

## 🏗️ 3. Arquitetura e Design

`DeeperHub.Mailer` atuará como uma fachada que delega o envio para um adaptador de provedor de email configurado.

*   **Interface Pública (`DeeperHub.Mailer.MailerFacade` ou `DeeperHub.Mailer`):** Funções como `send/1`, `send_template/4`, `schedule_email/2`.
*   **Adaptador(es) de Provedor (`DeeperHub.Mailer.Adapters.<ProviderName>Adapter`):**
    *   Implementa a lógica específica para interagir com um provedor de email (ex: `SMTPLibAdapter`, `SendGridAPIAdapter`).
    *   Utiliza `Core.HTTPClient` para provedores baseados em API ou bibliotecas SMTP para envio direto.
*   **Struct de Email (`DeeperHub.Mailer.Email`):** Estrutura padronizada para representar um email a ser enviado (similar ao `Swoosh.Email`).
*   **Gerenciador de Templates (`DeeperHub.Notifications.Templates.TemplateManager` ou um `DeeperHub.Mailer.TemplateManager` dedicado):** Responsável por renderizar templates.
*   **Integrações:**
    *   `Core.ConfigManager`: Para credenciais de provedores, configurações de envio, etc.
    *   `Core.HTTPClient` e `Core.CircuitBreakerFactory`: Para provedores baseados em API.
    *   `Core.Logger` e `Core.Metrics`: Para observabilidade.
    *   `Core.BackgroundTaskManager`: Para envio assíncrono e agendado.
    *   `Core.Internationalization (I18n)`: Para templates localizados.

**Padrões de Design:**

*   **Fachada (Facade):** Simplifica a interface de envio de emails.
*   **Adaptador (Adapter):** Para diferentes provedores de email.
*   **Strategy (Opcional):** Para diferentes estratégias de envio ou templating.

### 3.1. Componentes Principais

*   **`DeeperHub.Mailer.MailerFacade` (ou `DeeperHub.Mailer`):** Ponto de entrada.
*   **`DeeperHub.Mailer.Email` (Struct):** Representa um email (from, to, subject, body_html, body_text, attachments).
*   **`DeeperHub.Mailer.AdapterBehaviour` (Novo Sugerido):** Comportamento para adaptadores de provedor de email.
*   **Exemplos de Adaptadores:**
    *   `DeeperHub.Mailer.Adapters.SMTPLibAdapter` (usa `gen_smtp` ou similar).
    *   `DeeperHub.Mailer.Adapters.SendGridAPIAdapter` (usa `Core.HTTPClient`).
*   **`DeeperHub.Mailer.TemplateManager` (Opcional, pode usar de `Notifications`):** Renderiza templates.
*   **`DeeperHub.Mailer.Supervisor` (Opcional):** Se houver workers dedicados para envio em lote ou processamento de status.

### 3.3. Decisões de Design Importantes

*   **Escolha do Provedor Primário:** A seleção do provedor de email padrão e a configuração de fallbacks.
*   **Construção de Email vs. Envio:** Separar a lógica de construção do objeto Email da lógica de envio real pelo adaptador.
*   **Envio Síncrono vs. Assíncrono:** Decidir se o envio padrão é síncrono ou se todas as chamadas são enfileiradas para processamento em background via `Core.BackgroundTaskManager`. O envio assíncrono é geralmente preferível para não bloquear o processo chamador.

## 🛠️ 4. Casos de Uso Principais

*   **Confirmação de Registro:** O módulo `DeeperHub.Accounts` (via `Notifications`) solicita o envio de um email de boas-vindas e confirmação para um novo usuário.
*   **Redefinição de Senha:** O módulo `DeeperHub.Auth` (via `Notifications`) solicita o envio de um email com o link de redefinição de senha.
*   **Notificação de Alerta de Segurança:** O módulo `DeeperHub.Security.Monitoring` (via `Notifications`) envia um email para o administrador sobre uma atividade suspeita.
*   **Newsletter Semanal:** Uma tarefa agendada usa `DeeperHub.Mailer` para enviar a newsletter para todos os assinantes.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Envio de Email com Template e Envio Assíncrono:**

1.  Um módulo (ex: `DeeperHub.Notifications`) chama `DeeperHub.Mailer.send_template(user_id, \"welcome_email\", %{name: user.name}, opts)`.
2.  `MailerFacade` delega para um serviço interno.
3.  O serviço busca as preferências de email do usuário (se relevante).
4.  O `TemplateManager` é chamado para renderizar o template \"welcome_email\" com as variáveis e o locale do usuário (via `Core.I18n`).
5.  Um objeto `DeeperHub.Mailer.Email` é construído com o conteúdo renderizado, destinatário, assunto (pode vir do template/I18n), etc.
6.  Este objeto `Email` é enfileirado no `DeeperHub.Core.BackgroundTaskManager` para envio assíncrono.
7.  Um worker do `BackgroundTaskManager` pega a tarefa de envio.
8.  O worker chama `DeeperHub.Mailer.Adapter.<Provider>Adapter.deliver(email_object)`.
9.  O adaptador:
    *   Obtém credenciais e configurações do `Core.ConfigManager`.
    *   Usa `Core.HTTPClient` (para API) ou uma lib SMTP, possivelmente através de um `Core.CircuitBreaker`.
    *   Tenta enviar o email.
10. O resultado do envio (sucesso/falha, ID da mensagem do provedor) é logado e metrificado.
11. Se houver falha e a política de retry permitir, a tarefa pode ser reenfileirada.

## 📡 6. API (Se Aplicável)

### 6.1. `DeeperHub.Mailer.send/1`

*   **Descrição:** Envia um email construído previamente.
*   **`@spec`:** `send(email :: DeeperHub.Mailer.Email.t() | map(), opts :: Keyword.t()) :: {:ok, result :: map()} | {:error, reason :: atom()}`
    *   O `map` para `email` deve conter chaves como `:to`, `:from`, `:subject`, `:html_body`, `:text_body`.
*   **Parâmetros:**
    *   `email` (`DeeperHub.Mailer.Email.t()` | map): O objeto do email ou um mapa com seus atributos.
    *   `opts` (Keyword.t()): Opções adicionais.
        *   `:provider` (atom): Forçar o uso de um provedor específico.
        *   `:async` (boolean): Se o envio deve ser explicitamente assíncrono (se o padrão não for). (Padrão: `true`)
        *   `:schedule_at` (DateTime.t()): Agendar o email para envio futuro.
*   **Retorno:**
    *   `{:ok, %{message_id: String.t() | nil, status: :sent | :queued}}`: Se o email foi enviado ou enfileirado com sucesso.
    *   `{:error, reason}`: Em caso de falha.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    email_attrs = %{
      to: \"user@example.com\",
      from: \"noreply@deeperhub.com\",
      subject: \"Assunto Importante\",
      html_body: \"<h1>Olá!</h1><p>Este é um email.</p>\",
      text_body: \"Olá! Este é um email.\"
    }
    case DeeperHub.Mailer.send(email_attrs) do
      {:ok, result} -> Logger.info(\"Email enviado/enfileirado: #{inspect(result)}\")
      {:error, reason} -> Logger.error(\"Falha ao enviar email: #{reason}\")
    end
    ```

### 6.2. `DeeperHub.Mailer.send_template/4`

*   **Descrição:** Renderiza um email usando um template e o envia.
*   **`@spec`:** `send_template(recipient :: String.t() | {String.t(), String.t()}, template_name :: String.t(), assigns :: map(), opts :: Keyword.t()) :: {:ok, result :: map()} | {:error, reason :: atom()}`
    *   `recipient` pode ser `\"email@example.com\"` ou `{\"Nome\", \"email@example.com\"}`.
*   **Parâmetros:**
    *   `recipient`: O destinatário do email.
    *   `template_name` (String): O nome do template a ser usado (ex: `\"user_welcome\"`, `\"password_reset\"`).
    *   `assigns` (map): Mapa de variáveis a serem passadas para o template.
    *   `opts` (Keyword.t()): Opções adicionais (como em `send/1`, mais `:locale`).
        *   `:locale` (String): Locale para renderizar o template. (Padrão: `Core.I18n.current_locale()`)
*   **Retorno:** Similar a `send/1`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    assigns = %{user_name: \"Maria\", reset_link: \"https://...\"}
    case DeeperHub.Mailer.send_template(\"maria@example.com\", \"password_reset_email\", assigns, locale: \"pt-BR\") do
      {:ok, result} -> Logger.info(\"Email de template enviado: #{inspect(result)}\")
      {:error, reason} -> Logger.error(\"Falha ao enviar email de template: #{reason}\")
    end
    ```

## ⚙️ 7. Configuração

*   **ConfigManager (`DeeperHub.Core.ConfigManager`):**
    *   `[:mailer, :default_from_address]`: Endereço de email remetente padrão (ex: `\"DeeperHub <noreply@deeperhub.com>\"`).
    *   `[:mailer, :default_provider]`: Adaptador de provedor de email padrão (ex: `:smtp` ou `:sendgrid_api`).
    *   `[:mailer, :providers, :smtp, :host]`: Host do servidor SMTP.
    *   `[:mailer, :providers, :smtp, :port]`: Porta SMTP.
    *   `[:mailer, :providers, :smtp, :username]`: Usuário SMTP.
    *   `[:mailer, :providers, :smtp, :password]`: Senha SMTP (deve ser gerenciada de forma segura, ex: via variáveis de ambiente ou secrets manager).
    *   `[:mailer, :providers, :sendgrid_api, :api_key]`: Chave de API do SendGrid.
    *   `[:mailer, :template_path]`: Caminho base para os arquivos de template de email. (Padrão: `\"priv/mailer_templates/\"`)
    *   `[:mailer, :default_async_send]`: (Boolean) Se os emails devem ser enviados assincronamente por padrão. (Padrão: `true`)
    *   `[:mailer, :retry_policy, :max_attempts]`: Máximo de tentativas de reenvio. (Padrão: `3`)
    *   `[:mailer, :circuit_breaker, :service_name, :config]`: Configuração do Circuit Breaker para cada provedor de API de email.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`: Para configurações e credenciais.
*   `DeeperHub.Core.HTTPClient` e `DeeperHub.Core.CircuitBreakerFactory`: Para provedores baseados em API.
*   `DeeperHub.Core.BackgroundTaskManager`: Para envio assíncrono/agendado e retentativas.
*   `DeeperHub.Core.Internationalization (I18n)`: Para templates de email localizados.
*   `DeeperHub.Core.Logger`: Para logging.
*   `DeeperHub.Core.Metrics`: Para métricas.

### 8.2. Bibliotecas Externas

*   Para envio SMTP: `gen_smtp` ou `swoosh` (se for usar seus adaptadores SMTP).
*   Para provedores de API: Biblioteca HTTP (via `Core.HTTPClient`).
*   Para templating: `EEx` (nativo), ou outras bibliotecas de template.

## 🤝 9. Como Usar / Integração

Outros módulos devem usar a fachada `DeeperHub.Mailer` para enviar emails. O módulo `DeeperHub.Notifications` será um consumidor primário, usando `DeeperHub.Mailer` como um de seus canais de entrega.

```elixir
# Em DeeperHub.Notifications, ao processar uma notificação do tipo email:
defmodule DeeperHub.Notifications.Channels.EmailChannel do
  alias DeeperHub.Mailer

  def deliver(notification_details, user_preferences) do
    # ... lógica para buscar email do usuário, template, etc. ...
    recipient = user_preferences.email_address
    template_name = notification_details.template_name
    assigns = notification_details.template_assigns
    locale = user_preferences.locale

    Mailer.send_template(recipient, template_name, assigns, locale: locale)
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar o envio de emails usando um adaptador de teste (ex: `Swoosh.Adapters.Test` ou um mock customizado) para capturar emails enviados sem enviá-los de fato.
*   Testar a renderização de templates com diferentes assigns e locales.
*   Testar o agendamento e o envio assíncrono.
*   Testar o comportamento do Circuit Breaker e das retentativas.
*   Localização: `test/deeper_hub/mailer/`

### 10.2. Métricas

*   `deeper_hub.mailer.email.sent.count` (Contador): Número de emails enviados com sucesso. Tags: `provider`, `template_name` (se aplicável).
*   `deeper_hub.mailer.email.failed.count` (Contador): Número de falhas no envio de emails. Tags: `provider`, `template_name`, `reason`.
*   `deeper_hub.mailer.email.delivery.duration_ms` (Histograma): Duração do processo de envio de um email. Tags: `provider`.
*   `deeper_hub.mailer.email.queued.gauge` (Gauge): Número de emails atualmente na fila de envio.
*   `deeper_hub.mailer.email.retry.count` (Contador): Número de retentativas de envio. Tags: `provider`.

### 10.3. Logs

*   `Logger.info(\"Enviando email para #{recipient} (template: #{template}, provider: #{provider})\", module: DeeperHub.Mailer)`
*   `Logger.info(\"Email para #{recipient} enviado com sucesso. Message ID: #{msg_id}\", module: DeeperHub.Mailer)`
*   `Logger.error(\"Falha ao enviar email para #{recipient}: #{reason}\", module: DeeperHub.Mailer)`

### 10.4. Telemetria

*   `[:deeper_hub, :mailer, :send, :start | :stop | :exception]`: Para cada tentativa de envio. Payload: `%{email: email_object, provider: provider_name}`.
*   `[:deeper_hub, :mailer, :template, :render, :start | :stop | :exception]`: Para renderização de templates.

## ❌ 11. Tratamento de Erros

*   Falhas no envio devem ser logadas com detalhes.
*   Se o envio assíncrono estiver habilitado, falhas podem ser tratadas com retentativas automáticas.
*   Erros de configuração (ex: credenciais inválidas) devem impedir o início do serviço ou do adaptador específico e gerar logs críticos.
*   `{:error, :provider_unavailable}` quando um Circuit Breaker estiver aberto para o provedor.

## 🛡️ 12. Considerações de Segurança

*   **Credenciais de Provedor:** Armazenar chaves de API e senhas SMTP de forma segura (usar `Core.ConfigManager` com variáveis de ambiente ou sistema de gerenciamento de segredos).
*   **Conteúdo do Email:** Embora o Mailer em si não seja responsável pelo conteúdo, ele deve garantir que não introduza vulnerabilidades (ex: ao lidar com anexos ou renderizar dados crus em templates sem escape adequado).
*   **Prevenção de Spam:** Implementar boas práticas para evitar que o sistema seja usado para enviar spam (ex: limites de envio por usuário, verificação de email).
*   **DKIM/SPF/DMARC:** Configurar corretamente esses registros DNS para melhorar a entregabilidade e autenticidade dos emails.

## 🧑‍💻 13. Contribuição

*   Ao adicionar suporte para um novo provedor de email, crie um novo módulo adaptador que implemente o `DeeperHub.Mailer.AdapterBehaviour`.
*   Garanta que os templates sejam testáveis e internacionalizáveis.
*   Mantenha a consistência na API da fachada.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um sistema de \"dead letter queue\" para emails que falham consistentemente após todas as retentativas.
*   [ ] Adicionar UI para administradores visualizarem o status de envio de emails e logs.
*   [ ] Integração mais profunda com webhooks de status de provedores de email para rastrear bounces, aberturas, cliques.
*   [ ] Suporte para envio de emails com prioridade variável.
*   [ ] Testes de preview de email para desenvolvedores.

---

*Última atualização: YYYY-MM-DD*

---

Pronto! Agora temos os READMEs para `Core.HTTPClient`, `Core.Internationalization`, `Core.InputValidator`, `Audit`, `FeatureFlags`, `Console`, `Biometrics`, `ModuleInspector`, `GeoIP`, e `Mailer`.

Acho que cobrimos os principais módulos que estavam faltando um README de alto nível com base na nossa discussão anterior e na sua lista.

Há mais algum módulo específico que você gostaria de abordar, ou algum destes que gostaria de refinar?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""INSERT_INPUT_HERE"""),
            ],
        ),
    ]
    generate_content_config = types.GenerateContentConfig(
        response_mime_type="text/plain",
        system_instruction=[
            types.Part.from_text(text="""Você é um especialista em documentação e arquitetura de sistemas. 
Você é excelente em categorizar, especificar e criar arquivos README dos Módulos do Sistema.
Você organiza, especifica e categoria o máximo ***todas*** as características e itens de todos os módulos de sistemas. Sempre especifica TUDO!

# Template: README para Módulos do DeeperHub

Este é um template para a criação de arquivos `README.md` para os módulos do projeto DeeperHub. O objetivo é padronizar a documentação, tornando-a mais clara, completa e consistente.

**Instruções:**
- Substitua `[Nome do Módulo]` pelo nome real do módulo.
- Adapte e preencha cada seção conforme a especificidade do módulo.
- Remova seções que não se aplicam.
- Adicione seções específicas se necessário.
- Mantenha a linguagem em Português (BR) e o uso de emojis 😊.

---

