# lib/deeper_hub/core/logger/logger.ex
defmodule DeeperHub.Core.Logger do
  @moduledoc """
  Módulo responsável pelo sistema de logging centralizado do DeeperHub.
  Ele fornece funcionalidades para registrar mensagens de log em diferentes níveis,
  com formatação customizável e integração com diferentes coletores de log (sinks).

  Este módulo implementa macros para cada nível de log (:debug, :info, :warn, :error, :critical)
  que capturam automaticamente o módulo chamador e aplicam formatação consistente.

  Características principais:
  - Formatação colorida para melhor visualização no console
  - Inclusão automática de data e nome do módulo
  - Respeito ao nível de log configurado globalmente
  - Suporte a metadados adicionais para enriquecer as mensagens de log

  Exemplo de uso:
  ```elixir
  require DeeperHub.Core.Logger

  DeeperHub.Core.Logger.info("Iniciando operação", user_id: "123")
  DeeperHub.Core.Logger.error("Falha na operação", error: err, operation: :process_data)
  ```
  """

  require Logger
  import IO.ANSI

  @doc """
  Registra uma mensagem de log no nível :debug.
  A mensagem incluirá a data, o nome do módulo chamador e será colorida.

  ## Parâmetros
    * `message` - Mensagem a ser registrada (string ou qualquer estrutura que possa ser convertida com inspect)
    * `metadata` - Lista de palavras-chave com metadados adicionais (opcional)

  ## Retorno
    * `:ok` - Operação bem-sucedida

  ## Exemplos

      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.debug("Mensagem de debug")
      :ok
      
      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.debug("Detalhes da operação", user_id: "123", operation: :query)
      :ok
  """
  @spec debug(any(), keyword()) :: :ok
  defmacro debug(message, metadata \\ []) do
    caller_module_atom = __CALLER__.module

    quote do
      DeeperHub.Core.Logger.__log__(
        :debug,
        unquote(message),
        Keyword.put(unquote(metadata), :module, unquote(caller_module_atom))
      )
    end
  end

  @doc """
  Registra uma mensagem de log no nível :info.
  A mensagem incluirá a data, o nome do módulo chamador e será colorida.

  ## Parâmetros
    * `message` - Mensagem a ser registrada (string ou qualquer estrutura que possa ser convertida com inspect)
    * `metadata` - Lista de palavras-chave com metadados adicionais (opcional)

  ## Retorno
    * `:ok` - Operação bem-sucedida

  ## Exemplos

      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.info("Mensagem informativa")
      :ok
      
      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.info("Usuário autenticado", user_id: "123", ip: "192.168.1.1")
      :ok
  """
  @spec info(any(), keyword()) :: :ok
  defmacro info(message, metadata \\ []) do
    caller_module_atom = __CALLER__.module

    quote do
      DeeperHub.Core.Logger.__log__(
        :info,
        unquote(message),
        Keyword.put(unquote(metadata), :module, unquote(caller_module_atom))
      )
    end
  end

  @doc """
  Registra uma mensagem de log no nível :warn.
  A mensagem incluirá a data, o nome do módulo chamador e será colorida.

  ## Parâmetros
    * `message` - Mensagem a ser registrada (string ou qualquer estrutura que possa ser convertida com inspect)
    * `metadata` - Lista de palavras-chave com metadados adicionais (opcional)

  ## Retorno
    * `:ok` - Operação bem-sucedida

  ## Exemplos

      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.warn("Alerta importante")
      :ok
      
      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.warn("Tentativa suspeita de login", user_id: "123", ip: "203.0.113.1")
      :ok
  """
  @spec warn(any(), keyword()) :: :ok
  defmacro warn(message, metadata \\ []) do
    caller_module_atom = __CALLER__.module

    quote do
      DeeperHub.Core.Logger.__log__(
        :warn,
        unquote(message),
        Keyword.put(unquote(metadata), :module, unquote(caller_module_atom))
      )
    end
  end

  @doc """
  Registra uma mensagem de log no nível :error.
  A mensagem incluirá a data, o nome do módulo chamador e será colorida.

  ## Parâmetros
    * `message` - Mensagem a ser registrada (string ou qualquer estrutura que possa ser convertida com inspect)
    * `metadata` - Lista de palavras-chave com metadados adicionais (opcional)

  ## Retorno
    * `:ok` - Operação bem-sucedida

  ## Exemplos

      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.error("Ocorreu um erro grave")
      :ok
      
      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.error("Falha na conexão com o banco de dados", error: err, operation: :save_user)
      :ok
  """
  @spec error(any(), keyword()) :: :ok
  defmacro error(message, metadata \\ []) do
    caller_module_atom = __CALLER__.module

    quote do
      DeeperHub.Core.Logger.__log__(
        :error,
        unquote(message),
        Keyword.put(unquote(metadata), :module, unquote(caller_module_atom))
      )
    end
  end

  @doc """
  Registra uma mensagem de log no nível :critical.
  Este nível é usado para erros que exigem atenção imediata.
  A mensagem incluirá a data, o nome do módulo chamador e será colorida.

  ## Parâmetros
    * `message` - Mensagem a ser registrada (string ou qualquer estrutura que possa ser convertida com inspect)
    * `metadata` - Lista de palavras-chave com metadados adicionais (opcional)

  ## Retorno
    * `:ok` - Operação bem-sucedida

  ## Exemplos

      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.critical("Falha crítica no sistema!")
      :ok
      
      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.critical("Servidor indisponível", service: :authentication, impact: :high)
      :ok
  """
  @spec critical(any(), keyword()) :: :ok
  defmacro critical(message, metadata \\ []) do
    caller_module_atom = __CALLER__.module

    quote do
      DeeperHub.Core.Logger.__log__(
        :critical,
        unquote(message),
        Keyword.put(unquote(metadata), :module, unquote(caller_module_atom))
      )
    end
  end

  # --- Funções Privadas ---

  # Função de log interna, não deve ser chamada diretamente.
  # É prefixada com __ para indicar seu uso interno pelas macros.
  @doc false
  @spec __log__(atom(), any(), keyword()) :: :ok
  def __log__(level, message_content, metadata) do
    try do
      # Respeita o nível de log configurado globalmente
      if Logger.compare_levels(level, Logger.level()) != :lt do
        # Adiciona timestamp com horário para logs mais precisos
        datetime = DateTime.utc_now()
        date_str = datetime |> DateTime.to_date() |> Date.to_string()
        time_str = datetime |> DateTime.to_time() |> Time.to_string() |> String.slice(0, 8)
        timestamp = "#{date_str} #{time_str}"

        # Extrai informações do módulo
        module_name_atom = metadata[:module] || :UnknownModule
        module_name_str = Atom.to_string(module_name_atom)

        # Configuração de cores
        date_color = yellow()
        module_text_color = blue() <> bright()
        reset = reset()

        level_message_color_map = %{
          :debug => cyan(),
          :info => green(),
          # Alterado de amarelo para magenta para diferenciar da data
          :warn => magenta(),
          :error => red(),
          :critical => red() <> bright()
        }

        # Usa default se nível desconhecido
        message_color = Map.get(level_message_color_map, level, default_color())

        # Formata os metadados adicionais, se houver
        metadata_str =
          if Enum.empty?(metadata) or Keyword.keys(metadata) == [:module] do
            ""
          else
            metadata_without_module = Keyword.delete(metadata, :module)
            " " <> inspect(metadata_without_module)
          end

        # Monta a mensagem de log completa
        log_parts = [
          date_color,
          timestamp,
          reset,
          " ",
          "[",
          module_text_color,
          module_name_str,
          reset,
          "]",
          " ",
          message_color,
          formatar_conteudo_mensagem(message_content),
          reset,
          metadata_str
        ]

        IO.puts(log_parts)
      end

      :ok
    rescue
      e ->
        # Fallback para garantir que erros no sistema de log não derrubem a aplicação
        IO.puts("[LOGGER ERROR] Falha ao registrar log: #{Exception.message(e)}")
        :ok
    end
  end

  @doc false
  @spec formatar_conteudo_mensagem(any()) :: String.t()
  defp formatar_conteudo_mensagem(message) when is_binary(message), do: message
  defp formatar_conteudo_mensagem(message), do: inspect(message, pretty: true, limit: 5000)
end
