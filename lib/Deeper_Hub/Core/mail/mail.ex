defmodule DeeperHub.Core.Mail do
  @moduledoc """
  Módulo principal para gerenciamento de emails no DeeperHub.

  Este módulo fornece funções para criação, renderização e envio de emails,
  integrando-se com outros subsistemas como alertas de segurança e notificações.
  """

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Mail.Sender
  alias DeeperHub.Core.Mail.Templates
  alias DeeperHub.Core.Mail.Queue

  @doc """
  Envia um email usando as configurações padrão.

  ## Parâmetros

  - `to` - Endereço de email do destinatário ou lista de destinatários
  - `subject` - Assunto do email
  - `template` - Nome do template a ser utilizado
  - `assigns` - Variáveis para renderização do template
  - `options` - Opções adicionais para o envio
    - `:use_queue` - Se `true`, usa a fila para envio (padrão: `false`)
    - `:priority` - Prioridade na fila (`:high`, `:normal`, `:low`)
    - `:async` - Se `true`, envia de forma assíncrona (padrão: `false`)

  ## Exemplo

  ```elixir
  DeeperHub.Core.Mail.send_email(
    "usuario@exemplo.com",
    "Alerta de Segurança",
    :security_alert,
    %{alert_type: "Tentativa de login falha", details: "..."}
  )
  ```

  ## Retorno

  - `{:ok, message_id}` em caso de sucesso
  - `{:ok, queue_id}` em caso de sucesso ao adicionar à fila
  - `{:error, reason}` em caso de falha
  """
  def send_email(to, subject, template, assigns \\ %{}, options \\ []) do
    # Obtém o conteúdo HTML e texto do template
    {html_body, text_body} = Templates.render(template, assigns)

    # Cria a mensagem de email
    email =
      Mail.build()
      |> Mail.put_from(get_sender_email())
      |> put_recipients(to)
      |> Mail.put_subject(subject)
      |> Mail.put_html(html_body)
      |> Mail.put_text(text_body)

    # Verifica as opções de envio
    use_queue = Keyword.get(options, :use_queue, false)
    async = Keyword.get(options, :async, false)
    priority = Keyword.get(options, :priority, :normal)

    cond do
      # Usa a fila de emails
      use_queue ->
        Logger.info("Adicionando email à fila", 
          module: __MODULE__,
          to: to,
          subject: subject,
          template: template,
          priority: priority
        )
        Queue.enqueue(email, priority)

      # Envio assíncrono
      async ->
        Logger.info("Enviando email de forma assíncrona", 
          module: __MODULE__,
          to: to,
          subject: subject,
          template: template
        )
        Sender.deliver_async(email)

      # Envio síncrono padrão
      true ->
        Logger.info("Enviando email", 
          module: __MODULE__,
          to: to,
          subject: subject,
          template: template
        )
        Sender.deliver(email)
    end
  end

  @doc """
  Envia um email de alerta de segurança.

  ## Parâmetros

  - `to` - Endereço de email do destinatário ou lista de destinatários
  - `alert_type` - Tipo de alerta
  - `alert_message` - Mensagem do alerta
  - `alert_details` - Detalhes adicionais do alerta
  - `severity` - Severidade do alerta (:info, :warning, :critical)
  - `options` - Opções adicionais para o envio
    - `:use_queue` - Se `true`, usa a fila para envio (padrão: `true` para alertas)
    - `:priority` - Prioridade na fila (padrão baseado na severidade)
    - `:async` - Se `true`, envia de forma assíncrona (padrão: `false`)

  ## Retorno

  - `{:ok, message_id}` em caso de sucesso
  - `{:ok, queue_id}` em caso de sucesso ao adicionar à fila
  - `{:error, reason}` em caso de falha
  """
  def send_security_alert(to, alert_type, alert_message, alert_details \\ %{}, severity \\ :warning, options \\ []) do
    # Prepara o assunto com base na severidade
    subject = get_alert_subject(severity, alert_type)

    # Prepara os dados para o template
    assigns = %{
      alert_type: alert_type,
      alert_message: alert_message,
      alert_details: alert_details,
      severity: severity,
      timestamp: DateTime.utc_now()
    }

    # Define a prioridade com base na severidade
    priority = case severity do
      :critical -> :high
      :warning -> :normal
      :info -> :low
      _ -> :normal
    end

    # Define as opções padrão para alertas de segurança
    default_options = [
      use_queue: true,
      priority: priority
    ]

    # Mescla as opções fornecidas com as padrões
    merged_options = Keyword.merge(default_options, options)

    # Envia o email usando o template de alerta de segurança
    send_email(to, subject, :security_alert, assigns, merged_options)
  end

  @doc """
  Envia um email de boas-vindas para um novo usuário.

  ## Parâmetros

  - `to` - Endereço de email do destinatário
  - `username` - Nome de usuário
  - `verification_url` - URL para verificação de email (opcional)
  - `options` - Opções adicionais para o envio
    - `:use_queue` - Se `true`, usa a fila para envio (padrão: `true`)
    - `:priority` - Prioridade na fila (padrão: `:normal`)
    - `:async` - Se `true`, envia de forma assíncrona (padrão: `false`)

  ## Retorno

  - `{:ok, message_id}` em caso de sucesso
  - `{:ok, queue_id}` em caso de sucesso ao adicionar à fila
  - `{:error, reason}` em caso de falha
  """
  def send_welcome_email(to, username, verification_url \\ nil, options \\ []) do
    subject = "Bem-vindo ao DeeperHub!"

    assigns = %{
      username: username,
      verification_url: verification_url,
      current_year: DateTime.utc_now().year
    }

    # Define as opções padrão para emails de boas-vindas
    default_options = [
      use_queue: true,
      priority: :normal
    ]

    # Mescla as opções fornecidas com as padrões
    merged_options = Keyword.merge(default_options, options)

    send_email(to, subject, :welcome, assigns, merged_options)
  end

  @doc """
  Envia um email de redefinição de senha.

  ## Parâmetros

  - `to` - Endereço de email do destinatário
  - `username` - Nome de usuário
  - `reset_url` - URL para redefinição de senha
  - `expiration_hours` - Tempo de expiração do link em horas
  - `options` - Opções adicionais para o envio
    - `:use_queue` - Se `true`, usa a fila para envio (padrão: `true`)
    - `:priority` - Prioridade na fila (padrão: `:high`)
    - `:async` - Se `true`, envia de forma assíncrona (padrão: `false`)

  ## Retorno

  - `{:ok, message_id}` em caso de sucesso
  - `{:ok, queue_id}` em caso de sucesso ao adicionar à fila
  - `{:error, reason}` em caso de falha
  """
  def send_password_reset(to, username, reset_url, expiration_hours \\ 24, options \\ []) do
    subject = "Redefinição de Senha - DeeperHub"

    assigns = %{
      username: username,
      reset_url: reset_url,
      expiration_hours: expiration_hours,
      current_year: DateTime.utc_now().year
    }

    # Define as opções padrão para emails de redefinição de senha
    # Usamos prioridade alta pois são emails importantes e sensíveis ao tempo
    default_options = [
      use_queue: true,
      priority: :high
    ]

    # Mescla as opções fornecidas com as padrões
    merged_options = Keyword.merge(default_options, options)

    send_email(to, subject, :password_reset, assigns, merged_options)
  end

  #
  # Funções privadas
  #

  # Obtém o email do remetente das configurações
  defp get_sender_email do
    Application.get_env(:deeper_hub, :mail, [])
    |> Keyword.get(:sender_email, "noreply@deeperhub.com")
  end

  # Adiciona destinatários ao email
  defp put_recipients(email, recipients) when is_list(recipients) do
    Enum.reduce(recipients, email, fn recipient, acc ->
      Mail.put_to(acc, recipient)
    end)
  end

  defp put_recipients(email, recipient) when is_binary(recipient) do
    Mail.put_to(email, recipient)
  end

  # Gera o assunto para emails de alerta com base na severidade
  defp get_alert_subject(:info, alert_type), do: "Informação de Segurança: #{alert_type}"
  defp get_alert_subject(:warning, alert_type), do: "Alerta de Segurança: #{alert_type}"
  defp get_alert_subject(:critical, alert_type), do: "CRÍTICO - Alerta de Segurança: #{alert_type}"
  defp get_alert_subject(_, alert_type), do: "Alerta de Segurança: #{alert_type}"
end
