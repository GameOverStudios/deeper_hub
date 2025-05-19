defmodule DeeperHub.Core.Mail.Templates.SecurityAlert do
  @moduledoc """
  Template de email para alertas de segurança.
  
  Este módulo fornece funções para renderizar templates de email
  para alertas de segurança, tanto em formato HTML quanto texto plano.
  """
  
  @doc """
  Renderiza o template HTML para um alerta de segurança.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:alert_type` - Tipo de alerta
    - `:alert_message` - Mensagem do alerta
    - `:alert_details` - Detalhes adicionais do alerta
    - `:severity` - Severidade do alerta (:info, :warning, :critical)
    - `:timestamp` - Data/hora do alerta
  
  ## Retorno
  
  - String HTML do template renderizado
  """
  def render_html(assigns) do
    # Obtém a severidade ou usa o padrão
    severity = Map.get(assigns, :severity, :warning)
    
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      alert_type: "Alerta de Segurança",
      alert_message: "Foi detectado um evento de segurança no sistema.",
      alert_details: %{},
      severity: severity,
      severity_color: get_severity_color(severity),
      timestamp: format_timestamp(Map.get(assigns, :timestamp, DateTime.utc_now())),
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>#{assigns.alert_type} - #{assigns.app_name}</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #{assigns.severity_color}; color: white; padding: 10px 20px; border-radius: 5px 5px 0 0; }
        .content { border: 1px solid #ddd; border-top: none; padding: 20px; border-radius: 0 0 5px 5px; }
        .footer { margin-top: 20px; font-size: 12px; color: #777; text-align: center; }
        .alert-details { background-color: #f9f9f9; padding: 10px; border-left: 4px solid #{assigns.severity_color}; margin: 10px 0; }
        h1 { margin: 0; font-size: 22px; }
        h2 { font-size: 18px; margin-top: 20px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>#{assigns.alert_type}</h1>
        </div>
        <div class="content">
          <p>Foi detectado um evento de segurança no sistema <strong>#{assigns.app_name}</strong>:</p>
          
          <div class="alert-details">
            <p><strong>Mensagem:</strong> #{assigns.alert_message}</p>
            <p><strong>Severidade:</strong> #{format_severity(assigns.severity)}</p>
            <p><strong>Data/Hora:</strong> #{assigns.timestamp}</p>
            
            #{render_details_html(assigns.alert_details)}
          </div>
          
          <p>Por favor, verifique o sistema e tome as medidas necessárias.</p>
          
          <p>Se você não reconhece esta atividade, entre em contato com o suporte imediatamente.</p>
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
  Renderiza o template de texto plano para um alerta de segurança.
  
  ## Parâmetros
  
  - `assigns` - Variáveis para renderização do template
    - `:alert_type` - Tipo de alerta
    - `:alert_message` - Mensagem do alerta
    - `:alert_details` - Detalhes adicionais do alerta
    - `:severity` - Severidade do alerta (:info, :warning, :critical)
    - `:timestamp` - Data/hora do alerta
  
  ## Retorno
  
  - String de texto plano do template renderizado
  """
  def render_text(assigns) do
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      alert_type: "Alerta de Segurança",
      alert_message: "Foi detectado um evento de segurança no sistema.",
      alert_details: %{},
      severity: :warning,
      timestamp: format_timestamp(Map.get(assigns, :timestamp, DateTime.utc_now())),
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    """
    #{assigns.alert_type} - #{assigns.app_name}
    
    Foi detectado um evento de segurança no sistema #{assigns.app_name}:
    
    Mensagem: #{assigns.alert_message}
    Severidade: #{format_severity(assigns.severity)}
    Data/Hora: #{assigns.timestamp}
    
    #{render_details_text(assigns.alert_details)}
    
    Por favor, verifique o sistema e tome as medidas necessárias.
    
    Se você não reconhece esta atividade, entre em contato com o suporte imediatamente.
    
    --
    © #{assigns.current_year} #{assigns.app_name}. Todos os direitos reservados.
    Para suporte, contate #{assigns.support_email}
    """
  end
  
  #
  # Funções auxiliares
  #
  
  # Renderiza os detalhes do alerta em HTML
  defp render_details_html(details) when is_map(details) and map_size(details) == 0, do: ""
  defp render_details_html(details) when is_map(details) do
    details_html = Enum.map(details, fn {key, value} ->
      "<p><strong>#{format_key(key)}:</strong> #{format_value(value)}</p>"
    end)
    |> Enum.join("\n")
    
    """
    <h2>Detalhes adicionais:</h2>
    #{details_html}
    """
  end
  defp render_details_html(_), do: ""
  
  # Renderiza os detalhes do alerta em texto
  defp render_details_text(details) when is_map(details) and map_size(details) == 0, do: ""
  defp render_details_text(details) when is_map(details) do
    details_text = Enum.map(details, fn {key, value} ->
      "#{format_key(key)}: #{format_value(value)}"
    end)
    |> Enum.join("\n")
    
    """
    Detalhes adicionais:
    #{details_text}
    """
  end
  defp render_details_text(_), do: ""
  
  # Formata a chave para exibição
  defp format_key(key) when is_atom(key), do: key |> Atom.to_string() |> String.capitalize()
  defp format_key(key) when is_binary(key), do: String.capitalize(key)
  defp format_key(key), do: inspect(key)
  
  # Formata o valor para exibição
  defp format_value(value) when is_binary(value), do: value
  defp format_value(value) when is_number(value), do: to_string(value)
  defp format_value(value) when is_boolean(value), do: if(value, do: "Sim", else: "Não")
  defp format_value(value) when is_map(value) or is_list(value), do: inspect(value)
  defp format_value(nil), do: "-"
  defp format_value(value), do: inspect(value)
  
  # Formata a severidade para exibição
  defp format_severity(:info), do: "Informação"
  defp format_severity(:warning), do: "Alerta"
  defp format_severity(:critical), do: "CRÍTICO"
  defp format_severity(_), do: "Desconhecido"
  
  # Obtém a cor associada à severidade
  defp get_severity_color(:info), do: "#2196F3"  # Azul
  defp get_severity_color(:warning), do: "#FF9800"  # Laranja
  defp get_severity_color(:critical), do: "#F44336"  # Vermelho
  defp get_severity_color(_), do: "#607D8B"  # Cinza azulado
  
  # Formata o timestamp para exibição
  defp format_timestamp(%DateTime{} = dt) do
    # Formata como "DD/MM/YYYY HH:MM:SS UTC"
    Calendar.strftime(dt, "%d/%m/%Y %H:%M:%S %Z")
  end
  defp format_timestamp(_), do: "Data/hora desconhecida"
  
  # Obtém o email de suporte das configurações
  defp get_support_email do
    Application.get_env(:deeper_hub, :mail, [])
    |> Keyword.get(:support_email, "suporte@deeperhub.com")
  end
end
