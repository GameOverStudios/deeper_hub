defmodule DeeperHub.Core.Mail.Templates.Invitation do
  @moduledoc """
  Template de email para convites e compartilhamento de recursos.
  
  Este módulo fornece funções para renderizar templates de email
  para convites de acesso a recursos ou compartilhamento de conteúdo.
  """
  
  @doc """
  Renderiza o template HTML para um email de convite.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:inviter_name` - Nome de quem está convidando
    - `:resource_type` - Tipo de recurso (projeto, documento, etc)
    - `:resource_name` - Nome do recurso
    - `:invitation_link` - Link para aceitar o convite
    - `:expires_in_days` - Dias até a expiração do convite
    - `:message` - Mensagem personalizada (opcional)
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
      inviter_name: "Um usuário",
      resource_type: "recurso",
      resource_name: "Recurso Compartilhado",
      invitation_link: "#",
      expires_in_days: 7,
      message: nil,
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Convite para #{assigns.resource_type} - #{assigns.app_name}</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4285F4; color: white; padding: 10px 20px; border-radius: 5px 5px 0 0; }
        .content { border: 1px solid #ddd; border-top: none; padding: 20px; border-radius: 0 0 5px 5px; }
        .footer { margin-top: 20px; font-size: 12px; color: #777; text-align: center; }
        .button { display: inline-block; background-color: #4285F4; color: white; padding: 10px 20px; 
                 text-decoration: none; border-radius: 4px; margin: 20px 0; font-weight: bold; }
        .message { background-color: #f9f9f9; padding: 15px; border-left: 4px solid #4285F4; 
                  margin: 15px 0; font-style: italic; }
        h1 { margin: 0; font-size: 22px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Convite para #{assigns.resource_type}</h1>
        </div>
        <div class="content">
          <p><strong>#{assigns.inviter_name}</strong> convidou você para acessar #{assigns.resource_type} <strong>#{assigns.resource_name}</strong> no #{assigns.app_name}.</p>
          
          #{if assigns.message do
            """
            <div class="message">
              <p>Mensagem de #{assigns.inviter_name}:</p>
              <p>"#{assigns.message}"</p>
            </div>
            """
          else
            ""
          end}
          
          <p>Para aceitar este convite e acessar o #{assigns.resource_type}, clique no botão abaixo:</p>
          
          <div style="text-align: center;">
            <a href="#{assigns.invitation_link}" class="button">Aceitar Convite</a>
          </div>
          
          <p>Este convite expirará em <strong>#{assigns.expires_in_days} dias</strong>.</p>
          
          <p>Se você não conhece #{assigns.inviter_name} ou acredita que este convite foi enviado por engano, 
          você pode ignorá-lo com segurança.</p>
          
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
  Renderiza o template de texto plano para um email de convite.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:inviter_name` - Nome de quem está convidando
    - `:resource_type` - Tipo de recurso (projeto, documento, etc)
    - `:resource_name` - Nome do recurso
    - `:invitation_link` - Link para aceitar o convite
    - `:expires_in_days` - Dias até a expiração do convite
    - `:message` - Mensagem personalizada (opcional)
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
      inviter_name: "Um usuário",
      resource_type: "recurso",
      resource_name: "Recurso Compartilhado",
      invitation_link: "#",
      expires_in_days: 7,
      message: nil,
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    message_text = if assigns.message do
      """
      
      Mensagem de #{assigns.inviter_name}:
      "#{assigns.message}"
      
      """
    else
      ""
    end
    
    """
    Convite para #{assigns.resource_type} - #{assigns.app_name}
    
    #{assigns.inviter_name} convidou você para acessar #{assigns.resource_type} #{assigns.resource_name} no #{assigns.app_name}.
    #{message_text}
    Para aceitar este convite e acessar o #{assigns.resource_type}, acesse o link abaixo:
    
    #{assigns.invitation_link}
    
    Este convite expirará em #{assigns.expires_in_days} dias.
    
    Se você não conhece #{assigns.inviter_name} ou acredita que este convite foi enviado por engano, você pode ignorá-lo com segurança.
    
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
