defmodule DeeperHub.Core.Mail.Templates.Fallback do
  @moduledoc """
  Template genérico de email para uso quando um template específico não é encontrado.
  
  Este módulo fornece funções para renderizar um template genérico de email,
  tanto em formato HTML quanto texto plano, para ser usado como fallback.
  """
  
  @doc """
  Renderiza o template HTML genérico.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:template_name` - Nome do template solicitado
    - `:assigns` - Assigns originais (para depuração)
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
      template_name: "desconhecido",
      assigns: "{}",
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Notificação - #{assigns.app_name}</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #607D8B; color: white; padding: 10px 20px; border-radius: 5px 5px 0 0; }
        .content { border: 1px solid #ddd; border-top: none; padding: 20px; border-radius: 0 0 5px 5px; }
        .footer { margin-top: 20px; font-size: 12px; color: #777; text-align: center; }
        .debug { background-color: #f5f5f5; padding: 10px; border-left: 4px solid #607D8B; font-family: monospace; margin: 20px 0; }
        h1 { margin: 0; font-size: 22px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Notificação do #{assigns.app_name}</h1>
        </div>
        <div class="content">
          <p>Esta é uma notificação automática do sistema #{assigns.app_name}.</p>
          
          <div class="debug">
            <p><strong>Template solicitado:</strong> #{assigns.template_name}</p>
          </div>
          
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
  Renderiza o template de texto plano genérico.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:template_name` - Nome do template solicitado
    - `:assigns` - Assigns originais (para depuração)
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
      template_name: "desconhecido",
      assigns: "{}",
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    """
    Notificação do #{assigns.app_name}
    
    Esta é uma notificação automática do sistema #{assigns.app_name}.
    
    Template solicitado: #{assigns.template_name}
    
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
