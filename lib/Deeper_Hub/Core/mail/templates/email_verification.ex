defmodule DeeperHub.Core.Mail.Templates.EmailVerification do
  @moduledoc """
  Template de email para verificação de endereço de email.
  """

  alias DeeperHub.Core.Mail.Templates.Base

  @doc """
  Gera o email de verificação de endereço de email.

  ## Parâmetros
    * `user` - Dados do usuário
    * `verification_token` - Token de verificação
    * `opts` - Opções adicionais

  ## Retorno
    * Mapa com subject, html_body e text_body
  """
  def render(user, verification_token, opts \\ []) do
    %{
      subject: "Verifique seu endereço de email - DeeperHub",
      html_body: html_body(user, verification_token, opts),
      text_body: text_body(user, verification_token, opts)
    }
  end

  defp html_body(user, verification_token, opts) do
    verification_url = build_verification_url(verification_token, opts)

    content = """
    <div class="verification-message">
      <h2>Olá, #{user.username}! 📧</h2>

      <p>Obrigado por se registrar no DeeperHub! Para completar seu cadastro e garantir a segurança da sua conta, precisamos verificar seu endereço de email.</p>

      <div class="alert alert-info">
        <strong>Importante:</strong> Este link de verificação expira em 24 horas por motivos de segurança.
      </div>

      <div style="text-align: center; margin: 30px 0;">
        <a href="#{verification_url}" class="btn">Verificar Meu Email</a>
      </div>

      <p>Se o botão acima não funcionar, você pode copiar e colar o seguinte link no seu navegador:</p>
      <p style="word-break: break-all; background-color: #f8f9fa; padding: 10px; border-radius: 4px; font-family: monospace;">
        #{verification_url}
      </p>

      <div class="alert alert-warning">
        <strong>Não solicitou esta verificação?</strong><br>
        Se você não criou uma conta no DeeperHub, pode ignorar este email com segurança. Sua conta não será ativada sem a verificação.
      </div>

      <h3>🔒 Por que verificamos emails?</h3>
      <ul>
        <li>Garantir que você tenha acesso ao email fornecido</li>
        <li>Proteger sua conta contra uso não autorizado</li>
        <li>Permitir recuperação de senha quando necessário</li>
        <li>Enviar notificações importantes sobre sua conta</li>
      </ul>

      <p>Após a verificação, você terá acesso completo a todos os recursos do DeeperHub!</p>
    </div>
    """

    Base.render_html("Verificação de Email", content, Keyword.put(opts, :user_id, user.id))
  end

  defp text_body(user, verification_token, opts) do
    verification_url = build_verification_url(verification_token, opts)

    content = """
    Olá, #{user.username}!

    Obrigado por se registrar no DeeperHub! Para completar seu cadastro e garantir a segurança da sua conta, precisamos verificar seu endereço de email.

    IMPORTANTE: Este link de verificação expira em 24 horas por motivos de segurança.

    Para verificar seu email, acesse o seguinte link:
    #{verification_url}

    Não solicitou esta verificação?
    Se você não criou uma conta no DeeperHub, pode ignorar este email com segurança. Sua conta não será ativada sem a verificação.

    Por que verificamos emails?
    - Garantir que você tenha acesso ao email fornecido
    - Proteger sua conta contra uso não autorizado
    - Permitir recuperação de senha quando necessário
    - Enviar notificações importantes sobre sua conta

    Após a verificação, você terá acesso completo a todos os recursos do DeeperHub!
    """

    Base.render_text("Verificação de Email", content)
  end

  defp build_verification_url(token, opts) do
    base_url = Application.get_env(:deeper_hub, :base_url, "https://example.com")
    "#{base_url}/auth/verify-email?token=#{token}"
  end
end
