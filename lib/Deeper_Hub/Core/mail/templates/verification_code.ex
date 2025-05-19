defmodule DeeperHub.Core.Mail.Templates.VerificationCode do
  @moduledoc """
  Template de email para envio de códigos de verificação em duas etapas.
  
  Este módulo fornece funções para renderizar templates de email
  para autenticação em duas etapas, tanto em formato HTML quanto texto plano.
  """
  
  @doc """
  Renderiza o template HTML para um email de código de verificação.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:code` - Código de verificação
    - `:expires_in_minutes` - Tempo de expiração em minutos
    - `:device_info` - Informações sobre o dispositivo (mapa)
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
    
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Código de Verificação - #{assigns.app_name}</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4285F4; color: white; padding: 10px 20px; border-radius: 5px 5px 0 0; }
        .content { border: 1px solid #ddd; border-top: none; padding: 20px; border-radius: 0 0 5px 5px; }
        .footer { margin-top: 20px; font-size: 12px; color: #777; text-align: center; }
        .code { font-size: 32px; font-weight: bold; text-align: center; margin: 20px 0; letter-spacing: 5px; color: #4285F4; }
        .device-info { background-color: #f9f9f9; padding: 10px; border-left: 4px solid #4285F4; margin: 10px 0; }
        h1 { margin: 0; font-size: 22px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Código de Verificação</h1>
        </div>
        <div class="content">
          <p>Você solicitou um código de verificação para acessar sua conta no #{assigns.app_name}.</p>
          
          <div class="code">#{assigns.code}</div>
          
          <p>Este código expirará em <strong>#{assigns.expires_in_minutes} minutos</strong>.</p>
          
          <p>A solicitação foi feita a partir do seguinte dispositivo:</p>
          
          <div class="device-info">
            <p><strong>Navegador:</strong> #{assigns.device_info.browser}</p>
            <p><strong>Sistema Operacional:</strong> #{assigns.device_info.os}</p>
            <p><strong>Endereço IP:</strong> #{assigns.device_info.ip}</p>
            <p><strong>Localização:</strong> #{assigns.device_info.location}</p>
          </div>
          
          <p>Se você não solicitou este código, recomendamos que altere sua senha imediatamente e entre em contato com nosso suporte.</p>
          
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
  Renderiza o template de texto plano para um email de código de verificação.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:code` - Código de verificação
    - `:expires_in_minutes` - Tempo de expiração em minutos
    - `:device_info` - Informações sobre o dispositivo (mapa)
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
    
    """
    Código de Verificação - #{assigns.app_name}
    
    Você solicitou um código de verificação para acessar sua conta no #{assigns.app_name}.
    
    Seu código de verificação: #{assigns.code}
    
    Este código expirará em #{assigns.expires_in_minutes} minutos.
    
    A solicitação foi feita a partir do seguinte dispositivo:
    Navegador: #{assigns.device_info.browser}
    Sistema Operacional: #{assigns.device_info.os}
    Endereço IP: #{assigns.device_info.ip}
    Localização: #{assigns.device_info.location}
    
    Se você não solicitou este código, recomendamos que altere sua senha imediatamente e entre em contato com nosso suporte.
    
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
