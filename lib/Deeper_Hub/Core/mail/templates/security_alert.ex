defmodule DeeperHub.Core.Mail.Templates.SecurityAlert do
  @moduledoc """
  Template de email para alertas de segurança.
  """

  alias DeeperHub.Core.Mail.Templates.Base

  @doc """
  Gera o email de alerta de segurança.

  ## Parâmetros
    * `user` - Dados do usuário
    * `alert_type` - Tipo de alerta (:login_suspicious, :password_changed, :new_device, etc.)
    * `details` - Detalhes do evento de segurança
    * `opts` - Opções adicionais

  ## Retorno
    * Mapa com subject, html_body e text_body
  """
  def render(user, alert_type, details, opts \\ []) do
    %{
      subject: build_subject(alert_type),
      html_body: html_body(user, alert_type, details, opts),
      text_body: text_body(user, alert_type, details, opts)
    }
  end

  defp html_body(user, alert_type, details, opts) do
    {title, message, severity} = get_alert_info(alert_type, details)
    alert_class = "alert-#{severity}"

    content = """
    <div class="security-alert-message">
      <h2>Alerta de Segurança 🔒</h2>

      <p>Olá, #{user.username},</p>

      <div class="alert #{alert_class}">
        <strong>#{title}</strong><br>
        #{message}
      </div>

      <h3>📋 Detalhes do Evento:</h3>
      <ul>
        <li><strong>Data/Hora:</strong> #{format_datetime(details[:timestamp])}</li>
        <li><strong>Endereço IP:</strong> #{details[:ip_address] || "Não disponível"}</li>
        <li><strong>Localização:</strong> #{details[:location] || "Não disponível"}</li>
        <li><strong>Dispositivo:</strong> #{details[:device] || "Não disponível"}</li>
        <li><strong>Navegador:</strong> #{details[:user_agent] || "Não disponível"}</li>
      </ul>

      #{render_action_section(alert_type, opts)}

      <h3>🛡️ Medidas de Segurança Recomendadas:</h3>
      <ul>
        <li>Verifique se você reconhece esta atividade</li>
        <li>Se não foi você, altere sua senha imediatamente</li>
        <li>Ative a autenticação de dois fatores se ainda não fez</li>
        <li>Revise os dispositivos conectados à sua conta</li>
        <li>Entre em contato conosco se suspeitar de atividade maliciosa</li>
      </ul>

      <p>Se você reconhece esta atividade, pode ignorar este email com segurança.</p>

      <p><strong>Sua segurança é nossa prioridade!</strong></p>
    </div>
    """

    Base.render_html("Alerta de Segurança", content, Keyword.put(opts, :user_id, user.id))
  end

  defp text_body(user, alert_type, details, opts) do
    {title, message, _severity} = get_alert_info(alert_type, details)

    content = """
    ALERTA DE SEGURANÇA

    Olá, #{user.username},

    #{title}
    #{message}

    Detalhes do Evento:
    - Data/Hora: #{format_datetime(details[:timestamp])}
    - Endereço IP: #{details[:ip_address] || "Não disponível"}
    - Localização: #{details[:location] || "Não disponível"}
    - Dispositivo: #{details[:device] || "Não disponível"}
    - Navegador: #{details[:user_agent] || "Não disponível"}

    #{render_action_section_text(alert_type, opts)}

    Medidas de Segurança Recomendadas:
    - Verifique se você reconhece esta atividade
    - Se não foi você, altere sua senha imediatamente
    - Ative a autenticação de dois fatores se ainda não fez
    - Revise os dispositivos conectados à sua conta
    - Entre em contato conosco se suspeitar de atividade maliciosa

    Se você reconhece esta atividade, pode ignorar este email com segurança.

    Sua segurança é nossa prioridade!
    """

    Base.render_text("Alerta de Segurança", content)
  end

  defp get_alert_info(:login_suspicious, _details) do
    {"Login Suspeito Detectado", "Detectamos um login em sua conta de um local ou dispositivo não reconhecido.",
     "warning"}
  end

  defp get_alert_info(:password_changed, _details) do
    {"Senha Alterada", "A senha da sua conta foi alterada com sucesso.", "info"}
  end

  defp get_alert_info(:new_device, _details) do
    {"Novo Dispositivo Detectado", "Um novo dispositivo foi usado para acessar sua conta.", "info"}
  end

  defp get_alert_info(:multiple_failed_logins, details) do
    attempts = details[:attempts] || "várias"

    {"Múltiplas Tentativas de Login Falharam", "Detectamos #{attempts} tentativas de login malsucedidas em sua conta.",
     "danger"}
  end

  defp get_alert_info(:account_locked, _details) do
    {"Conta Temporariamente Bloqueada", "Sua conta foi temporariamente bloqueada devido a atividade suspeita.",
     "danger"}
  end

  defp get_alert_info(_, _details) do
    {"Atividade de Segurança Detectada", "Detectamos atividade relacionada à segurança em sua conta.", "warning"}
  end

  defp render_action_section(:password_changed, opts) do
    """
    <div class="alert alert-info">
      <strong>Ação Necessária:</strong> Se você não alterou sua senha,
      <a href="#{build_reset_url(opts)}">clique aqui para redefinir sua senha</a> imediatamente.
    </div>
    """
  end

  defp render_action_section(:account_locked, opts) do
    """
    <div class="alert alert-warning">
      <strong>Ação Necessária:</strong> Para desbloquear sua conta,
      <a href="#{build_unlock_url(opts)}">clique aqui</a> ou entre em contato com o suporte.
    </div>
    """
  end

  defp render_action_section(_, _opts), do: ""

  defp render_action_section_text(:password_changed, opts) do
    """
    AÇÃO NECESSÁRIA: Se você não alterou sua senha, acesse o link abaixo para redefinir sua senha imediatamente:
    #{build_reset_url(opts)}
    """
  end

  defp render_action_section_text(:account_locked, opts) do
    """
    AÇÃO NECESSÁRIA: Para desbloquear sua conta, acesse:
    #{build_unlock_url(opts)}
    """
  end

  defp render_action_section_text(_, _opts), do: ""

  defp build_subject(:login_suspicious), do: "🚨 Login suspeito detectado - DeeperHub"
  defp build_subject(:password_changed), do: "🔐 Senha alterada - DeeperHub"
  defp build_subject(:new_device), do: "📱 Novo dispositivo detectado - DeeperHub"
  defp build_subject(:multiple_failed_logins), do: "⚠️ Múltiplas tentativas de login - DeeperHub"
  defp build_subject(:account_locked), do: "🔒 Conta bloqueada - DeeperHub"
  defp build_subject(_), do: "🔒 Alerta de segurança - DeeperHub"

  defp build_reset_url(opts) do
    base_url = Application.get_env(:deeper_hub, :base_url, "https://example.com")
    "#{base_url}/auth/forgot-password"
  end

  defp build_unlock_url(opts) do
    base_url = Application.get_env(:deeper_hub, :base_url, "https://example.com")
    "#{base_url}/auth/unlock-account"
  end

  defp format_datetime(nil), do: "Não disponível"
  defp format_datetime(datetime) when is_binary(datetime), do: datetime

  defp format_datetime(%DateTime{} = datetime) do
    datetime
    |> DateTime.shift_zone!("America/Sao_Paulo")
    |> DateTime.to_string()
  end

  defp format_datetime(_), do: "Não disponível"
end
