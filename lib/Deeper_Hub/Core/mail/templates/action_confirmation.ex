defmodule DeeperHub.Core.Mail.Templates.ActionConfirmation do
  @moduledoc """
  Template de email para confirmação de ações importantes.
  
  Este módulo fornece funções para renderizar templates de email
  para confirmação de ações sensíveis como alterações de configurações,
  exclusão de dados, entre outros.
  """
  
  @doc """
  Renderiza o template HTML para um email de confirmação de ação.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:action_type` - Tipo de ação (ex: "alteração de senha", "exclusão de conta")
    - `:user_name` - Nome do usuário
    - `:confirmation_link` - Link para confirmar a ação
    - `:cancel_link` - Link para cancelar a ação
    - `:expires_in_hours` - Horas até a expiração da solicitação
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
      user_name: "Usuário",
      action_type: "ação importante",
      confirmation_link: "#",
      cancel_link: "#",
      expires_in_hours: 24,
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Confirmação de #{assigns.action_type} - #{assigns.app_name}</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4285F4; color: white; padding: 10px 20px; border-radius: 5px 5px 0 0; }
        .content { border: 1px solid #ddd; border-top: none; padding: 20px; border-radius: 0 0 5px 5px; }
        .footer { margin-top: 20px; font-size: 12px; color: #777; text-align: center; }
        .button-confirm { display: inline-block; background-color: #4285F4; color: white; padding: 10px 20px; 
                         text-decoration: none; border-radius: 4px; margin: 10px 10px 10px 0; font-weight: bold; }
        .button-cancel { display: inline-block; background-color: #f44336; color: white; padding: 10px 20px; 
                        text-decoration: none; border-radius: 4px; margin: 10px 0; font-weight: bold; }
        .warning { background-color: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; margin: 15px 0; }
        h1 { margin: 0; font-size: 22px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Confirmação de #{assigns.action_type}</h1>
        </div>
        <div class="content">
          <p>Olá, <strong>#{assigns.user_name}</strong>!</p>
          
          <p>Recebemos uma solicitação para realizar a seguinte ação em sua conta no #{assigns.app_name}:</p>
          
          <p style="font-size: 18px; font-weight: bold; text-align: center;">#{assigns.action_type}</p>
          
          <div class="warning">
            <p><strong>Importante:</strong> Se você não solicitou esta ação, por favor, cancele imediatamente 
            clicando no botão "Cancelar" abaixo e altere sua senha para proteger sua conta.</p>
          </div>
          
          <p>Para confirmar esta ação, clique no botão abaixo:</p>
          
          <div style="text-align: center; margin: 20px 0;">
            <a href="#{assigns.confirmation_link}" class="button-confirm">Confirmar</a>
            <a href="#{assigns.cancel_link}" class="button-cancel">Cancelar</a>
          </div>
          
          <p>Esta solicitação expirará em <strong>#{assigns.expires_in_hours} horas</strong>.</p>
          
          <p>Se você tiver alguma dúvida ou precisar de assistência, entre em contato com nosso suporte.</p>
          
          <p>Atenciosamente,<br>Equipe de Segurança #{assigns.app_name}</p>
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
  Renderiza o template de texto plano para um email de confirmação de ação.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:action_type` - Tipo de ação (ex: "alteração de senha", "exclusão de conta")
    - `:user_name` - Nome do usuário
    - `:confirmation_link` - Link para confirmar a ação
    - `:cancel_link` - Link para cancelar a ação
    - `:expires_in_hours` - Horas até a expiração da solicitação
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
      user_name: "Usuário",
      action_type: "ação importante",
      confirmation_link: "#",
      cancel_link: "#",
      expires_in_hours: 24,
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    """
    Confirmação de #{assigns.action_type} - #{assigns.app_name}
    
    Olá, #{assigns.user_name}!
    
    Recebemos uma solicitação para realizar a seguinte ação em sua conta no #{assigns.app_name}:
    
    #{assigns.action_type}
    
    IMPORTANTE: Se você não solicitou esta ação, por favor, cancele imediatamente 
    acessando o link "Cancelar" abaixo e altere sua senha para proteger sua conta.
    
    Para confirmar esta ação, acesse o link abaixo:
    #{assigns.confirmation_link}
    
    Para cancelar esta ação, acesse o link abaixo:
    #{assigns.cancel_link}
    
    Esta solicitação expirará em #{assigns.expires_in_hours} horas.
    
    Se você tiver alguma dúvida ou precisar de assistência, entre em contato com nosso suporte.
    
    Atenciosamente,
    Equipe de Segurança #{assigns.app_name}
    
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
