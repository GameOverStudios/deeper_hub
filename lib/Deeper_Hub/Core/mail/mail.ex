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

  @doc """
  Envia um email com código de verificação para autenticação em duas etapas.

  ## Parâmetros

  - `to` - Endereço de email do destinatário
  - `code` - Código de verificação
  - `expires_in_minutes` - Tempo de expiração do código em minutos
  - `device_info` - Informações sobre o dispositivo que solicitou o código
  - `options` - Opções adicionais para o envio
    - `:use_queue` - Se `true`, usa a fila para envio (padrão: `true`)
    - `:priority` - Prioridade na fila (padrão: `:high`)
    - `:async` - Se `true`, envia de forma assíncrona (padrão: `false`)

  ## Retorno

  - `{:ok, message_id}` em caso de sucesso
  - `{:ok, queue_id}` em caso de sucesso ao adicionar à fila
  - `{:error, reason}` em caso de falha
  """
  def send_verification_code(to, code, expires_in_minutes \\ 10, device_info \\ %{}, options \\ []) do
    subject = "Seu código de verificação - DeeperHub"

    # Garante que device_info tenha todos os campos necessários
    device_info = Map.merge(%{
      browser: "Desconhecido",
      os: "Desconhecido",
      ip: "Desconhecido",
      location: "Desconhecido"
    }, device_info)

    assigns = %{
      code: code,
      expires_in_minutes: expires_in_minutes,
      device_info: device_info,
      current_year: DateTime.utc_now().year
    }

    # Define as opções padrão para emails de código de verificação
    # Usamos prioridade alta pois são emails importantes e sensíveis ao tempo
    default_options = [
      use_queue: true,
      priority: :high
    ]

    # Mescla as opções fornecidas com as padrões
    merged_options = Keyword.merge(default_options, options)

    send_email(to, subject, :verification_code, assigns, merged_options)
  end

  @doc """
  Envia um email de convite para acesso a um recurso.

  ## Parâmetros

  - `to` - Endereço de email do destinatário
  - `inviter_name` - Nome de quem está convidando
  - `resource_type` - Tipo de recurso (projeto, documento, etc)
  - `resource_name` - Nome do recurso
  - `invitation_link` - Link para aceitar o convite
  - `options` - Opções adicionais para o envio
    - `:expires_in_days` - Dias até a expiração do convite (padrão: 7)
    - `:message` - Mensagem personalizada (opcional)
    - `:use_queue` - Se `true`, usa a fila para envio (padrão: `true`)
    - `:priority` - Prioridade na fila (padrão: `:normal`)
    - `:async` - Se `true`, envia de forma assíncrona (padrão: `false`)

  ## Retorno

  - `{:ok, message_id}` em caso de sucesso
  - `{:ok, queue_id}` em caso de sucesso ao adicionar à fila
  - `{:error, reason}` em caso de falha
  """
  def send_invitation(to, inviter_name, resource_type, resource_name, invitation_link, options \\ []) do
    subject = "Convite para #{resource_type} - DeeperHub"

    # Extrai opções específicas do convite
    expires_in_days = Keyword.get(options, :expires_in_days, 7)
    message = Keyword.get(options, :message)

    # Remove opções específicas do convite para não passar para o send_email
    options = Keyword.drop(options, [:expires_in_days, :message])

    assigns = %{
      inviter_name: inviter_name,
      resource_type: resource_type,
      resource_name: resource_name,
      invitation_link: invitation_link,
      expires_in_days: expires_in_days,
      message: message,
      current_year: DateTime.utc_now().year
    }

    # Define as opções padrão para emails de convite
    default_options = [
      use_queue: true,
      priority: :normal
    ]

    # Mescla as opções fornecidas com as padrões
    merged_options = Keyword.merge(default_options, options)

    send_email(to, subject, :invitation, assigns, merged_options)
  end

  @doc """
  Envia um email de confirmação de ação importante.

  ## Parâmetros

  - `to` - Endereço de email do destinatário
  - `user_name` - Nome do usuário
  - `action_type` - Tipo de ação (ex: "alteração de senha", "exclusão de conta")
  - `confirmation_link` - Link para confirmar a ação
  - `cancel_link` - Link para cancelar a ação
  - `options` - Opções adicionais para o envio
    - `:expires_in_hours` - Horas até a expiração da solicitação (padrão: 24)
    - `:use_queue` - Se `true`, usa a fila para envio (padrão: `true`)
    - `:priority` - Prioridade na fila (padrão: `:high`)
    - `:async` - Se `true`, envia de forma assíncrona (padrão: `false`)

  ## Retorno

  - `{:ok, message_id}` em caso de sucesso
  - `{:ok, queue_id}` em caso de sucesso ao adicionar à fila
  - `{:error, reason}` em caso de falha
  """
  def send_action_confirmation(to, user_name, action_type, confirmation_link, cancel_link, options \\ []) do
    subject = "Confirmação de #{action_type} - DeeperHub"

    # Extrai opções específicas da confirmação de ação
    expires_in_hours = Keyword.get(options, :expires_in_hours, 24)

    # Remove opções específicas para não passar para o send_email
    options = Keyword.drop(options, [:expires_in_hours])

    assigns = %{
      user_name: user_name,
      action_type: action_type,
      confirmation_link: confirmation_link,
      cancel_link: cancel_link,
      expires_in_hours: expires_in_hours,
      current_year: DateTime.utc_now().year
    }

    # Define as opções padrão para emails de confirmação de ação
    # Usamos prioridade alta pois são emails importantes e sensíveis ao tempo
    default_options = [
      use_queue: true,
      priority: :high
    ]

    # Mescla as opções fornecidas com as padrões
    merged_options = Keyword.merge(default_options, options)

    send_email(to, subject, :action_confirmation, assigns, merged_options)
  end

  @doc """
  Envia um email de alerta de login em novo dispositivo.

  ## Parâmetros

  - `to` - Endereço de email do destinatário
  - `user_name` - Nome do usuário
  - `device_info` - Informações sobre o dispositivo
  - `security_link` - Link para as configurações de segurança
  - `options` - Opções adicionais para o envio
    - `:use_queue` - Se `true`, usa a fila para envio (padrão: `true`)
    - `:priority` - Prioridade na fila (padrão: `:high`)
    - `:async` - Se `true`, envia de forma assíncrona (padrão: `false`)

  ## Retorno

  - `{:ok, message_id}` em caso de sucesso
  - `{:ok, queue_id}` em caso de sucesso ao adicionar à fila
  - `{:error, reason}` em caso de falha
  """
  def send_new_device_login(to, user_name, device_info, security_link, options \\ []) do
    subject = "Alerta de Segurança: Login em Novo Dispositivo - DeeperHub"

    # Garante que device_info tenha todos os campos necessários
    device_info = Map.merge(%{
      browser: "Desconhecido",
      os: "Desconhecido",
      ip: "Desconhecido",
      location: "Desconhecido"
    }, device_info)

    assigns = %{
      user_name: user_name,
      device_info: device_info,
      login_time: DateTime.utc_now() |> Calendar.strftime("%d/%m/%Y às %H:%M:%S"),
      security_link: security_link,
      current_year: DateTime.utc_now().year
    }

    # Define as opções padrão para emails de alerta de novo dispositivo
    # Usamos prioridade alta pois são emails importantes de segurança
    default_options = [
      use_queue: true,
      priority: :high
    ]

    # Mescla as opções fornecidas com as padrões
    merged_options = Keyword.merge(default_options, options)

    send_email(to, subject, :new_device_login, assigns, merged_options)
  end

  @doc """
  Envia um email de notificação de segurança avançada.

  ## Parâmetros

  - `to` - Endereço de email do destinatário
  - `user_name` - Nome do usuário
  - `event_type` - Tipo de evento de segurança
  - `event_details` - Detalhes do evento
  - `security_link` - Link para as configurações de segurança
  - `options` - Opções adicionais para o envio
    - `:severity` - Nível de severidade ("alta", "média", "baixa", padrão: "média")
    - `:recommendations` - Lista de recomendações para o usuário
    - `:use_queue` - Se `true`, usa a fila para envio (padrão: `true`)
    - `:priority` - Prioridade na fila (baseada na severidade)
    - `:async` - Se `true`, envia de forma assíncrona (padrão: `false`)

  ## Retorno

  - `{:ok, message_id}` em caso de sucesso
  - `{:ok, queue_id}` em caso de sucesso ao adicionar à fila
  - `{:error, reason}` em caso de falha
  """
  def send_security_notification(to, user_name, event_type, event_details, security_link, options \\ []) do
    # Extrai opções específicas da notificação de segurança
    severity = Keyword.get(options, :severity, "média")
    recommendations = Keyword.get(options, :recommendations, [
      "Verifique as atividades recentes em sua conta",
      "Considere alterar sua senha"
    ])

    # Remove opções específicas para não passar para o send_email
    options = Keyword.drop(options, [:severity, :recommendations])

    # Ajusta o assunto com base na severidade
    subject = case String.downcase(severity) do
      "alta" -> "URGENTE: Notificação de Segurança - #{event_type}"
      "média" -> "Notificação de Segurança: #{event_type}"
      "baixa" -> "Informação de Segurança: #{event_type}"
      _ -> "Notificação de Segurança: #{event_type}"
    end

    # Garante que event_details tenha todos os campos necessários
    event_details = Map.merge(%{
      description: "Evento de segurança detectado",
      location: "Desconhecido",
      ip: "Desconhecido"
    }, event_details)

    assigns = %{
      user_name: user_name,
      event_type: event_type,
      event_details: event_details,
      event_time: DateTime.utc_now() |> Calendar.strftime("%d/%m/%Y às %H:%M:%S"),
      security_link: security_link,
      severity: severity,
      recommendations: recommendations,
      current_year: DateTime.utc_now().year
    }

    # Define a prioridade com base na severidade
    priority = case String.downcase(severity) do
      "alta" -> :high
      "baixa" -> :low
      _ -> :normal
    end

    # Define as opções padrão para emails de notificação de segurança
    default_options = [
      use_queue: true,
      priority: priority
    ]

    # Mescla as opções fornecidas com as padrões
    merged_options = Keyword.merge(default_options, options)

    send_email(to, subject, :security_notification, assigns, merged_options)
  end

  @doc """
  Envia um email de notificação de atualização do sistema.

  ## Parâmetros

  - `to` - Endereço de email do destinatário
  - `user_name` - Nome do usuário
  - `update_title` - Título da atualização
  - `update_details` - Detalhes da atualização
  - `options` - Opções adicionais para o envio
    - `:update_type` - Tipo de atualização ("nova versão", "manutenção", etc, padrão: "atualização")
    - `:new_features` - Lista de novos recursos
    - `:fixed_issues` - Lista de problemas corrigidos
    - `:maintenance_window` - Janela de manutenção
    - `:action_link` - Link para ação relacionada
    - `:action_text` - Texto para o botão de ação
    - `:use_queue` - Se `true`, usa a fila para envio (padrão: `true`)
    - `:priority` - Prioridade na fila (padrão: `:low` para atualizações normais, `:normal` para manutenção)
    - `:async` - Se `true`, envia de forma assíncrona (padrão: `false`)

  ## Retorno

  - `{:ok, message_id}` em caso de sucesso
  - `{:ok, queue_id}` em caso de sucesso ao adicionar à fila
  - `{:error, reason}` em caso de falha
  """
  def send_system_update(to, user_name, update_title, update_details, options \\ []) do
    # Extrai opções específicas da atualização do sistema
    update_type = Keyword.get(options, :update_type, "atualização")
    new_features = Keyword.get(options, :new_features, [])
    fixed_issues = Keyword.get(options, :fixed_issues, [])
    maintenance_window = Keyword.get(options, :maintenance_window)
    action_link = Keyword.get(options, :action_link)
    action_text = Keyword.get(options, :action_text, "Saiba Mais")

    # Remove opções específicas para não passar para o send_email
    options = Keyword.drop(options, [:update_type, :new_features, :fixed_issues, 
                                  :maintenance_window, :action_link, :action_text])

    # Define o assunto com base no tipo de atualização
    subject = case String.downcase(update_type) do
      "manutenção" -> "Manutenção Programada - #{update_title}"
      "nova versão" -> "Nova Versão Disponível - #{update_title}"
      _ -> update_title
    end

    assigns = %{
      user_name: user_name,
      update_type: update_type,
      update_title: update_title,
      update_details: update_details,
      update_date: DateTime.utc_now() |> Calendar.strftime("%d/%m/%Y"),
      new_features: new_features,
      fixed_issues: fixed_issues,
      maintenance_window: maintenance_window,
      action_link: action_link,
      action_text: action_text,
      current_year: DateTime.utc_now().year
    }

    # Define a prioridade com base no tipo de atualização
    priority = case String.downcase(update_type) do
      "manutenção" -> :normal  # Manutenção é mais importante que atualizações normais
      _ -> :low  # Atualizações normais têm prioridade baixa
    end

    # Define as opções padrão para emails de atualização do sistema
    default_options = [
      use_queue: true,
      priority: priority
    ]

    # Mescla as opções fornecidas com as padrões
    merged_options = Keyword.merge(default_options, options)

    send_email(to, subject, :system_update, assigns, merged_options)
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
