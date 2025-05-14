defmodule Deeper_Hub.Core.Data.Pagination do
  @moduledoc """
  Módulo para paginação de resultados.
  
  Este módulo fornece funções para paginar resultados de consultas ao banco de dados,
  facilitando a implementação de APIs com suporte a paginação.
  """
  
  import Ecto.Query
  alias Deeper_Hub.Core.Data.Repo
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Metrics.DatabaseMetrics
  
  @doc """
  Pagina os resultados de uma consulta.
  
  ## Parâmetros
  
    - `schema`: O módulo do schema Ecto
    - `page`: O número da página (começando em 1)
    - `page_size`: O número de registros por página
    - `filters`: Filtros adicionais para a consulta (mapa de campo => valor)
    - `opts`: Opções adicionais (como ordenação, preload, etc.)
    
  ## Retorno
  
    - `{:ok, %{items: list, total: integer, page: integer, page_size: integer, total_pages: integer}}`
    - `{:error, reason}` em caso de falha
  """
  @spec paginate(module(), integer(), integer(), map(), Keyword.t()) :: 
    {:ok, map()} | {:error, term()}
  def paginate(schema, page \\ 1, page_size \\ 10, filters \\ %{}, opts \\ []) do
    start_time = System.monotonic_time()
    
    # Registra a operação
    Logger.debug("Paginando resultados", %{
      module: __MODULE__,
      schema: schema,
      page: page,
      page_size: page_size,
      filters: filters,
      opts: opts
    })
    
    try do
      # Valida os parâmetros
      page = max(1, page)
      page_size = max(1, min(100, page_size))
      
      # Calcula o offset
      offset_value = (page - 1) * page_size
      
      # Constrói a query base
      query = from(item in schema)
      
      # Aplica os filtros
      query = Enum.reduce(filters, query, fn {field_name, field_value}, acc_query ->
        from(item in acc_query, where: field(item, ^field_name) == ^field_value)
      end)
      
      # Aplica a ordenação se fornecida
      query = if Keyword.has_key?(opts, :order_by) do
        order_by_value = Keyword.get(opts, :order_by)
        from(item in query, order_by: ^order_by_value)
      else
        query
      end
      
      # Conta o total de registros
      total_query = from(item in query, select: count(item.id))
      total = Repo.one(total_query)
      
      # Calcula o total de páginas
      total_pages = ceil(total / page_size)
      
      # Aplica a paginação
      paginated_query = query
      |> limit(^page_size)
      |> offset(^offset_value)
      
      # Executa a query paginada
      items = Repo.all(paginated_query)
      
      # Monta o resultado
      result = %{
        items: items,
        total: total,
        page: page,
        page_size: page_size,
        total_pages: total_pages
      }
      
      # Registra métricas
      DatabaseMetrics.record_operation_time(:paginate, schema, System.monotonic_time() - start_time)
      DatabaseMetrics.record_operation_result(:paginate, schema, {:ok, result})
      DatabaseMetrics.record_result_size(:paginate, schema, length(items))
      
      # Registra o resultado
      Logger.debug("Resultados paginados com sucesso", %{
        module: __MODULE__,
        schema: schema,
        page: page,
        page_size: page_size,
        total: total,
        total_pages: total_pages,
        count: length(items)
      })
      
      {:ok, result}
    rescue
      e ->
        # Registra o erro
        Logger.error("Falha ao paginar resultados", %{
          module: __MODULE__,
          schema: schema,
          page: page,
          page_size: page_size,
          filters: filters,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        # Registra métricas
        DatabaseMetrics.record_operation_time(:paginate, schema, System.monotonic_time() - start_time)
        DatabaseMetrics.record_operation_result(:paginate, schema, {:error, e})
        
        {:error, e}
    end
  end
end
