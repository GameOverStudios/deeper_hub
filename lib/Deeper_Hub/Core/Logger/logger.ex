defmodule Deeper_Hub.Core.Logger do
  @moduledoc """
  Módulo de logging para o DeeperHub, responsável por gerenciar
  mensagens de log com suporte a diferentes níveis de severidade
  e formatação colorida.

  Segue os princípios SOLID:
  - Single Responsibility: Gerencia exclusivamente o logging
  - Open/Closed: Extensível para novos níveis de log
  - Interface segregada para diferentes tipos de log
  """

  @colors %{
    info: :green,
    warning: :yellow,
    error: :red,
    debug: :cyan,
    success: :light_green
  }

  @doc """
  Gera uma mensagem de log colorida para um determinado nível.

  ## Parâmetros
    - level: Nível do log (:info, :warning, :error, etc.)
    - message: Mensagem a ser logada
    - metadata: Metadados opcionais para enriquecer o log

  ## Retorna
    - String formatada e colorida
  """
  @spec log(atom(), String.t(), map()) :: :ok
  def log(level, message, metadata \\ %{}) do
    color = Map.get(@colors, level, :white)
    formatted_message = format_message(level, message, metadata, color)

    # Correção: Usar apply/3 para chamada dinâmica da função de cor
    colored_output = apply(IO.ANSI, color, []) <> formatted_message <> IO.ANSI.reset()
    IO.puts(colored_output)

    # Opcional: Adicionar logging em arquivo
    log_to_file(level, formatted_message)

    :ok
  end

  @doc """
  Atalhos para diferentes níveis de log
  """
  def info(message, metadata \\ %{}) do
    log(:info, message, Map.put(metadata, :module, get_caller_module()))
  end

  def warning(message, metadata \\ %{}) do
    log(:warning, message, Map.put(metadata, :module, get_caller_module()))
  end

  def error(message, metadata \\ %{}) do
    log(:error, message, Map.put(metadata, :module, get_caller_module()))
  end

  def debug(message, metadata \\ %{}) do
    log(:debug, message, Map.put(metadata, :module, get_caller_module()))
  end

  def success(message, metadata \\ %{}) do
    log(:success, message, Map.put(metadata, :module, get_caller_module()))
  end

  @spec get_caller_module() :: module()
  defp get_caller_module do
    {:current_stacktrace, stacktrace} = Process.info(self(), :current_stacktrace)

    # Procura o primeiro módulo que não seja o Logger, Process, ou Enum
    Enum.find_value(stacktrace, :unknown, fn
      {module, _function, _, _} when module not in [__MODULE__, Process, Enum] -> module
      _ -> nil
    end)
  end

  @spec format_message(atom(), String.t(), map(), atom()) :: String.t()
  defp format_message(_level, message, metadata, color) do
    timestamp = DateTime.utc_now() |> DateTime.to_time() |> Time.to_string() |> String.slice(0..7)

    # Obtém o nome do módulo que chamou o log
    module_name =
      case metadata[:module] do
        nil -> "Unknown"
        mod -> mod |> Atom.to_string() |> String.replace("Elixir.", "")
      end

    metadata_str =
      metadata
      |> Map.delete(:module)
      |> Enum.map(fn {k, v} -> "#{k}=#{inspect(v)}" end)
      |> Enum.join(" ")

    module_color = IO.ANSI.magenta()
    # Correção: Usar apply/3 para chamada dinâmica da função de cor
    message_color = apply(IO.ANSI, color, [])

    "[#{timestamp}] #{module_color}[#{module_name}]#{IO.ANSI.reset()} #{message_color}#{message}#{IO.ANSI.reset()}#{if metadata_str != "", do: " #{metadata_str}", else: ""}"
  end

  @spec log_to_file(atom(), String.t()) :: :ok
  defp log_to_file(level, message) do
    # Implementação básica de log em arquivo
    # Em um cenário real, você pode usar bibliotecas como Logger ou
    # implementar rotação de logs
    log_dir = Path.join([File.cwd!(), "logs"])
    File.mkdir_p!(log_dir)

    log_file = Path.join([log_dir, "#{level}.log"])
    File.write!(log_file, message <> "\n", [:append])
  end
end
