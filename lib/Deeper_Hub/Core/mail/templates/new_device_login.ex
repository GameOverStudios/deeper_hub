defmodule DeeperHub.Core.Mail.Templates.NewDeviceLogin do
  @moduledoc """
  Template de email para alertas de login em novos dispositivos.
  
  Este módulo fornece funções para renderizar templates de email
  para notificar usuários sobre logins realizados em dispositivos não reconhecidos.
  """
  
  @doc """
  Renderiza o template HTML para um email de alerta de login em novo dispositivo.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:user_name` - Nome do usuário
    - `:device_info` - Informações sobre o dispositivo (mapa)
    - `:login_time` - Data e hora do login
    - `:security_link` - Link para as configurações de segurança
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
    
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Alerta de Segurança: Login em Novo Dispositivo - #{assigns.app_name}</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #f44336; color: white; padding: 10px 20px; border-radius: 5px 5px 0 0; }
        .content { border: 1px solid #ddd; border-top: none; padding: 20px; border-radius: 0 0 5px 5px; }
        .footer { margin-top: 20px; font-size: 12px; color: #777; text-align: center; }
        .button { display: inline-block; background-color: #4285F4; color: white; padding: 10px 20px; 
                 text-decoration: none; border-radius: 4px; margin: 20px 0; font-weight: bold; }
        .device-info { background-color: #f9f9f9; padding: 15px; border-left: 4px solid #f44336; margin: 15px 0; }
        .alert-icon { font-size: 48px; text-align: center; margin: 10px 0; color: #f44336; }
        h1 { margin: 0; font-size: 22px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Alerta de Segurança: Login em Novo Dispositivo</h1>
        </div>
        <div class="content">
          <div class="alert-icon">⚠️</div>
          
          <p>Olá, <strong>#{assigns.user_name}</strong>!</p>
          
          <p>Detectamos um login na sua conta do #{assigns.app_name} a partir de um dispositivo que você não usou anteriormente.</p>
          
          <div class="device-info">
            <p><strong>Data e Hora:</strong> #{assigns.login_time}</p>
            <p><strong>Navegador:</strong> #{assigns.device_info.browser}</p>
            <p><strong>Sistema Operacional:</strong> #{assigns.device_info.os}</p>
            <p><strong>Endereço IP:</strong> #{assigns.device_info.ip}</p>
            <p><strong>Localização:</strong> #{assigns.device_info.location}</p>
          </div>
          
          <p><strong>Foi você?</strong></p>
          <p>Se foi você quem acessou sua conta, não é necessária nenhuma ação adicional.</p>
          
          <p><strong>Não foi você?</strong></p>
          <p>Se você não reconhece este acesso, sua conta pode estar comprometida. Recomendamos que você:</p>
          <ol>
            <li>Altere sua senha imediatamente</li>
            <li>Ative a verificação em duas etapas, se ainda não estiver ativa</li>
            <li>Verifique atividades recentes em sua conta</li>
            <li>Entre em contato com nosso suporte</li>
          </ol>
          
          <div style="text-align: center;">
            <a href="#{assigns.security_link}" class="button">Verificar Configurações de Segurança</a>
          </div>
          
          <p>Estamos sempre trabalhando para manter sua conta segura.</p>
          
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
  Renderiza o template de texto plano para um email de alerta de login em novo dispositivo.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:user_name` - Nome do usuário
    - `:device_info` - Informações sobre o dispositivo (mapa)
    - `:login_time` - Data e hora do login
    - `:security_link` - Link para as configurações de segurança
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
    
    """
    ALERTA DE SEGURANÇA: LOGIN EM NOVO DISPOSITIVO - #{assigns.app_name}
    
    Olá, #{assigns.user_name}!
    
    Detectamos um login na sua conta do #{assigns.app_name} a partir de um dispositivo que você não usou anteriormente.
    
    DETALHES DO ACESSO:
    Data e Hora: #{assigns.login_time}
    Navegador: #{assigns.device_info.browser}
    Sistema Operacional: #{assigns.device_info.os}
    Endereço IP: #{assigns.device_info.ip}
    Localização: #{assigns.device_info.location}
    
    FOI VOCÊ?
    Se foi você quem acessou sua conta, não é necessária nenhuma ação adicional.
    
    NÃO FOI VOCÊ?
    Se você não reconhece este acesso, sua conta pode estar comprometida. Recomendamos que você:
    1. Altere sua senha imediatamente
    2. Ative a verificação em duas etapas, se ainda não estiver ativa
    3. Verifique atividades recentes em sua conta
    4. Entre em contato com nosso suporte
    
    Acesse suas configurações de segurança:
    #{assigns.security_link}
    
    Estamos sempre trabalhando para manter sua conta segura.
    
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
