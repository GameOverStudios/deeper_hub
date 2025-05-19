defmodule DeeperHub.Core.Mail.Sender do
  @moduledoc """
  Módulo responsável pelo envio de emails no DeeperHub.

  Este módulo encapsula a lógica de envio de emails, permitindo
  diferentes configurações de SMTP e suporte a filas para envio
  assíncrono.
  """

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger

  @doc """
  Entrega um email usando o adaptador configurado.

  ## Parâmetros

  - `email` - Mensagem de email construída com a biblioteca Mail

  ## Retorno

  - `{:ok, message_id}` em caso de sucesso
  - `{:error, reason}` em caso de falha
  """
  def deliver(email) do
    config = get_smtp_config()

    try do
      # Renderiza o email no formato RFC2822
      rendered_email = Mail.render(email, Mail.Renderers.RFC2822)

      # Envia o email via SMTP
      result = send_smtp(config, email.from, get_all_recipients(email), rendered_email)

      # Registra o envio no log
      Logger.info("Email enviado com sucesso",
                 module: __MODULE__,
                 to: get_all_recipients(email),
                 subject: email.subject)

      result
    rescue
      e ->
        Logger.error("Erro ao enviar email: #{inspect(e)}",
                    module: __MODULE__,
                    to: get_all_recipients(email),
                    subject: email.subject)

        {:error, e}
    end
  end

  @doc """
  Entrega um email de forma assíncrona usando um processo separado.

  ## Parâmetros

  - `email` - Mensagem de email construída com a biblioteca Mail

  ## Retorno

  - `:ok` imediatamente, o envio ocorre em background
  """
  def deliver_async(email) do
    # Cria um processo para enviar o email de forma assíncrona
    Task.start(fn -> deliver(email) end)

    :ok
  end

  @doc """
  Entrega um email de forma assíncrona com retry em caso de falha.

  ## Parâmetros

  - `email` - Mensagem de email construída com a biblioteca Mail
  - `max_retries` - Número máximo de tentativas (padrão: 3)
  - `retry_delay` - Tempo de espera entre tentativas em ms (padrão: 5000)

  ## Retorno

  - `:ok` imediatamente, o envio ocorre em background
  """
  def deliver_with_retry(email, max_retries \\ 3, retry_delay \\ 5000) do
    # Cria um processo para enviar o email com retry
    Task.start(fn ->
      do_deliver_with_retry(email, max_retries, retry_delay, 0)
    end)

    :ok
  end

  #
  # Funções privadas
  #

  # Implementação do retry para envio de emails
  defp do_deliver_with_retry(_email, max_retries, _retry_delay, attempt) when attempt >= max_retries do
    {:error, :max_retries_exceeded}
  end

  defp do_deliver_with_retry(email, max_retries, retry_delay, attempt) do
    case deliver(email) do
      {:ok, message_id} ->
        {:ok, message_id}

      {:error, _reason} ->
        # Espera antes de tentar novamente
        Process.sleep(retry_delay)

        # Tenta novamente
        do_deliver_with_retry(email, max_retries, retry_delay, attempt + 1)
    end
  end

  # Obtém a configuração SMTP das configurações da aplicação
  defp get_smtp_config do
    Application.get_env(:deeper_hub, :mail, [])
    |> Keyword.get(:smtp, [])
  end

  # Extrai todos os destinatários do email (to, cc, bcc)
  defp get_all_recipients(email) do
    (email.to || []) ++ (email.cc || []) ++ (email.bcc || [])
  end

  # Envia o email via SMTP usando a biblioteca :gen_smtp_client
  defp send_smtp(config, from, to, rendered_email) do
    # Verifica se estamos em modo de teste
    if Application.get_env(:deeper_hub, :mail, []) |> Keyword.get(:test_mode, false) do
      # Em modo de teste, apenas simula o envio
      Logger.debug("Email simulado em modo de teste",
                  module: __MODULE__,
                  to: to,
                  from: from)

      {:ok, "test_message_id_#{:rand.uniform(1000000)}"}
    else
      # Em modo de produção, envia realmente o email via SMTP
      server = Keyword.get(config, :server, "localhost")
      port = Keyword.get(config, :port, 25)
      username = Keyword.get(config, :username, "")
      password = Keyword.get(config, :password, "")
      ssl = Keyword.get(config, :ssl, false)
      tls = Keyword.get(config, :tls, false)
      auth = Keyword.get(config, :auth, false)
      
      Logger.info("Enviando email via SMTP",
                  module: __MODULE__,
                  to: to,
                  from: from,
                  smtp_server: server,
                  port: port)
      
      # Prepara as opções para o gen_smtp_client
      smtp_options = [
        relay: server,
        port: port,
        username: username,
        password: password,
        ssl: ssl,
        tls: tls,
        auth: auth,
        hostname: server
      ]
      
      # Prepara os destinatários como lista
      recipients = if is_list(to), do: to, else: [to]
      
      # Envia o email usando :gen_smtp_client
      try do
        case :gen_smtp_client.send_blocking({from, recipients, rendered_email}, smtp_options) do
          {:ok, message} ->
            Logger.info("Email enviado com sucesso via SMTP",
                      module: __MODULE__,
                      to: to,
                      from: from,
                      smtp_server: server,
                      message: message)
            {:ok, message}
            
          {:error, error} ->
            Logger.error("Erro ao enviar email via SMTP: #{inspect(error)}",
                      module: __MODULE__,
                      to: to,
                      from: from,
                      smtp_server: server)
            {:error, error}
        end
      rescue
        e ->
          Logger.error("Exceção ao enviar email via SMTP: #{inspect(e)}",
                    module: __MODULE__,
                    to: to,
                    from: from,
                    smtp_server: server)
          {:error, e}
      end
    end
  end
end
