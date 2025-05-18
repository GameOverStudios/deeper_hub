defmodule Deeper_Hub.Core.WebSockets.Security.XssProtection do
  @moduledoc """
  Proteção contra ataques XSS (Cross-Site Scripting) para WebSockets.

  Este módulo implementa mecanismos para prevenir ataques XSS em mensagens WebSocket,
  sanitizando conteúdo e validando dados recebidos.
  """

  alias Deeper_Hub.Core.Logger

  @doc """
  Sanitiza uma mensagem para prevenir ataques XSS.

  ## Parâmetros

    - `message`: Mensagem a ser sanitizada

  ## Retorno

    - `{:ok, sanitized_message}` se a sanitização for bem-sucedida
    - `{:error, reason}` se a mensagem contiver conteúdo malicioso
  """
  def sanitize_message(message) when is_map(message) do
    try do
      sanitized = sanitize_map(message)
      {:ok, sanitized}
    rescue
      e ->
        Logger.error("Erro ao sanitizar mensagem", %{
          module: __MODULE__,
          error: inspect(e)
        })

        {:error, "Erro ao sanitizar mensagem"}
    end
  end

  def sanitize_message(message) when is_binary(message) do
    try do
      sanitized = sanitize_string(message)
      {:ok, sanitized}
    rescue
      e ->
        Logger.error("Erro ao sanitizar string", %{
          module: __MODULE__,
          error: inspect(e)
        })

        {:error, "Erro ao sanitizar string"}
    end
  end

  def sanitize_message(message) when is_list(message) do
    try do
      sanitized = sanitize_list(message)
      {:ok, sanitized}
    rescue
      e ->
        Logger.error("Erro ao sanitizar lista", %{
          module: __MODULE__,
          error: inspect(e)
        })

        {:error, "Erro ao sanitizar lista"}
    end
  end

  def sanitize_message(message) do
    {:ok, message}
  end

  @doc """
  Verifica se uma mensagem contém potenciais ataques XSS.

  ## Parâmetros

    - `message`: Mensagem a ser verificada

  ## Retorno

    - `{:ok, message}` se a mensagem for segura
    - `{:error, reason}` se a mensagem contiver conteúdo malicioso
  """
  def check_for_xss(message) when is_binary(message) do
    xss_patterns = [
      ~r/<script\b[^>]*>(.*?)<\/script>/i,
      ~r/javascript:/i,
      ~r/on\w+\s*=/i,
      ~r/<iframe\b[^>]*>(.*?)<\/iframe>/i,
      ~r/data:text\/html/i,
      ~r/expression\s*\(/i,
      ~r/eval\s*\(/i
    ]

    case Enum.find(xss_patterns, fn pattern -> Regex.match?(pattern, message) end) do
      nil ->
        {:ok, message}

      pattern ->
        Logger.warn("Possível ataque XSS detectado", %{
          module: __MODULE__,
          pattern: inspect(pattern),
          message_sample: String.slice(message, 0..100)
        })

        {:error, "Conteúdo potencialmente malicioso detectado"}
    end
  end

  def check_for_xss(message) when is_map(message) do
    # Verifica cada valor no mapa recursivamente
    Enum.reduce_while(message, {:ok, message}, fn {_key, value}, acc ->
      case check_value_for_xss(value) do
        {:ok, _} -> {:cont, acc}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  def check_for_xss(message) when is_list(message) do
    # Verifica cada item na lista recursivamente
    Enum.reduce_while(message, {:ok, message}, fn item, acc ->
      case check_value_for_xss(item) do
        {:ok, _} -> {:cont, acc}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  def check_for_xss(message) do
    {:ok, message}
  end

  # Funções privadas para sanitização

  defp sanitize_map(map) when is_map(map) do
    # Sanitiza cada valor do mapa
    Enum.into(map, %{}, fn {key, value} ->
      sanitized_value = case value do
        string when is_binary(string) ->
          # Primeiro, escapar as tags HTML para preservar o formato escapado
          sanitized = string
          |> String.replace("<", "&lt;")
          |> String.replace(">", "&gt;")
          |> String.replace("\"", "&quot;")
          |> String.replace("'", "&#x27;")
          |> String.replace("(", "&#40;")
          |> String.replace(")", "&#41;")
          |> String.replace(":", "&#58;")

          # Depois, remover outros padrões perigosos
          remove_dangerous_patterns(sanitized)
        _ ->
          sanitize_value(value)
      end

      {key, sanitized_value}
    end)
  end

  defp sanitize_list(list) when is_list(list) do
    # Sanitiza cada elemento da lista
    Enum.map(list, fn item ->
      case item do
        string when is_binary(string) ->
          # Primeiro, escapar as tags HTML para preservar o formato escapado
          sanitized = string
          |> String.replace("<", "&lt;")
          |> String.replace(">", "&gt;")
          |> String.replace("\"", "&quot;")
          |> String.replace("'", "&#x27;")
          |> String.replace("(", "&#40;")
          |> String.replace(")", "&#41;")
          |> String.replace(":", "&#58;")

          # Depois, remover outros padrões perigosos
          remove_dangerous_patterns(sanitized)
        _ ->
          sanitize_value(item)
      end
    end)
  end

  defp sanitize_string(string) when is_binary(string) do
    # Primeiro, escapar as tags HTML para preservar o formato escapado
    sanitized = string
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#x27;")
    |> String.replace("(", "&#40;")
    |> String.replace(")", "&#41;")
    |> String.replace(":", "&#58;")

    # Depois, remover outros padrões perigosos
    remove_dangerous_patterns(sanitized)
  end

  # Remove padrões perigosos conhecidos antes da sanitização de caracteres
  defp remove_dangerous_patterns(string) do
    # Aplica uma série de substituições para remover padrões perigosos
    # Importante: a ordem das substituições importa
    string
    # Sanitiza completamente tags script
    |> String.replace(~r/<script/i, "&lt;script")
    |> String.replace(~r/script>/i, "script&gt;")
    # Remove atributos de eventos como onclick, onerror
    |> String.replace(~r/on\w+\s*=/i, "data-removed=")
    # Remove protocolos javascript:
    |> String.replace(~r/javascript:/i, "removed:")
    # Remove funções perigosas
    |> String.replace(~r/eval\s*\(/i, "removed(")
    |> String.replace(~r/document\.cookie/i, "removed.cookie")
    |> String.replace(~r/document\.write/i, "removed.write")
    # Remove outras funções potencialmente perigosas
    |> String.replace(~r/alert\s*\(/i, "removed(")
    |> String.replace(~r/prompt\s*\(/i, "removed(")
    |> String.replace(~r/confirm\s*\(/i, "removed(")
  end

  defp sanitize_value(value) when is_map(value), do: sanitize_map(value)
  defp sanitize_value(value) when is_list(value), do: sanitize_list(value)
  defp sanitize_value(value) when is_binary(value), do: sanitize_string(value)
  defp sanitize_value(value), do: value

  # Funções privadas para verificação de XSS

  defp check_value_for_xss(value) when is_binary(value), do: check_for_xss(value)
  defp check_value_for_xss(value) when is_map(value), do: check_for_xss(value)
  defp check_value_for_xss(value) when is_list(value), do: check_for_xss(value)
  defp check_value_for_xss(_value), do: {:ok, nil}
end
