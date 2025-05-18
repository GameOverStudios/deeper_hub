# lib/deeper_hub/core/logger/logger.ex
defmodule DeeperHub.Core.Logger do
  @moduledoc """
  Módulo responsável pelo sistema de logging centralizado do DeeperHub.
  Ele fornece funcionalidades para registrar mensagens de log em diferentes níveis,
  com formatação customizável e integração com diferentes coletores de log (sinks).
  """

  require Logger
  import IO.ANSI

  @doc """
  Registra uma mensagem de log no nível :debug.
  A mensagem incluirá a data, o nome do módulo chamador e será colorida.

  ## Examples

      iex> DeeperHub.Core.Logger.debug("Mensagem de debug")
      :ok
  """
  defmacro debug(message, metadata \\ []) do
    caller_module_atom = __CALLER__.module
    quote do
      DeeperHub.Core.Logger.__log__(:debug, unquote(message), Keyword.put(unquote(metadata), :module, unquote(caller_module_atom)))
    end
  end

  @doc """
  Registra uma mensagem de log no nível :info.
  A mensagem incluirá a data, o nome do módulo chamador e será colorida.

  ## Examples

      iex> DeeperHub.Core.Logger.info("Mensagem informativa")
      :ok
  """
  defmacro info(message, metadata \\ []) do
    caller_module_atom = __CALLER__.module
    quote do
      DeeperHub.Core.Logger.__log__(:info, unquote(message), Keyword.put(unquote(metadata), :module, unquote(caller_module_atom)))
    end
  end

  @doc """
  Registra uma mensagem de log no nível :warn.
  A mensagem incluirá a data, o nome do módulo chamador e será colorida.

  ## Examples

      iex> DeeperHub.Core.Logger.warn("Alerta importante")
      :ok
  """
  defmacro warn(message, metadata \\ []) do
    caller_module_atom = __CALLER__.module
    quote do
      DeeperHub.Core.Logger.__log__(:warn, unquote(message), Keyword.put(unquote(metadata), :module, unquote(caller_module_atom)))
    end
  end

  @doc """
  Registra uma mensagem de log no nível :error.
  A mensagem incluirá a data, o nome do módulo chamador e será colorida.

  ## Examples

      iex> DeeperHub.Core.Logger.error("Ocorreu um erro grave")
      :ok
  """
  defmacro error(message, metadata \\ []) do
    caller_module_atom = __CALLER__.module
    quote do
      DeeperHub.Core.Logger.__log__(:error, unquote(message), Keyword.put(unquote(metadata), :module, unquote(caller_module_atom)))
    end
  end

  @doc """
  Registra uma mensagem de log no nível :critical.
  Este nível é usado para erros que exigem atenção imediata.
  A mensagem incluirá a data, o nome do módulo chamador e será colorida.

  ## Examples

      iex> DeeperHub.Core.Logger.critical("Falha crítica no sistema!")
      :ok
  """
  defmacro critical(message, metadata \\ []) do
    caller_module_atom = __CALLER__.module
    quote do
      DeeperHub.Core.Logger.__log__(:critical, unquote(message), Keyword.put(unquote(metadata), :module, unquote(caller_module_atom)))
    end
  end

  # --- Funções Privadas ---

  # Função de log interna, não deve ser chamada diretamente.
  # É prefixada com __ para indicar seu uso interno pelas macros.
  @doc false
  def __log__(level, message_content, metadata) do
    # Respeita o nível de log configurado globalmente
    if Logger.compare_levels(level, Logger.level()) != :lt do
      date_str = Date.utc_today() |> Date.to_string()
      module_name_atom = metadata[:module] || :UnknownModule
      module_name_str = Atom.to_string(module_name_atom)

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

      log_parts = [
        date_color,
        date_str,
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
        reset
      ]

      IO.puts(log_parts)
    end

    :ok
  end

  @doc false
  defp formatar_conteudo_mensagem(message) when is_binary(message), do: message
  defp formatar_conteudo_mensagem(message), do: inspect(message)
end
