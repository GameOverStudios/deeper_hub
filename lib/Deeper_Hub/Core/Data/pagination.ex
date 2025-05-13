defmodule Deeper_Hub.Core.Data.Pagination do
  @moduledoc """
  Provides pagination functionality for Mnesia tables and lists.
  """

  @doc """
  Paginate a list of items.

  ## Parameters

  - items: List of items to paginate
  - params: Pagination parameters
    - page: The page number (default: 1)
    - page_size: Number of items per page (default: 10)

  ## Examples

      iex> Deeper_Hub.Core.Data.Pagination.paginate_list([1, 2, 3, 4, 5], %{page: 2, page_size: 2})
  """
  def paginate_list(items, params \\ %{}) do
    page = Map.get(params, :page, 1)
    page_size = Map.get(params, :page_size, 10)

    total_items = length(items)
    total_pages = ceil(total_items / page_size)

    start_index = (page - 1) * page_size
    end_index = start_index + page_size - 1

    paginated_items = Enum.slice(items, start_index..end_index)

    %{
      entries: paginated_items,
      page_number: page,
      page_size: page_size,
      total_entries: total_items,
      total_pages: total_pages
    }
  end

  @doc """
  Paginate Mnesia table results.

  ## Parameters

  - table: Mnesia table name
  - params: Pagination parameters

  ## Examples

      iex> Deeper_Hub.Core.Data.Pagination.paginate_mnesia(:users, %{page: 2, page_size: 10})
  """
  def paginate_mnesia(table, params \\ %{}) do
    page = Map.get(params, :page, 1)
    page_size = Map.get(params, :page_size, 10)

    # Fetch all records from the Mnesia table
    {:atomic, all_records} = :mnesia.transaction(fn ->
      :mnesia.select(table, [{{table, :'$1'}, [], [:'$1']}])
    end)

    total_items = length(all_records)
    total_pages = ceil(total_items / page_size)

    start_index = (page - 1) * page_size
    end_index = start_index + page_size - 1

    paginated_items = Enum.slice(all_records, start_index..end_index)

    %{
      entries: paginated_items,
      page_number: page,
      page_size: page_size,
      total_entries: total_items,
      total_pages: total_pages
    }
  end
end
