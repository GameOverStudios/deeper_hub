defmodule DeeperHub.Core.Data.Crud do
  @moduledoc """
  Provides generic CRUD (Create, Read, Update, Delete) operations 
  for database tables, abstracting SQL query construction.

  This module relies on `DeeperHub.Core.Data.Repo` for query execution.
  It assumes table names are strings and primary keys are typically 'id'.
  Input `params` and `conditions` are expected to be maps.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Inserts a new record into the specified table.

  Returns `{:ok, record_map}` with the inserted record (if `RETURNING *` is supported 
  and used) or `{:error, reason}`.

  ## Examples

      Crud.create("users", %{name: "Alice", email: "alice@example.com"})
      #=> {:ok, %{"id" => 1, "name" => "Alice", "email" => "alice@example.com", ...}}
  """
  def create(table, params) when is_binary(table) and is_map(params) do
    if map_size(params) == 0 do
      Logger.warn("Crud.create called with empty params for table '#{table}'.", module: __MODULE__)
      {:error, :empty_params}
    else
      columns = params |> Map.keys() |> Enum.map(&Atom.to_string/1) # Convert atoms to strings if they are keys
      placeholders = Enum.map(1..length(columns), &"$#{&1}")
      values = Map.values(params)

      sql = "INSERT INTO #{table} (#{Enum.join(columns, ", ")}) VALUES (#{Enum.join(placeholders, ", ")}) RETURNING *"
      
      Logger.debug("Crud.create SQL: #{sql} with values: #{inspect(values)}", module: __MODULE__)
      
      case Repo.query(sql, values) do
        {:ok, [%{} = inserted_record | _]} -> 
          # SQLite often returns a list with one item for RETURNING *
          {:ok, inserted_record}
        {:ok, %{rows: [inserted_record | _]}} -> # Exqlite might wrap in rows key
           {:ok, inserted_record}
        {:ok, %{rows: []}} -> # Insert might not have returned anything (e.g. table without PK or RETURNING not fully supported for edge cases)
            Logger.warn("Crud.create for table '#{table}' did not return a record.", module: __MODULE__)
            {:error, :creation_failed_no_return} # Or perhaps {:ok, nil} depending on desired contract
        {:error, reason} -> 
          {:error, reason}
        other -> 
          Logger.error("Crud.create received unexpected result from Repo.query for table '#{table}': #{inspect(other)}", module: __MODULE__)
          {:error, {:unexpected_repo_result, other}}
      end
    end
  end

  @doc """
  Retrieves a single record from the table by its primary key (assumed to be 'id').

  Returns `{:ok, record_map}` if found, `{:error, :not_found}` if not found, 
  or `{:error, reason}` for other errors.
  """
  def get(table, id) when is_binary(table) do
    sql = "SELECT * FROM #{table} WHERE id = $1 LIMIT 1"
    Logger.debug("Crud.get SQL: #{sql} with id: #{id}", module: __MODULE__)
    
    case Repo.query(sql, [id]) do
      {:ok, [%{} = record | _]} -> {:ok, record}
      {:ok, %{rows: [record | _]}} -> {:ok, record}
      {:ok, %{rows: []}} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
      other -> 
        Logger.error("Crud.get received unexpected result from Repo.query for table '#{table}': #{inspect(other)}", module: __MODULE__)
        {:error, {:unexpected_repo_result, other}}
    end
  end

  @doc """
  Lists all records from a table. Optionally filters by conditions.
  (Filtering and options like limit/order to be implemented more robustly later)
  """
  def list(table, conditions \\ %{}, _opts \\ []) when is_binary(table) do
    # Basic implementation without sophisticated condition parsing yet
    # This will be expanded to build a proper WHERE clause.
    if map_size(conditions) > 0 do
      Logger.warn("Crud.list called with conditions, but condition parsing is not fully implemented yet for table '#{table}'. Fetching all.", module: __MODULE__)
    end
    sql = "SELECT * FROM #{table}"
    Logger.debug("Crud.list SQL: #{sql} for table '#{table}'", module: __MODULE__)

    Repo.query(sql, []) # Repo.query should return {:ok, list_of_maps} or {:error, ...}
  end

  @doc """
  Updates a record in the table identified by `id` with the given `params`.

  Returns `{:ok, updated_record_map}` or `{:error, reason}`.
  Returns `{:error, :not_found}` if no record was updated (e.g., ID does not exist).
  """
  def update(table, id, params) when is_binary(table) and is_map(params) do
    if map_size(params) == 0 do
      Logger.warn("Crud.update called with empty params for table '#{table}', id: #{id}.", module: __MODULE__)
      {:error, :empty_params}
    else
      columns_to_update = params |> Map.keys() |> Enum.map(&Atom.to_string/1)
      set_clauses = Enum.map_join(1..length(columns_to_update), ", ", fn i ->
        "#{columns_to_update[i-1]} = $#{i}"
      end)
      values = Map.values(params) ++ [id] # Add id as the last parameter for WHERE clause
      id_placeholder_index = length(columns_to_update) + 1

      sql = "UPDATE #{table} SET #{set_clauses} WHERE id = $#{id_placeholder_index} RETURNING *"
      Logger.debug("Crud.update SQL: #{sql} with values: #{inspect(values)}", module: __MODULE__)

      case Repo.query(sql, values) do
        {:ok, [%{} = updated_record | _]} -> {:ok, updated_record}
        {:ok, %{rows: [updated_record | _]}} -> {:ok, updated_record}
        {:ok, %{rows: []}} -> {:error, :not_found} # No rows updated/returned
        {:error, reason} -> {:error, reason}
        other -> 
          Logger.error("Crud.update received unexpected result from Repo.query for table '#{table}': #{inspect(other)}", module: __MODULE__)
          {:error, {:unexpected_repo_result, other}}
      end
    end
  end

  @doc """
  Deletes a record from the table by its primary key (assumed to be 'id').

  Returns `{:ok, deleted_record_map}` if `RETURNING *` is effective, 
  `{:ok, %{num_rows: 1}}` if deletion was successful but no record returned,
  `{:error, :not_found}` if no record was deleted, or `{:error, reason}`.
  """
  def delete(table, id) when is_binary(table) do
    sql = "DELETE FROM #{table} WHERE id = $1 RETURNING *"
    Logger.debug("Crud.delete SQL: #{sql} with id: #{id}", module: __MODULE__)

    case Repo.query(sql, [id]) do
      {:ok, [%{} = deleted_record | _]} -> {:ok, deleted_record} # RETURNING * worked
      {:ok, %{rows: [deleted_record | _]}} -> {:ok, deleted_record}
      {:ok, %{rows: [], num_rows: 0}} -> {:error, :not_found}
      {:ok, %{num_rows: 1}} -> {:ok, %{num_rows: 1}} # Deleted, but nothing returned by RETURNING *
      {:ok, result_map} when result_map.num_rows == 1 -> {:ok, result_map} # Generic case if num_rows is 1
      {:error, reason} -> {:error, reason}
      other -> 
        Logger.error("Crud.delete received unexpected result from Repo.query for table '#{table}': #{inspect(other)}", module: __MODULE__)
        {:error, {:unexpected_repo_result, other}}
    end
  end

  # TODO:
  # - Implement get_by/2, list/3 (with proper condition parsing and options)
  # - Implement update_by/3, delete_by/2
  # - Helper function for building WHERE clauses from maps more robustly.
  # - Helper function for handling different primary key names.
  # - More robust error handling and result parsing from Repo.
end
