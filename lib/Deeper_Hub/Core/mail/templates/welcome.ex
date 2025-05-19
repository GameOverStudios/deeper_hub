defmodule DeeperHub.Core.Mail.Templates.Welcome do
  @moduledoc """
  Template de email para boas-vindas a novos usuários.
  
  Este módulo fornece funções para renderizar templates de email
  para boas-vindas, tanto em formato HTML quanto texto plano.
  """
  
  @doc """
  Renderiza o template HTML para um email de boas-vindas.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:username` - Nome do usuário
    - `:verification_url` - URL para verificação de email (opcional)
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
      verification_url: nil,
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    verification_section = if assigns.verification_url do
      """
      <div style="margin: 30px 0; text-align: center;">
        <p>Para confirmar seu email e ativar sua conta, clique no botão abaixo:</p>
        <a href="#{assigns.verification_url}" class="button" style="display: inline-block; background-color: #4CAF50; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold;">Verificar Email</a>
      </div>
      """
    else
      ""
    end
    
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Bem-vindo ao #{assigns.app_name}!</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4CAF50; color: white; padding: 10px 20px; border-radius: 5px 5px 0 0; }
        .content { border: 1px solid #ddd; border-top: none; padding: 20px; border-radius: 0 0 5px 5px; }
        .footer { margin-top: 20px; font-size: 12px; color: #777; text-align: center; }
        h1 { margin: 0; font-size: 22px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Bem-vindo ao #{assigns.app_name}!</h1>
        </div>
        <div class="content">
          <p>Olá <strong>#{assigns.username}</strong>,</p>
          
          <p>Estamos muito felizes em tê-lo como parte da nossa comunidade!</p>
          
          <p>Sua conta foi criada com sucesso e você já pode começar a usar todos os recursos da plataforma.</p>
          
          #{verification_section}
          
          <p>Se você tiver alguma dúvida ou precisar de ajuda, não hesite em entrar em contato com nossa equipe de suporte.</p>
          
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
  Renderiza o template de texto plano para um email de boas-vindas.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:username` - Nome do usuário
    - `:verification_url` - URL para verificação de email (opcional)
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
      verification_url: nil,
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    verification_section = if assigns.verification_url do
      """
      
      Para confirmar seu email e ativar sua conta, acesse o link abaixo:
      #{assigns.verification_url}
      """
    else
      ""
    end
    
    """
    Bem-vindo ao #{assigns.app_name}!
    
    Olá #{assigns.username},
    
    Estamos muito felizes em tê-lo como parte da nossa comunidade!
    
    Sua conta foi criada com sucesso e você já pode começar a usar todos os recursos da plataforma.
    #{verification_section}
    
    Se você tiver alguma dúvida ou precisar de ajuda, não hesite em entrar em contato com nossa equipe de suporte.
    
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
