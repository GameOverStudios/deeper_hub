defmodule DeeperHub.Core.Logger do
  @moduledoc """
  Implementação interna do Logger do DeeperHub.

  Este módulo contém a implementação dos métodos de logging,
  com suporte a mensagens coloridas e logs estruturados.
  """

  # Evita redefinição do módulo durante hot reloads
  unless Module.defines?(DeeperHub.Core.Logger, {:__info__, 1}) do
    alias DeeperHub.Core.Logger.Config.Colors

    @doc """
    Registra uma mensagem de log no nível DEBUG.

    ## Parâmetros
      * `message` - A mensagem a ser registrada
      * `metadata` - Mapa com metadados adicionais para o log
    """
    def debug(message, metadata \\ %{}) do
      log(:debug, message, metadata)
    end

    @doc """
    Registra uma mensagem de log no nível INFO.

    ## Parâmetros
      * `message` - A mensagem a ser registrada
      * `metadata` - Mapa com metadados adicionais para o log
    """
    def info(message, metadata \\ %{}) do
      log(:info, message, metadata)
    end

    @doc """
    Registra uma mensagem de log no nível WARN.

    ## Parâmetros
      * `message` - A mensagem a ser registrada
      * `metadata` - Mapa com metadados adicionais para o log
    """
    def warn(message, metadata \\ %{}) do
      log(:warn, message, metadata)
    end

    @doc """
    Registra uma mensagem de log no nível ERROR.

    ## Parâmetros
      * `message` - A mensagem a ser registrada
      * `metadata` - Mapa com metadados adicionais para o log
    """
    def error(message, metadata \\ %{}) do
      log(:error, message, metadata)
    end

    @doc """
    Registra uma mensagem de log no nível CRITICAL.

    ## Parâmetros
      * `message` - A mensagem a ser registrada
      * `metadata` - Mapa com metadados adicionais para o log
    """
    def critical(message, metadata \\ %{}) do
      log(:critical, message, metadata)
    end

    # Função interna para processar e enviar logs.
    defp log(level, message, metadata) do
      # Adiciona metadados relevantes
      enriched_metadata = enrich_metadata(metadata)

      # Delega para o Logger do Elixir
      # Mapeia nossos níveis para os níveis do Logger do Elixir
      elixir_level = map_level_to_elixir(level)

      # Simplificado - passamos a mensagem diretamente para evitar duplicação
      require Logger
      Logger.log(elixir_level, message, enriched_metadata)
    end

    # Obtém o módulo chamador da função de log
    defp get_caller_module do
      case Process.info(self(), :current_stacktrace) do
        {:current_stacktrace, stacktrace} ->
          # Procura por uma chamada de função fora deste módulo
          Enum.find_value(stacktrace, "UnknownModule", fn
            {module, _function, _arity, _location} ->
              if module != __MODULE__ and module != DeeperHub.Core.Logger do
                module
              else
                false
              end
          end)
        _ -> "UnknownModule"
      end
    end

    # Adiciona metadados padrão como timestamp, pid, etc.
    defp enrich_metadata(metadata) do
      Map.merge(%{
        module: inspect(get_caller_module()),
        level: metadata[:level]
      }, metadata)
    end

    # Mapeia nossos níveis para os níveis do Logger do Elixir
    defp map_level_to_elixir(:debug), do: :debug
    defp map_level_to_elixir(:info), do: :info
    defp map_level_to_elixir(:warn), do: :warning
    defp map_level_to_elixir(:error), do: :error
    defp map_level_to_elixir(:critical), do: :error  # Elixir logger não tem critical
  end
end
