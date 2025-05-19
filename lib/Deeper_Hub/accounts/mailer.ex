defmodule DeeperHub.Accounts.Mailer do
  @moduledoc """
  Módulo para envio de e-mails no DeeperHub.
  
  Este módulo fornece funções para enviar e-mails para usuários do sistema.
  Atualmente implementa uma versão simplificada que apenas registra os e-mails
  no log do sistema. Em produção, deve ser substituído por uma implementação
  que utilize um serviço de e-mail real.
  """
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Envia um e-mail para o destinatário especificado.
  
  ## Parâmetros
    * `to` - Endereço de e-mail do destinatário
    * `subject` - Assunto do e-mail
    * `body` - Corpo do e-mail
    
  ## Retorno
    * `:ok` - Se o e-mail for enviado com sucesso
    * `{:error, reason}` - Se ocorrer um erro ao enviar o e-mail
  """
  @spec send_email(String.t(), String.t(), String.t()) :: :ok | {:error, any()}
  def send_email(to, subject, body) do
    # Em ambiente de desenvolvimento, apenas registra o e-mail no log
    if Mix.env() == :dev do
      Logger.info("E-mail enviado para: #{to}", 
        module: __MODULE__,
        email: %{
          to: to,
          subject: subject,
          body: body
        }
      )
      :ok
    else
      # Em produção, deve utilizar um serviço de e-mail real
      # Exemplo: enviar via SMTP, SendGrid, AWS SES, etc.
      # Por enquanto, apenas registra no log
      Logger.info("E-mail enviado para: #{to}", 
        module: __MODULE__,
        email: %{
          to: to,
          subject: subject
        }
      )
      :ok
    end
  rescue
    error ->
      Logger.error("Erro ao enviar e-mail: #{inspect(error)}", 
        module: __MODULE__,
        to: to,
        subject: subject
      )
      {:error, error}
  end
end
