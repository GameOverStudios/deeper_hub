defmodule Deeper_Hub.Core.Data.Pagination do
  @moduledoc """
  Fornece funcionalidade de paginação para tabelas Mnesia e listas.
  
  Este módulo implementa mecanismos para paginar resultados de consultas, permitindo
  a exibição de dados em páginas com tamanho configurável. Suporta tanto listas
  comuns quanto tabelas Mnesia.
  
  ## Características
  
  - Paginação de listas com tamanho de página configurável
  - Paginação de tabelas Mnesia com tratamento de erros
  - Cálculo automático de total de páginas e entradas
  - Tratamento robusto de casos de borda (listas vazias, valores inválidos)
  
  ## Uso Básico
  
  ```elixir
  # Paginar uma lista
  result = Pagination.paginate_list([1, 2, 3, 4, 5], %{page: 1, page_size: 2})
  # => %{entries: [1, 2], page_number: 1, page_size: 2, total_entries: 5, total_pages: 3}
  
  # Paginar uma tabela Mnesia
  result = Pagination.paginate_mnesia(:users, %{page: 2, page_size: 10})
  # => %{entries: [...], page_number: 2, page_size: 10, total_entries: 25, total_pages: 3}
  ```
  """

  alias Deeper_Hub.Core.Data.Repository
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Metrics.DatabaseMetrics

  @typedoc "Parameters for pagination, including page number and page size."
  @type pagination_params ::
          %{
            page: pos_integer(),
            page_size: pos_integer()
          }
          | %{}

  @typedoc "The result of a pagination operation."
  @type pagination_result(item_type) :: %{
          entries: list(item_type),
          page_number: pos_integer(),
          page_size: pos_integer(),
          total_entries: non_neg_integer(),
          total_pages: non_neg_integer()
        }

  @doc """
  Paginate a list of items.

  ## Parameters

  - items: List of items to paginate
  - params: Pagination parameters
    - page: The page number (default: 1)
    - page_size: Number of items per page (default: 10)

  ## Examples

      iex> Deeper_Hub.Core.Data.Pagination.paginate_list([1, 2, 3, 4, 5], %{page: 2, page_size: 2})
      %{
        entries: [3, 4],
        page_number: 2,
        page_size: 2,
        total_entries: 5,
        total_pages: 3
      }
  """
  @spec paginate_list(list(any()), pagination_params()) :: pagination_result(any())
  def paginate_list(items, params \\ %{}) do
    # Inicia a métrica de operação
    start_time = DatabaseMetrics.start_operation(:pagination, :paginate_list)
    
    page = Map.get(params, :page, 1)
    page_size = Map.get(params, :page_size, 10)
    total_items = length(items)
    
    # Tratar page_size menor ou igual a zero
    result = if page_size <= 0 do
      build_empty_pagination_result(page, page_size, total_items)
    else
      build_pagination_result(items, page, page_size, total_items)
    end
    
    # Registra o tamanho do resultado
    DatabaseMetrics.record_result_size(:pagination, :paginate_list, length(result.entries))
    
    # Registra a conclusão da operação
    DatabaseMetrics.complete_operation(:pagination, :paginate_list, :success, start_time)
    
    result
  end
  
  @doc false
  defp build_empty_pagination_result(page, page_size, total_items) do
    %{
      entries: [],
      page_number: page,
      page_size: page_size,
      total_entries: total_items,
      total_pages: 0
    }
  end
  
  @doc false
  defp build_pagination_result(items, page, page_size, total_items) do
    # Cálculo normal para page_size válido
    total_pages = ceil(total_items / page_size) |> max(0)
    actual_total_pages = if total_items == 0, do: 0, else: max(1, total_pages)

    start_index = (page - 1) * page_size
    paginated_items = Enum.slice(items, start_index, page_size)

    %{
      entries: paginated_items,
      page_number: page,
      page_size: page_size,
      total_entries: total_items,
      total_pages: actual_total_pages
    }
  end

  @doc """
  Pagina resultados de uma tabela Mnesia.

  Utiliza `Deeper_Hub.Core.Data.Repository.all/1` para buscar todos os registros primeiro.

  ## Parâmetros

  - `table`: O átomo da tabela Mnesia a ser paginada
  - `params`: Parâmetros de paginação
    - `:page`: Número da página (padrão: 1)
    - `:page_size`: Número de itens por página (padrão: 10)

  ## Retorno

  Retorna uma estrutura de paginação contendo:
  - `entries`: Lista de registros da página atual
  - `page_number`: Número da página atual
  - `page_size`: Tamanho da página
  - `total_entries`: Total de registros em todas as páginas
  - `total_pages`: Total de páginas

  ## Tratamento de Erros

  Se a tabela não existir ou ocorrer algum erro ao acessar os dados, o método
  retorna uma estrutura de paginação vazia (sem registros) e registra o erro.

  ## Exemplos

      iex> Deeper_Hub.Core.Data.Pagination.paginate_mnesia(:users, %{page: 1, page_size: 5})
      %{
        entries: [...],
        page_number: 1,
        page_size: 5,
        total_entries: 15,
        total_pages: 3
      }

      # Se a tabela não existir, retorna uma estrutura de paginação vazia
      iex> Deeper_Hub.Core.Data.Pagination.paginate_mnesia(:nonexistent_table, %{page: 1, page_size: 5})
      %{
        entries: [],
        page_number: 1,
        page_size: 5,
        total_entries: 0,
        total_pages: 0
      }
  """
  @spec paginate_mnesia(atom(), pagination_params()) :: pagination_result(tuple())
  def paginate_mnesia(table, params \\ %{}) when is_atom(table) do
    # Inicia a métrica de operação
    start_time = DatabaseMetrics.start_operation(table, :paginate_mnesia)
    
    result = case fetch_records_for_pagination(table) do
      {:ok, records} -> 
        # Registra o tamanho total dos registros antes da paginação
        DatabaseMetrics.record_result_size(table, :paginate_mnesia_total, length(records))
        paginate_list(records, params)
      {:error, reason} -> 
        # Registra o erro
        DatabaseMetrics.complete_operation(table, :paginate_mnesia, :error, start_time)
        paginate_list([], params)
    end
    
    # Registra o tamanho do resultado paginado
    DatabaseMetrics.record_result_size(table, :paginate_mnesia_page, length(result.entries))
    
    # Registra a conclusão da operação (se não foi registrada como erro)
    if result.total_entries > 0 do
      DatabaseMetrics.complete_operation(table, :paginate_mnesia, :success, start_time)
    end
    
    result
  end
  
  @doc false
  defp fetch_records_for_pagination(table) do
    case Repository.all(table) do
      {:ok, records} -> {:ok, records}
      {:error, reason} -> 
        log_pagination_error(table, reason)
        {:error, reason}
    end
  end
  
  @doc false
  defp log_pagination_error(table, reason) do
    Deeper_Hub.Core.Logger.warning(
      "Failed to fetch records from table '#{table}' for pagination. Treating as empty.",
      %{module: __MODULE__, error: reason}
    )
  end
end
