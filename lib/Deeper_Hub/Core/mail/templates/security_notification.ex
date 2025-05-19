defmodule DeeperHub.Core.Mail.Templates.SecurityNotification do
  @moduledoc """
  Template de email para notificações de segurança avançadas.
  
  Este módulo fornece funções para renderizar templates de email
  para alertas de segurança como tentativas de acesso suspeitas,
  alterações em configurações de segurança e outros eventos relevantes.
  """
  
  @doc """
  Renderiza o template HTML para um email de notificação de segurança.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:user_name` - Nome do usuário
    - `:event_type` - Tipo de evento de segurança
    - `:event_details` - Detalhes do evento (mapa)
    - `:event_time` - Data e hora do evento
    - `:security_link` - Link para as configurações de segurança
    - `:severity` - Nível de severidade (alta, média, baixa)
    - `:recommendations` - Lista de recomendações para o usuário
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
    
    # Define a cor baseada na severidade
    severity_color = case String.downcase(assigns.severity) do
      "alta" -> "#f44336" # Vermelho
      "média" -> "#ff9800" # Laranja
      "baixa" -> "#4caf50" # Verde
      _ -> "#ff9800" # Padrão: Laranja
    end
    
    # Gera os itens da lista de recomendações
    recommendations_html = assigns.recommendations
    |> Enum.map(fn rec -> "<li>#{rec}</li>" end)
    |> Enum.join("\n          ")
    
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Notificação de Segurança: #{assigns.event_type} - #{assigns.app_name}</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #{severity_color}; color: white; padding: 10px 20px; border-radius: 5px 5px 0 0; }
        .content { border: 1px solid #ddd; border-top: none; padding: 20px; border-radius: 0 0 5px 5px; }
        .footer { margin-top: 20px; font-size: 12px; color: #777; text-align: center; }
        .button { display: inline-block; background-color: #4285F4; color: white; padding: 10px 20px; 
                 text-decoration: none; border-radius: 4px; margin: 20px 0; font-weight: bold; }
        .event-details { background-color: #f9f9f9; padding: 15px; border-left: 4px solid #{severity_color}; margin: 15px 0; }
        .severity-badge { display: inline-block; padding: 5px 10px; border-radius: 3px; color: white; 
                         background-color: #{severity_color}; font-weight: bold; font-size: 14px; }
        h1 { margin: 0; font-size: 22px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Notificação de Segurança: #{assigns.event_type}</h1>
        </div>
        <div class="content">
          <p>Olá, <strong>#{assigns.user_name}</strong>!</p>
          
          <p>Gostaríamos de informá-lo sobre um evento de segurança recente relacionado à sua conta no #{assigns.app_name}.</p>
          
          <p>
            <span class="severity-badge">Severidade #{String.capitalize(assigns.severity)}</span>
            <span style="margin-left: 10px;">#{assigns.event_time}</span>
          </p>
          
          <div class="event-details">
            <p><strong>Evento:</strong> #{assigns.event_type}</p>
            <p><strong>Descrição:</strong> #{assigns.event_details.description}</p>
            <p><strong>Localização:</strong> #{assigns.event_details.location}</p>
            <p><strong>Endereço IP:</strong> #{assigns.event_details.ip}</p>
          </div>
          
          <p><strong>Recomendações:</strong></p>
          <ul>
          #{recommendations_html}
          </ul>
          
          <div style="text-align: center;">
            <a href="#{assigns.security_link}" class="button">Verificar Configurações de Segurança</a>
          </div>
          
          <p>Se você não reconhece esta atividade, recomendamos que entre em contato com nosso suporte imediatamente.</p>
          
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
  Renderiza o template de texto plano para um email de notificação de segurança.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:user_name` - Nome do usuário
    - `:event_type` - Tipo de evento de segurança
    - `:event_details` - Detalhes do evento (mapa)
    - `:event_time` - Data e hora do evento
    - `:security_link` - Link para as configurações de segurança
    - `:severity` - Nível de severidade (alta, média, baixa)
    - `:recommendations` - Lista de recomendações para o usuário
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
    
    # Gera os itens da lista de recomendações
    recommendations_text = assigns.recommendations
    |> Enum.map(fn rec -> "- #{rec}" end)
    |> Enum.join("\n")
    
    """
    NOTIFICAÇÃO DE SEGURANÇA: #{String.upcase(assigns.event_type)} - #{assigns.app_name}
    
    Olá, #{assigns.user_name}!
    
    Gostaríamos de informá-lo sobre um evento de segurança recente relacionado à sua conta no #{assigns.app_name}.
    
    SEVERIDADE: #{String.upcase(assigns.severity)}
    DATA E HORA: #{assigns.event_time}
    
    DETALHES DO EVENTO:
    Evento: #{assigns.event_type}
    Descrição: #{assigns.event_details.description}
    Localização: #{assigns.event_details.location}
    Endereço IP: #{assigns.event_details.ip}
    
    RECOMENDAÇÕES:
    #{recommendations_text}
    
    Para verificar suas configurações de segurança, acesse:
    #{assigns.security_link}
    
    Se você não reconhece esta atividade, recomendamos que entre em contato com nosso suporte imediatamente.
    
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
