defmodule Deeper_Hub.Core.Data.Pagination do
  @moduledoc """
  Provides pagination functionality for Mnesia tables and lists.
  """

  alias Deeper_Hub.Core.Data.Repository

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
    page = Map.get(params, :page, 1)
    page_size = Map.get(params, :page_size, 10)

    total_items = length(items)
    total_pages = if page_size > 0, do: ceil(total_items / page_size) |> max(0), else: 0
    actual_total_pages = if total_items == 0, do: 0, else: max(1, total_pages)

    start_index = (page - 1) * page_size
    # end_index = start_index + page_size - 1 # Not needed with Enum.slice/3

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
  Paginate Mnesia table results.

  Uses `Deeper_Hub.Core.Data.Repository.all/1` to fetch all records first.

  ## Parameters

  - table: Mnesia table name (atom)
  - params: Pagination parameters (see `paginate_list/2`)

  ## Examples

      iex> Deeper_Hub.Core.Data.Pagination.paginate_mnesia(:users, %{page: 1, page_size: 1})
      # Assuming one user record exists
      %{
        entries: [{:users, ...}],
        page_number: 1,
        page_size: 1,
        total_entries: 1,
        total_pages: 1
      }

      iex> Deeper_Hub.Core.Data.Pagination.paginate_mnesia(:non_existent_table, %{})
      %{
        entries: [],
        page_number: 1,
        page_size: 10,
        total_entries: 0,
        total_pages: 0
      }
  """
  @spec paginate_mnesia(atom(), pagination_params()) :: pagination_result(tuple())
  def paginate_mnesia(table, params \\ %{}) when is_atom(table) do
    case Repository.all(table) do
      {:ok, all_records} ->
        paginate_list(all_records, params)

      {:error, reason} ->
        # If Repository.all fails (e.g., table does not exist after all fixes),
        # treat as an empty list for pagination purposes.
        # Alternatively, could propagate the error: {:error, {:pagination_failed, reason}}
        Deeper_Hub.Core.Logger.warning(
          "Failed to fetch records from table '#{table}' for pagination. Treating as empty.",
          %{module: __MODULE__, error: reason}
        )

        paginate_list([], params)
    end
  end
end
