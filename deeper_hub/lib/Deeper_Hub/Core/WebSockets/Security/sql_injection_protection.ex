defmodule Deeper_Hub.Core.WebSockets.Security.SqlInjectionProtection do
  @moduledoc """
  Proteção contra ataques de SQL Injection para WebSockets.
  
  Este módulo implementa mecanismos para prevenir ataques de SQL Injection
  em mensagens WebSocket que podem conter dados destinados a consultas SQL.
  """
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Verifica se um valor contém potenciais ataques de SQL Injection.
  
  ## Parâmetros
  
    - `value`: Valor a ser verificado
  
  ## Retorno
  
    - `{:ok, value}` se o valor for seguro
    - `{:error, reason}` se o valor contiver conteúdo malicioso
  """
  def check_for_sql_injection(value) when is_binary(value) do
    sql_patterns = [
      ~r/\b(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|EXEC|UNION|WHERE)\b/i,
      ~r/--/,
      ~r/;/,
      ~r/\/\*/,
      ~r/\*\//,
      ~r/xp_/i,
      ~r/INFORMATION_SCHEMA/i,
      ~r/SLEEP\s*\(/i,
      ~r/WAITFOR\s+DELAY/i,
      ~r/BENCHMARK\s*\(/i
    ]
    
    case Enum.find(sql_patterns, fn pattern -> Regex.match?(pattern, value) end) do
      nil ->
        {:ok, value}
        
      pattern ->
        Logger.warning("Possível ataque SQL Injection detectado", %{
          module: __MODULE__,
          pattern: inspect(pattern),
          value_sample: String.slice(value, 0..100)
        })
        
        {:error, "Conteúdo potencialmente malicioso detectado"}
    end
  end
  
  def check_for_sql_injection(value) when is_map(value) do
    # Verifica cada valor no mapa recursivamente
    Enum.reduce_while(value, {:ok, value}, fn {_key, val}, acc ->
      case check_value_for_sql_injection(val) do
        {:ok, _} -> {:cont, acc}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
  
  def check_for_sql_injection(value) when is_list(value) do
    # Verifica cada item na lista recursivamente
    Enum.reduce_while(value, {:ok, value}, fn item, acc ->
      case check_value_for_sql_injection(item) do
        {:ok, _} -> {:cont, acc}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
  
  def check_for_sql_injection(value) do
    {:ok, value}
  end
  
  @doc """
  Sanitiza um valor para prevenir ataques de SQL Injection.
  
  ## Parâmetros
  
    - `value`: Valor a ser sanitizado
  
  ## Retorno
  
    - `{:ok, sanitized_value}` com o valor sanitizado
  """
  def sanitize_sql_value(value) when is_binary(value) do
    # Implementação básica de sanitização
    # Em um sistema real, seria melhor usar consultas parametrizadas
    sanitized = value
    |> String.replace("'", "''")
    |> String.replace(";", "")
    |> String.replace("--", "")
    |> String.replace("/*", "")
    |> String.replace("*/", "")
    
    {:ok, sanitized}
  end
  
  def sanitize_sql_value(value) when is_map(value) do
    sanitized = Enum.reduce(value, %{}, fn {key, val}, acc ->
      {:ok, sanitized_val} = sanitize_value_for_sql(val)
      Map.put(acc, key, sanitized_val)
    end)
    
    {:ok, sanitized}
  end
  
  def sanitize_sql_value(value) when is_list(value) do
    sanitized = Enum.map(value, fn item ->
      {:ok, sanitized_item} = sanitize_value_for_sql(item)
      sanitized_item
    end)
    
    {:ok, sanitized}
  end
  
  def sanitize_sql_value(value) do
    {:ok, value}
  end
  
  @doc """
  Prepara parâmetros para uso seguro em consultas SQL.
  
  ## Parâmetros
  
    - `query`: Consulta SQL com placeholders (?)
    - `params`: Lista de parâmetros para a consulta
  
  ## Retorno
  
    - `{:ok, {query, params}}` com a consulta e parâmetros seguros
    - `{:error, reason}` se algum parâmetro for suspeito
  """
  def prepare_query_params(query, params) when is_binary(query) and is_list(params) do
    # Verifica se a consulta contém o número correto de placeholders
    expected_params = count_placeholders(query)
    
    if length(params) != expected_params do
      {:error, "Número incorreto de parâmetros para a consulta"}
    else
      # Verifica cada parâmetro
      case Enum.reduce_while(params, [], fn param, acc ->
        case check_value_for_sql_injection(param) do
          {:ok, _} -> {:cont, [param | acc]}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end) do
        {:error, reason} -> 
          {:error, reason}
        
        params_list when is_list(params_list) ->
          {:ok, {query, Enum.reverse(params_list)}}
      end
    end
  end
  
  # Funções privadas para verificação e sanitização
  
  defp check_value_for_sql_injection(value) when is_binary(value), do: check_for_sql_injection(value)
  defp check_value_for_sql_injection(value) when is_map(value), do: check_for_sql_injection(value)
  defp check_value_for_sql_injection(value) when is_list(value), do: check_for_sql_injection(value)
  defp check_value_for_sql_injection(value), do: {:ok, value}
  
  defp sanitize_value_for_sql(value) when is_binary(value), do: sanitize_sql_value(value)
  defp sanitize_value_for_sql(value) when is_map(value), do: sanitize_sql_value(value)
  defp sanitize_value_for_sql(value) when is_list(value), do: sanitize_sql_value(value)
  defp sanitize_value_for_sql(value), do: {:ok, value}
  
  defp count_placeholders(query) do
    # Conta o número de placeholders (?) na consulta
    # Isso é uma implementação simplificada e pode não funcionar para todos os casos
    query
    |> String.graphemes()
    |> Enum.count(fn char -> char == "?" end)
  end
end
