defmodule DeeperHub.Core.Mail.Templates do
  @moduledoc """
  Módulo para gerenciamento de templates de email no DeeperHub.
  
  Este módulo fornece funções para renderização de templates de email,
  tanto em formato HTML quanto texto plano, utilizando os templates
  definidos no diretório de templates.
  """
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
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
    
    # Formata a data/hora
    timestamp = format_timestamp(Map.get(assigns, :timestamp, DateTime.utc_now()))
    
    # Prepara os assigns com valores padrão
    assigns = Map.merge(%{
      app_name: "DeeperHub",
      alert_type: "Alerta de Segurança",
      alert_message: "Foi detectado um evento de segurança no sistema.",
      alert_details: %{},
      severity: severity,
      severity_color: get_severity_color(severity),
      timestamp: timestamp,
      current_year: DateTime.utc_now().year,
      support_email: get_support_email()
    }, assigns)
    
    # Renderiza os templates HTML e texto
    html = render_security_alert_html(assigns)
    text = render_security_alert_text(assigns)
    
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
    
    # Renderiza os templates HTML e texto
    html = render_welcome_html(assigns)
    text = render_welcome_text(assigns)
    
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
    
    # Renderiza os templates HTML e texto
    html = render_password_reset_html(assigns)
    text = render_password_reset_text(assigns)
    
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
    
    # Renderiza um template genérico
    html = render_fallback_html(assigns)
    text = render_fallback_text(assigns)
    
    {html, text}
  end
  
  #
  # Implementações de templates HTML
  #
  
  # Template HTML para alerta de segurança
  defp render_security_alert_html(assigns) do
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
  
  # Template HTML para boas-vindas
  defp render_welcome_html(assigns) do
    verification_section = if assigns.verification_url do
      """
      <div style="margin: 30px 0; text-align: center;">
        <a href="#{assigns.verification_url}" style="background-color: #4CAF50; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold;">Verificar meu email</a>
      </div>
      <p>Ou copie e cole o link abaixo no seu navegador:</p>
      <p><a href="#{assigns.verification_url}">#{assigns.verification_url}</a></p>
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
          
          <p>Estamos muito felizes em ter você como parte da nossa comunidade!</p>
          
          <p>Sua conta foi criada com sucesso e você já pode começar a utilizar todas as funcionalidades do #{assigns.app_name}.</p>
          
          #{verification_section}
          
          <p>Se você tiver qualquer dúvida ou precisar de ajuda, não hesite em entrar em contato com nossa equipe de suporte.</p>
          
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
  
  # Template HTML para redefinição de senha
  defp render_password_reset_html(assigns) do
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
          
          <p>Para criar uma nova senha, clique no botão abaixo:</p>
          
          <div style="margin: 30px 0; text-align: center;">
            <a href="#{assigns.reset_url}" class="button">Redefinir minha senha</a>
          </div>
          
          <p>Ou copie e cole o link abaixo no seu navegador:</p>
          <p><a href="#{assigns.reset_url}">#{assigns.reset_url}</a></p>
          
          <p>Este link expirará em <strong>#{assigns.expiration_hours} horas</strong>.</p>
          
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
  
  # Template HTML genérico para fallback
  defp render_fallback_html(assigns) do
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
          
          <p>Template solicitado: <code>#{assigns.template_name}</code></p>
          
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
  
  #
  # Implementações de templates texto
  #
  
  # Template texto para alerta de segurança
  defp render_security_alert_text(assigns) do
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
  
  # Template texto para boas-vindas
  defp render_welcome_text(assigns) do
    verification_section = if assigns.verification_url do
      """
      Para verificar seu email, acesse o link abaixo:
      #{assigns.verification_url}
      """
    else
      ""
    end
    
    """
    Bem-vindo ao #{assigns.app_name}!
    
    Olá #{assigns.username},
    
    Estamos muito felizes em ter você como parte da nossa comunidade!
    
    Sua conta foi criada com sucesso e você já pode começar a utilizar todas as funcionalidades do #{assigns.app_name}.
    
    #{verification_section}
    
    Se você tiver qualquer dúvida ou precisar de ajuda, não hesite em entrar em contato com nossa equipe de suporte.
    
    Atenciosamente,
    Equipe #{assigns.app_name}
    
    --
    © #{assigns.current_year} #{assigns.app_name}. Todos os direitos reservados.
    Para suporte, contate #{assigns.support_email}
    """
  end
  
  # Template texto para redefinição de senha
  defp render_password_reset_text(assigns) do
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
  
  # Template texto genérico para fallback
  defp render_fallback_text(assigns) do
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
