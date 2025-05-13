defmodule DeeperHub.Core.Logger do
  @moduledoc """
  Implementação interna do Logger do DeeperHub.

  Este módulo contém a implementação dos métodos de logging,
  com suporte a mensagens coloridas e logs estruturados.
  """

  alias DeeperHub.Core.Logger.Config.Colors

  # Códigos ANSI para cores
  @ansi_codes %{
    black: "\e[30m",
    red: "\e[31m",
    green: "\e[32m",
    yellow: "\e[33m",
    blue: "\e[34m",
    magenta: "\e[35m",
    cyan: "\e[36m",
    white: "\e[37m",
    bright: "\e[1m",
    reset: "\e[0m"
  }

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
    # Obtém o módulo chamador
    caller_module = get_caller_module()
    # Formata a mensagem com cores
    formatted_message = format_message(level, caller_module, message)
    # Adiciona timestamp e outros metadados padrão
    enriched_metadata = enrich_metadata(metadata)

    # Delega para o Logger do Elixir
    # Mapeia nossos níveis para os níveis do Logger do Elixir
    elixir_level = map_level_to_elixir(level)

    require Logger
    Logger.log(elixir_level, formatted_message, enriched_metadata)
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

  # Formata a mensagem com cores para o console
  defp format_message(level, module, message) do
    # Obtém as configurações de cores
    colors = Colors.get_colors()

    # Formata o nome do módulo colorido
    formatted_module = format_with_color(inspect(module), colors.module_color)
    # Formata o nível colorido
    level_color = get_in(colors, [:level_colors, level]) || colors.default_color
    formatted_level = format_with_color(String.upcase("#{level}"), level_color)

    # Adiciona timestamp com cor
    timestamp = DateTime.utc_now() |> DateTime.to_string()
    formatted_timestamp = format_with_color(timestamp, colors.timestamp_color)

    # Combina tudo na mensagem final
    "#{formatted_timestamp} [#{formatted_module}] [#{formatted_level}] #{message}"
  end

  # Aplica as cores ao texto
  defp format_with_color(text, colors) when is_list(colors) do
    color_codes = Enum.map(colors, fn color -> @ansi_codes[color] end) |> Enum.join("")
    "#{color_codes}#{text}#{@ansi_codes.reset}"
  end

  defp format_with_color(text, color) when is_atom(color) do
    "#{@ansi_codes[color]}#{text}#{@ansi_codes.reset}"
  end

  # Adiciona metadados padrão como timestamp, pid, etc.
  defp enrich_metadata(metadata) do
    Map.merge(%{
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      pid: inspect(self()),
      module: inspect(get_caller_module())
    }, metadata)
  end

  # Mapeia nossos níveis para os níveis do Logger do Elixir
  defp map_level_to_elixir(:debug), do: :debug
  defp map_level_to_elixir(:info), do: :info
  defp map_level_to_elixir(:warn), do: :warning
  defp map_level_to_elixir(:error), do: :error
  defp map_level_to_elixir(:critical), do: :error  # Elixir logger não tem critical
end
