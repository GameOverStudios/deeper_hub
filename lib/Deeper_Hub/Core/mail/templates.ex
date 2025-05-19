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
