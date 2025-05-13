defmodule Deeper_Hub.Core.Metrics.MetricsConfig do
  @moduledoc """
  Configuração do sistema de métricas do DeeperHub.
  
  Este módulo define as configurações padrão para o sistema de métricas
  e fornece funções para obter e modificar essas configurações.
  """
  
  @doc """
  Retorna as configurações padrão para o sistema de métricas.
  
  ## Retorno
  
  Um mapa com as seguintes chaves:
    - `:enabled`: Se o sistema de métricas está habilitado
    - `:export_interval`: Intervalo em milissegundos para exportação de relatórios
    - `:export_format`: Formato de exportação dos relatórios
    - `:export_path`: Caminho para salvar os relatórios exportados
  """
  @spec default_config() :: map()
  def default_config do
    %{
      enabled: true,
      export_interval: 3_600_000, # 1 hora
      export_format: :json,
      export_path: "logs/metrics"
    }
  end
  
  @doc """
  Carrega a configuração do sistema de métricas a partir do ambiente.
  
  ## Retorno
  
  Um mapa com as configurações carregadas, combinando os valores padrão
  com os valores definidos no ambiente.
  """
  @spec load_config() :: map()
  def load_config do
    defaults = default_config()
    
    %{
      enabled: get_env_bool(:metrics_enabled, defaults.enabled),
      export_interval: get_env_int(:metrics_export_interval, defaults.export_interval),
      export_format: get_env_atom(:metrics_export_format, defaults.export_format),
      export_path: get_env_string(:metrics_export_path, defaults.export_path)
    }
  end
  
  # Funções auxiliares para obter valores do ambiente
  
  defp get_env_bool(key, default) do
    case System.get_env(to_string(key)) do
      "true" -> true
      "false" -> false
      nil -> default
      _ -> default
    end
  end
  
  defp get_env_int(key, default) do
    case System.get_env(to_string(key)) do
      nil -> default
      value ->
        case Integer.parse(value) do
          {int, _} -> int
          :error -> default
        end
    end
  end
  
  defp get_env_atom(key, default) do
    case System.get_env(to_string(key)) do
      nil -> default
      value ->
        try do
          String.to_existing_atom(value)
        rescue
          _ -> default
        end
    end
  end
  
  defp get_env_string(key, default) do
    System.get_env(to_string(key)) || default
  end
end
