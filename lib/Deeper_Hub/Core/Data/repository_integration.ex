defmodule Deeper_Hub.Core.Data.RepositoryIntegration do
  @moduledoc """
  Módulo de integração central para todos os componentes do repositório.
  
  Este módulo centraliza a inicialização e configuração de todos os componentes
  relacionados ao repositório, como telemetria, cache, circuit breaker e métricas.
  
  ## Uso
  
  Este módulo deve ser inicializado durante a inicialização da aplicação:
  
  ```elixir
  # No arquivo application.ex
  def start(_type, _args) do
    # Inicializa a integração do repositório com os schemas da aplicação
    Deeper_Hub.Core.Data.RepositoryIntegration.setup([
      MyApp.Schemas.User,
      MyApp.Schemas.Product,
      MyApp.Schemas.Order
    ])
    
    # ...
  end
  ```
  """
  
  alias Deeper_Hub.Core.Data.RepositoryTelemetry
  alias Deeper_Hub.Core.Data.RepositoryCache
  alias Deeper_Hub.Core.Data.RepositoryCircuitBreaker
  alias Deeper_Hub.Core.Data.RepositoryMetrics
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Cache.CacheFacade, as: Cache
  
  @doc """
  Inicializa todos os componentes do repositório para os schemas fornecidos.
  
  Esta função deve ser chamada durante a inicialização da aplicação para
  garantir que todos os componentes estejam configurados corretamente.
  
  ## Parâmetros
  
  - `schemas` - Lista de schemas Ecto para os quais configurar os componentes
  
  ## Retorno
  
  - `:ok` - Se todos os componentes forem inicializados com sucesso
  """
  def setup(schemas) when is_list(schemas) do
    Logger.info("Inicializando componentes do repositório", %{
      module: __MODULE__,
      schemas: Enum.map(schemas, &inspect/1)
    })
    
    # Inicializa telemetria
    RepositoryTelemetry.setup()
    
    # Inicializa métricas
    RepositoryMetrics.setup()
    
    # Inicializa cache
    RepositoryCache.setup(schemas)
    
    # Inicializa circuit breaker
    RepositoryCircuitBreaker.setup(schemas)
    
    Logger.info("Componentes do repositório inicializados com sucesso", %{
      module: __MODULE__,
      schemas: Enum.map(schemas, &inspect/1)
    })
    
    :ok
  end
  
  @doc """
  Reinicia todos os componentes do repositório para os schemas fornecidos.
  
  Esta função pode ser chamada para reiniciar os componentes em caso de
  problemas ou para aplicar novas configurações.
  
  ## Parâmetros
  
  - `schemas` - Lista de schemas Ecto para os quais reiniciar os componentes
  
  ## Retorno
  
  - `:ok` - Se todos os componentes forem reiniciados com sucesso
  """
  def restart(schemas) when is_list(schemas) do
    Logger.info("Reiniciando componentes do repositório", %{
      module: __MODULE__,
      schemas: Enum.map(schemas, &inspect/1)
    })
    
    # Limpa o cache para cada schema
    Enum.each(schemas, &RepositoryCache.invalidate_schema/1)
    
    # Reseta os circuit breakers para cada schema
    Enum.each(schemas, &RepositoryCircuitBreaker.reset/1)
    
    # Reinicializa telemetria
    RepositoryTelemetry.setup()
    
    Logger.info("Componentes do repositório reiniciados com sucesso", %{
      module: __MODULE__,
      schemas: Enum.map(schemas, &inspect/1)
    })
    
    :ok
  end
  
  @doc """
  Obtém o estado atual de todos os componentes do repositório para um schema específico.
  
  Esta função é útil para diagnóstico e monitoramento.
  
  ## Parâmetros
  
  - `schema` - O schema Ecto para o qual obter o estado
  
  ## Retorno
  
  - `map` - Um mapa contendo o estado de cada componente
  """
  def get_status(schema) do
    # Obtém o estado do circuit breaker
    read_circuit_state = RepositoryCircuitBreaker.get_read_state(schema)
    write_circuit_state = RepositoryCircuitBreaker.get_write_state(schema)
    
    # Obtém o tamanho do cache
    {:ok, record_cache_size} = Cache.size("repository:#{get_schema_name(schema)}:records")
    {:ok, query_cache_size} = Cache.size("repository:#{get_schema_name(schema)}:queries")
    
    # Retorna o estado consolidado
    %{
      schema: schema,
      circuit_breaker: %{
        read: read_circuit_state,
        write: write_circuit_state
      },
      cache: %{
        records: record_cache_size,
        queries: query_cache_size,
        total: record_cache_size + query_cache_size
      }
    }
  end
  
  # Funções privadas auxiliares
  
  # Extrai o nome do schema de um módulo ou string
  defp get_schema_name(schema) when is_atom(schema) do
    schema
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
  end
  
  defp get_schema_name(schema) when is_binary(schema) do
    schema
  end
end
