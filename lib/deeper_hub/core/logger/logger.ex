# lib/deeper_hub/core/logger/logger.ex
defmodule DeeperHub.Core.Logger do
  @moduledoc """
  Módulo responsável pelo sistema de logging centralizado do DeeperHub.
  Ele fornece funcionalidades para registrar mensagens de log em diferentes níveis,
  com formatação customizável e integração com diferentes coletores de log (sinks).

  Este módulo implementa macros para cada nível de log (:emergency, :alert, :critical, :error, :warning, :notice, :info, :debug)
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

  # Importação direta do Logger do Elixir - não requer a si mesmo para evitar dependência circular
  alias Logger, as: ElixirLogger
  alias DeeperHub.Core.EventManager
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
      DeeperHub.Core.Logger.__log__(:debug, unquote(message), Keyword.put(unquote(metadata), :module, unquote(caller_module_atom)))
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
      DeeperHub.Core.Logger.__log__(:info, unquote(message), Keyword.put(unquote(metadata), :module, unquote(caller_module_atom)))
    end
  end

  @doc """
  Registra uma mensagem de log no nível :warning.
  A mensagem incluirá a data, o nome do módulo chamador e será colorida.

  ## Parâmetros
    * `message` - Mensagem a ser registrada (string ou qualquer estrutura que possa ser convertida com inspect)
    * `metadata` - Lista de palavras-chave com metadados adicionais (opcional)

  ## Retorno
    * `:ok` - Operação bem-sucedida

  ## Exemplos

      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.warninginging("Alerta importante")
      :ok

      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.warninginging("Tentativa suspeita de login", user_id: "123", ip: "203.0.113.1")
      :ok
  """
  @spec warning(any(), keyword()) :: :ok
  defmacro warning(message, metadata \\ []) do
    caller_module_atom = __CALLER__.module
    quote do
      DeeperHub.Core.Logger.__log__(:warning, unquote(message), Keyword.put(unquote(metadata), :module, unquote(caller_module_atom)))
    end
  end

  @doc """
  Registra uma mensagem de log no nível :warn (depreciado).
  Use `warning/2` no lugar desta função.
  A mensagem incluirá a data, o nome do módulo chamador e será colorida.

  ## Parâmetros
    * `message` - Mensagem a ser registrada (string ou qualquer estrutura que possa ser convertida com inspect)
    * `metadata` - Lista de palavras-chave com metadados adicionais (opcional)

  ## Retorno
    * `:ok` - Operação bem-sucedida
  """
  @deprecated "Use warning/2 instead"
  @spec warn(any(), keyword()) :: :ok
  defmacro warn(message, metadata \\ []) do
    caller_module_atom = __CALLER__.module
    quote do
      DeeperHub.Core.Logger.__log__(:warning, unquote(message), Keyword.put(unquote(metadata), :module, unquote(caller_module_atom)))
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
      DeeperHub.Core.Logger.__log__(:error, unquote(message), Keyword.put(unquote(metadata), :module, unquote(caller_module_atom)))
    end
  end

  @doc """
  Registra uma mensagem de log no nível :emergency.
  Este é o nível mais alto de severidade, usado quando o sistema está inutilizável.
  A mensagem incluirá a data, o nome do módulo chamador e será colorida.

  ## Parâmetros
    * `message` - Mensagem a ser registrada (string ou qualquer estrutura que possa ser convertida com inspect)
    * `metadata` - Lista de palavras-chave com metadados adicionais (opcional)

  ## Retorno
    * `:ok` - Operação bem-sucedida

  ## Exemplos

      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.emergency("Sistema completamente indisponível!")
      :ok

      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.emergency("Falha total do sistema", component: :core, action_required: :immediate_restart)
      :ok
  """
  @spec emergency(any(), keyword()) :: :ok
  defmacro emergency(message, metadata \\ []) do
    caller_module_atom = __CALLER__.module
    quote do
      DeeperHub.Core.Logger.__log__(:emergency, unquote(message), Keyword.put(unquote(metadata), :module, unquote(caller_module_atom)))
    end
  end

  @doc """
  Registra uma mensagem de log no nível :alert.
  Este nível é usado quando uma ação deve ser tomada imediatamente.
  A mensagem incluirá a data, o nome do módulo chamador e será colorida.

  ## Parâmetros
    * `message` - Mensagem a ser registrada (string ou qualquer estrutura que possa ser convertida com inspect)
    * `metadata` - Lista de palavras-chave com metadados adicionais (opcional)

  ## Retorno
    * `:ok` - Operação bem-sucedida

  ## Exemplos

      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.alert("Ação imediata necessária!")
      :ok

      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.alert("Disco quase cheio", disk_usage: "95%", action: :cleanup_required)
      :ok
  """
  @spec alert(any(), keyword()) :: :ok
  defmacro alert(message, metadata \\ []) do
    caller_module_atom = __CALLER__.module
    quote do
      DeeperHub.Core.Logger.__log__(:alert, unquote(message), Keyword.put(unquote(metadata), :module, unquote(caller_module_atom)))
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
      DeeperHub.Core.Logger.__log__(:critical, unquote(message), Keyword.put(unquote(metadata), :module, unquote(caller_module_atom)))
    end
  end

  @doc """
  Registra uma mensagem de log no nível :notice.
  Este nível é usado para condições normais mas significativas.
  A mensagem incluirá a data, o nome do módulo chamador e será colorida.

  ## Parâmetros
    * `message` - Mensagem a ser registrada (string ou qualquer estrutura que possa ser convertida com inspect)
    * `metadata` - Lista de palavras-chave com metadados adicionais (opcional)

  ## Retorno
    * `:ok` - Operação bem-sucedida

  ## Exemplos

      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.notice("Configuração atualizada")
      :ok

      iex> require DeeperHub.Core.Logger
      iex> DeeperHub.Core.Logger.notice("Usuário admin logado", user_id: "admin", ip: "192.168.1.100")
      :ok
  """
  @spec notice(any(), keyword()) :: :ok
  defmacro notice(message, metadata \\ []) do
    caller_module_atom = __CALLER__.module
    quote do
      DeeperHub.Core.Logger.__log__(:notice, unquote(message), Keyword.put(unquote(metadata), :module, unquote(caller_module_atom)))
    end
  end

  # --- Funções Privadas ---

  # Função de log interna, não deve ser chamada diretamente.
  # É prefixada com __ para indicar seu uso interno pelas macros.
  @doc false
  @spec __log__(atom(), any(), keyword()) :: :ok
  def __log__(level, message_content, metadata) do
    # Emite evento para logs de níveis importantes
    emitir_evento_log(level, message_content, metadata)
    
    # Delega para função interna
    registrar_log_interno(level, message_content, metadata)
  end
  
  # Função interna que realiza o registro do log
  @doc false
  defp registrar_log_interno(level, message_content, metadata) do
    try do
      # Verifica se o nível de log está ativo (respeita as configurações do Elixir Logger)
      if ElixirLogger.compare_levels(level, ElixirLogger.level()) != :lt do
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
          :emergency => red() <> bright() <> blink_slow(),
          :alert => red() <> bright(),
          :critical => red() <> bright(),
          :error => red(),
          # Alterado de amarelo para magenta para diferenciar da data
          :warning => magenta(),
          :notice => white() <> bright(),
          :info => green(),
          :debug => cyan()
        }

        # Usa default se nível desconhecido
        message_color = Map.get(level_message_color_map, level, default_color())

        # Formata os metadados adicionais, se houver
        metadata_str = if Enum.empty?(metadata) or Keyword.keys(metadata) == [:module] do
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

  # Emite eventos para logs importantes que podem requerer ações adicionais
  @doc false
  defp emitir_evento_log(level, message, metadata) when level in [:error, :alert, :critical, :emergency] do
    try do
      # Converte o nível para o formato do tópico de evento
      topic = String.to_atom("log_#{level}")
      
      # Prepara os dados do evento
      event_data = %{
        level: level,
        message: formatar_conteudo_mensagem(message),
        metadata: metadata,
        timestamp: :os.system_time(:millisecond)
      }
      
      # Emite o evento no barramento
      EventManager.publish(topic, event_data, "logger")
    rescue
      _ -> :ok # Ignora falhas para não comprometer a funcionalidade principal de logging
    end
  end
  
  defp emitir_evento_log(_level, _message, _metadata), do: :ok # Outros níveis não emitem eventos
end
