defmodule DeeperHub.Core.Mail.Templates.PasswordReset do
  @moduledoc """
  Template de email para redefinição de senha.
  
  Este módulo fornece funções para renderizar templates de email
  para redefinição de senha, tanto em formato HTML quanto texto plano.
  """
  
  @doc """
  Renderiza o template HTML para um email de redefinição de senha.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:username` - Nome do usuário
    - `:reset_url` - URL para redefinição de senha
    - `:expiration_hours` - Tempo de expiração do link em horas
    - `:app_name` - Nome da aplicação
    - `:support_email` - Email de suporte
    - `:current_year` - Ano atual
  
  ## Retorno
  
  - String HTML do template renderizado
  """
  def render_html(assigns) do
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      username: "usuário",
      reset_url: "#",
      expiration_hours: 24,
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Redefinição de Senha - #{assigns.app_name}</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #2196F3; color: white; padding: 10px 20px; border-radius: 5px 5px 0 0; }
        .content { border: 1px solid #ddd; border-top: none; padding: 20px; border-radius: 0 0 5px 5px; }
        .footer { margin-top: 20px; font-size: 12px; color: #777; text-align: center; }
        .button { display: inline-block; background-color: #2196F3; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold; }
        h1 { margin: 0; font-size: 22px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Redefinição de Senha</h1>
        </div>
        <div class="content">
          <p>Olá <strong>#{assigns.username}</strong>,</p>
          
          <p>Recebemos uma solicitação para redefinir a senha da sua conta no #{assigns.app_name}.</p>
          
          <div style="margin: 30px 0; text-align: center;">
            <p>Para criar uma nova senha, clique no botão abaixo:</p>
            <a href="#{assigns.reset_url}" class="button">Redefinir Senha</a>
          </div>
          
          <p>Ou copie e cole o seguinte link no seu navegador:</p>
          <p style="background-color: #f9f9f9; padding: 10px; border-left: 4px solid #2196F3;">
            #{assigns.reset_url}
          </p>
          
          <p><strong>Importante:</strong> Este link expirará em #{assigns.expiration_hours} horas.</p>
          
          <p>Se você não solicitou esta redefinição de senha, por favor ignore este email ou entre em contato com nossa equipe de suporte.</p>
          
          <p>Atenciosamente,<br>Equipe #{assigns.app_name}</p>
        </div>
        <div class="footer">
          <p>&copy; #{assigns.current_year} #{assigns.app_name}. Todos os direitos reservados.</p>
          <p>Para suporte, contate <a href="mailto:#{assigns.support_email}">#{assigns.support_email}</a></p>
        </div>
      </div>
    </body>
    </html>
    """
  end
  
  @doc """
  Renderiza o template de texto plano para um email de redefinição de senha.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:username` - Nome do usuário
    - `:reset_url` - URL para redefinição de senha
    - `:expiration_hours` - Tempo de expiração do link em horas
    - `:app_name` - Nome da aplicação
    - `:support_email` - Email de suporte
    - `:current_year` - Ano atual
  
  ## Retorno
  
  - String de texto plano do template renderizado
  """
  def render_text(assigns) do
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      username: "usuário",
      reset_url: "#",
      expiration_hours: 24,
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    """
    Redefinição de Senha - #{assigns.app_name}
    
    Olá #{assigns.username},
    
    Recebemos uma solicitação para redefinir a senha da sua conta no #{assigns.app_name}.
    
    Para criar uma nova senha, acesse o link abaixo:
    #{assigns.reset_url}
    
    Este link expirará em #{assigns.expiration_hours} horas.
    
    Se você não solicitou esta redefinição de senha, por favor ignore este email ou entre em contato com nossa equipe de suporte.
    
    Atenciosamente,
    Equipe #{assigns.app_name}
    
    --
    © #{assigns.current_year} #{assigns.app_name}. Todos os direitos reservados.
    Para suporte, contate #{assigns.support_email}
    """
  end
  
  # Obtém o email de suporte das configurações
  defp get_support_email do
    Application.get_env(:deeper_hub, :mail, [])
    |> Keyword.get(:support_email, "suporte@deeperhub.com")
  end
end
