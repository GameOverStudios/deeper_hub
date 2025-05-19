defmodule DeeperHub.Core.Mail.Templates do
  @moduledoc """
  Módulo para gerenciamento de templates de email no DeeperHub.
  
  Este módulo fornece funções para renderização de templates de email,
  tanto em formato HTML quanto texto plano, utilizando os templates
  definidos no diretório de templates.
  """
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Mail.Templates.SecurityAlert
  alias DeeperHub.Core.Mail.Templates.Welcome
  alias DeeperHub.Core.Mail.Templates.PasswordReset
  alias DeeperHub.Core.Mail.Templates.Fallback
  alias DeeperHub.Core.Mail.Templates.VerificationCode
  alias DeeperHub.Core.Mail.Templates.Invitation
  alias DeeperHub.Core.Mail.Templates.ActionConfirmation
  alias DeeperHub.Core.Mail.Templates.NewDeviceLogin
  alias DeeperHub.Core.Mail.Templates.SecurityNotification
  alias DeeperHub.Core.Mail.Templates.SystemUpdate
  
  @doc """
  Renderiza um template de email.
  
  ## Parâmetros
  
  - `template` - Nome do template a ser renderizado (atom)
  - `assigns` - Variáveis para renderização do template
  
  ## Retorno
  
  - Tupla `{html_body, text_body}` com o conteúdo HTML e texto plano
  """
  def render(template, assigns \\ %{}) do
    case template do
      :security_alert -> render_security_alert(assigns)
      :welcome -> render_welcome(assigns)
      :password_reset -> render_password_reset(assigns)
      :verification_code -> render_verification_code(assigns)
      :invitation -> render_invitation(assigns)
      :action_confirmation -> render_action_confirmation(assigns)
      :new_device_login -> render_new_device_login(assigns)
      :security_notification -> render_security_notification(assigns)
      :system_update -> render_system_update(assigns)
      _ -> render_fallback(template, assigns)
    end
  end
  
  #
  # Templates específicos
  #
  
  # Template de alerta de segurança
  defp render_security_alert(assigns) do
    # Obtém a severidade ou usa o padrão
    severity = Map.get(assigns, :severity, :warning)
    
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      alert_type: "Alerta de Segurança",
      alert_message: "Foi detectado um evento de segurança no sistema.",
      alert_details: %{},
      severity: severity,
      timestamp: DateTime.utc_now(),
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    # Renderiza os templates HTML e texto usando o módulo específico
    html = SecurityAlert.render_html(assigns)
    text = SecurityAlert.render_text(assigns)
    
    {html, text}
  end
  
  # Template de boas-vindas
  defp render_welcome(assigns) do
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      username: "usuário",
      verification_url: nil,
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    # Renderiza os templates HTML e texto usando o módulo específico
    html = Welcome.render_html(assigns)
    text = Welcome.render_text(assigns)
    
    {html, text}
  end
  
  # Template de redefinição de senha
  defp render_password_reset(assigns) do
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      username: "usuário",
      reset_url: "#",
      expiration_hours: 24,
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    # Renderiza os templates HTML e texto usando o módulo específico
    html = PasswordReset.render_html(assigns)
    text = PasswordReset.render_text(assigns)
    
    {html, text}
  end
  
  # Template de código de verificação em duas etapas
  defp render_verification_code(assigns) do
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      code: "000000",
      expires_in_minutes: 10,
      device_info: %{
        browser: "Desconhecido",
        os: "Desconhecido",
        ip: "Desconhecido",
        location: "Desconhecido"
      },
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    # Renderiza os templates HTML e texto usando o módulo específico
    html = VerificationCode.render_html(assigns)
    text = VerificationCode.render_text(assigns)
    
    {html, text}
  end
  
  # Template de convite e compartilhamento
  defp render_invitation(assigns) do
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      inviter_name: "Um usuário",
      resource_type: "recurso",
      resource_name: "Recurso Compartilhado",
      invitation_link: "#",
      expires_in_days: 7,
      message: nil,
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    # Renderiza os templates HTML e texto usando o módulo específico
    html = Invitation.render_html(assigns)
    text = Invitation.render_text(assigns)
    
    {html, text}
  end
  
  # Template de confirmação de ação
  defp render_action_confirmation(assigns) do
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      user_name: "Usuário",
      action_type: "ação importante",
      confirmation_link: "#",
      cancel_link: "#",
      expires_in_hours: 24,
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    # Renderiza os templates HTML e texto usando o módulo específico
    html = ActionConfirmation.render_html(assigns)
    text = ActionConfirmation.render_text(assigns)
    
    {html, text}
  end
  
  # Template de alerta de login em novo dispositivo
  defp render_new_device_login(assigns) do
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      user_name: "Usuário",
      device_info: %{
        browser: "Desconhecido",
        os: "Desconhecido",
        ip: "Desconhecido",
        location: "Desconhecido"
      },
      login_time: DateTime.utc_now() |> Calendar.strftime("%d/%m/%Y às %H:%M:%S"),
      security_link: "#",
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    # Renderiza os templates HTML e texto usando o módulo específico
    html = NewDeviceLogin.render_html(assigns)
    text = NewDeviceLogin.render_text(assigns)
    
    {html, text}
  end
  
  # Template de notificação de segurança avançada
  defp render_security_notification(assigns) do
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      user_name: "Usuário",
      event_type: "Evento de segurança",
      event_details: %{
        description: "Descrição do evento de segurança",
        location: "Desconhecido",
        ip: "Desconhecido"
      },
      event_time: DateTime.utc_now() |> Calendar.strftime("%d/%m/%Y às %H:%M:%S"),
      security_link: "#",
      severity: "média",
      recommendations: [
        "Verifique as atividades recentes em sua conta",
        "Considere alterar sua senha"
      ],
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    # Renderiza os templates HTML e texto usando o módulo específico
    html = SecurityNotification.render_html(assigns)
    text = SecurityNotification.render_text(assigns)
    
    {html, text}
  end
  
  # Template de atualização do sistema
  defp render_system_update(assigns) do
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      user_name: "Usuário",
      update_type: "atualização",
      update_title: "Atualização do Sistema",
      update_details: "Detalhes da atualização do sistema.",
      update_date: DateTime.utc_now() |> Calendar.strftime("%d/%m/%Y"),
      new_features: [],
      fixed_issues: [],
      maintenance_window: nil,
      action_link: nil,
      action_text: "Saiba Mais",
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    # Renderiza os templates HTML e texto usando o módulo específico
    html = SystemUpdate.render_html(assigns)
    text = SystemUpdate.render_text(assigns)
    
    {html, text}
  end
  
  # Template fallback para templates desconhecidos
  defp render_fallback(template, assigns) do
    Logger.warn("Template de email desconhecido: #{inspect(template)}", 
               module: __MODULE__)
    
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      template_name: inspect(template),
      assigns: inspect(assigns),
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    # Renderiza um template genérico usando o módulo específico
    html = Fallback.render_html(assigns)
    text = Fallback.render_text(assigns)
    
    {html, text}
  end
  
  #
  # Funções auxiliares
  #
  
  # Obtém o email de suporte das configurações
  defp get_support_email do
    Application.get_env(:deeper_hub, :mail, [])
    |> Keyword.get(:support_email, "suporte@deeperhub.com")
  end
end
