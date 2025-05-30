defmodule DeeperHub.Core.Mail.Templates.Base do
  @moduledoc """
  Template base para emails do DeeperHub.

  Este módulo fornece funcionalidades comuns para todos os templates de email,
  incluindo layout base, estilos CSS e funções utilitárias.
  """

  @doc """
  Gera o HTML base para emails com layout responsivo.

  ## Parâmetros
    * `title` - Título do email
    * `content` - Conteúdo HTML do email
    * `opts` - Opções adicionais

  ## Retorno
    * String com HTML completo do email
  """
  @spec render_html(String.t(), String.t(), keyword()) :: String.t()
  def render_html(title, content, opts \\ []) do
    """
    <!DOCTYPE html>
    <html lang="#{Keyword.get(opts, :lang, "pt-BR")}">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{title}</title>
        <style>
            #{base_css()}
        </style>
    </head>
    <body>
        <div class="email-container">
            <header class="email-header">
                <img src="#{logo_url()}" alt="DeeperHub" class="logo">
                <h1>#{title}</h1>
            </header>

            <main class="email-content">
                #{content}
            </main>

            <footer class="email-footer">
                <p>© #{Date.utc_today().year} DeeperHub. Todos os direitos reservados.</p>
                <p>
                    <a href="#{unsubscribe_url(opts)}">Cancelar inscrição</a> |
                    <a href="#{support_url()}">Suporte</a>
                </p>
            </footer>
        </div>
    </body>
    </html>
    """
  end

  @doc """
  Gera versão em texto plano do email.

  ## Parâmetros
    * `title` - Título do email
    * `content` - Conteúdo em texto do email

  ## Retorno
    * String com texto plano do email
  """
  @spec render_text(String.t(), String.t()) :: String.t()
  def render_text(title, content) do
    """
    #{title}
    #{String.duplicate("=", String.length(title))}

    #{content}

    ---
    © #{Date.utc_today().year} DeeperHub. Todos os direitos reservados.

    Para cancelar inscrição ou obter suporte, visite: #{support_url()}
    """
  end

  # CSS base para emails responsivos
  defp base_css do
    """
    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        line-height: 1.6;
        color: #333;
        margin: 0;
        padding: 0;
        background-color: #f4f4f4;
    }

    .email-container {
        max-width: 600px;
        margin: 0 auto;
        background-color: #ffffff;
        box-shadow: 0 0 10px rgba(0,0,0,0.1);
    }

    .email-header {
        background-color: #2c3e50;
        color: white;
        padding: 20px;
        text-align: center;
    }

    .logo {
        max-height: 50px;
        margin-bottom: 10px;
    }

    .email-header h1 {
        margin: 0;
        font-size: 24px;
    }

    .email-content {
        padding: 30px;
    }

    .email-footer {
        background-color: #ecf0f1;
        padding: 20px;
        text-align: center;
        font-size: 12px;
        color: #7f8c8d;
    }

    .email-footer a {
        color: #3498db;
        text-decoration: none;
    }

    .btn {
        display: inline-block;
        padding: 12px 24px;
        background-color: #3498db;
        color: white;
        text-decoration: none;
        border-radius: 4px;
        font-weight: bold;
        margin: 10px 0;
    }

    .btn:hover {
        background-color: #2980b9;
    }

    .alert {
        padding: 15px;
        margin: 20px 0;
        border-radius: 4px;
    }

    .alert-info {
        background-color: #d9edf7;
        border: 1px solid #bce8f1;
        color: #31708f;
    }

    .alert-warning {
        background-color: #fcf8e3;
        border: 1px solid #faebcc;
        color: #8a6d3b;
    }

    .alert-danger {
        background-color: #f2dede;
        border: 1px solid #ebccd1;
        color: #a94442;
    }

    @media only screen and (max-width: 600px) {
        .email-container {
            width: 100% !important;
        }

        .email-content {
            padding: 20px !important;
        }
    }
    """
  end

  # URLs configuráveis
  defp logo_url do
    Application.get_env(:deeper_hub, :email_logo_url, "https://example.com/logo.png")
  end

  defp support_url do
    Application.get_env(:deeper_hub, :support_url, "https://example.com/support")
  end

  defp unsubscribe_url(opts) do
    user_id = Keyword.get(opts, :user_id)
    base_url = Application.get_env(:deeper_hub, :base_url, "https://example.com")
    "#{base_url}/unsubscribe?user_id=#{user_id}"
  end
end
