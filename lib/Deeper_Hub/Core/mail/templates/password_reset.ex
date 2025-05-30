defmodule DeeperHub.Core.Mail.Templates.PasswordReset do
  @moduledoc """
  Template de email para reset de senha.
  """

  alias DeeperHub.Core.Mail.Templates.Base

  @doc """
  Gera o email de reset de senha.

  ## Parâmetros
    * `user` - Dados do usuário
    * `reset_token` - Token de reset
    * `opts` - Opções adicionais

  ## Retorno
    * Mapa com subject, html_body e text_body
  """
  def render(user, reset_token, opts \\ []) do
    %{
      subject: "Redefinir sua senha - DeeperHub",
      html_body: html_body(user, reset_token, opts),
      text_body: text_body(user, reset_token, opts)
    }
  end

  defp html_body(user, reset_token, opts) do
    reset_url = build_reset_url(reset_token, opts)

    content = """
    <div class="password-reset-message">
      <h2>Olá, #{user.username}! 🔐</h2>

      <p>Recebemos uma solicitação para redefinir a senha da sua conta no DeeperHub.</p>

      <div class="alert alert-warning">
        <strong>Atenção:</strong> Este link de redefinição expira em 1 hora por motivos de segurança.
      </div>

      <div style="text-align: center; margin: 30px 0;">
        <a href="#{reset_url}" class="btn">Redefinir Minha Senha</a>
      </div>

      <p>Se o botão acima não funcionar, você pode copiar e colar o seguinte link no seu navegador:</p>
      <p style="word-break: break-all; background-color: #f8f9fa; padding: 10px; border-radius: 4px; font-family: monospace;">
        #{reset_url}
      </p>

      <div class="alert alert-danger">
        <strong>Não solicitou esta redefinição?</strong><br>
        Se você não solicitou a redefinição de senha, ignore este email. Sua senha atual permanecerá inalterada.
        Por segurança, recomendamos que você verifique sua conta e considere alterar sua senha.
      </div>

      <h3>🛡️ Dicas de Segurança:</h3>
      <ul>
        <li>Use uma senha forte com pelo menos 12 caracteres</li>
        <li>Inclua letras maiúsculas, minúsculas, números e símbolos</li>
        <li>Não reutilize senhas de outras contas</li>
        <li>Considere usar um gerenciador de senhas</li>
        <li>Ative a autenticação de dois fatores quando disponível</li>
      </ul>

      <p>Se você continuar tendo problemas para acessar sua conta, entre em contato com nosso suporte.</p>
    </div>
    """

    Base.render_html("Redefinir Senha", content, Keyword.put(opts, :user_id, user.id))
  end

  defp text_body(user, reset_token, opts) do
    reset_url = build_reset_url(reset_token, opts)

    content = """
    Olá, #{user.username}!

    Recebemos uma solicitação para redefinir a senha da sua conta no DeeperHub.

    ATENÇÃO: Este link de redefinição expira em 1 hora por motivos de segurança.

    Para redefinir sua senha, acesse o seguinte link:
    #{reset_url}

    Não solicitou esta redefinição?
    Se você não solicitou a redefinição de senha, ignore este email. Sua senha atual permanecerá inalterada.
    Por segurança, recomendamos que você verifique sua conta e considere alterar sua senha.

    Dicas de Segurança:
    - Use uma senha forte com pelo menos 12 caracteres
    - Inclua letras maiúsculas, minúsculas, números e símbolos
    - Não reutilize senhas de outras contas
    - Considere usar um gerenciador de senhas
    - Ative a autenticação de dois fatores quando disponível

    Se você continuar tendo problemas para acessar sua conta, entre em contato com nosso suporte.
    """

    Base.render_text("Redefinir Senha", content)
  end

  defp build_reset_url(token, opts) do
    base_url = Application.get_env(:deeper_hub, :base_url, "https://example.com")
    "#{base_url}/auth/reset-password?token=#{token}"
  end
end
