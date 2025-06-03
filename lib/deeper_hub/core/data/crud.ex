# <file path="deeper_hub/core/data/crud.ex">
defmodule DeeperHub.Core.Data.Crud do
  @moduledoc """
  Provides generic CRUD (Create, Read, Update, Delete) operations
  for database tables, abstracting SQL query construction.

  This module relies on `DeeperHub.Core.Data.Repo` for query execution.
  It assumes table names are strings and primary keys are typically 'id'.
  Input `params` and `conditions` are expected to be maps.
  SQLite 3.35.0+ is recommended for `RETURNING *` support.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  # Helper function to transform Exqlite result (list of lists + column names) into a list of maps
  defp transform_exqlite_result_to_maps(nil, _rows) do
    Logger.warning("transform_exqlite_result_to_maps called with nil columns.", module: __MODULE__)
    [] # Or handle as an error
  end
  defp transform_exqlite_result_to_maps(_columns, nil) do
    Logger.warning("transform_exqlite_result_to_maps called with nil rows.", module: __MODULE__)
    [] # Or handle as an error
  end
  defp transform_exqlite_result_to_maps(columns, rows) when is_list(columns) and is_list(rows) do
    Enum.map(rows, fn row_values ->
      if length(columns) == length(row_values) do
        Enum.zip(columns, row_values) |> Map.new()
      else
        Logger.error(
          "Mismatch between column count and row value count. Columns: #{inspect(columns)}, Row: #{inspect(row_values)}",
          module: __MODULE__
        )
        # Return an empty map or raise an error, depending on desired strictness
        %{}
      end
    end)
  end


  @doc """
  Inserts a new record into the specified table.

  Returns `{:ok, record_map}` with the inserted record (if `RETURNING *` is supported
  and used) or `{:error, reason}`.
  """
  @spec create(String.t(), map()) :: {:ok, map()} | {:error, any()}
  def create(table, params) when is_binary(table) and is_map(params) do
    if map_size(params) == 0 do
      Logger.warning("Crud.create called with empty params for table '#{table}'.",
        module: __MODULE__
      )
      {:error, :empty_params}
    else
      string_keyed_params =
        Enum.into(params, %{}, fn {k, v} ->
          {if(is_atom(k), do: Atom.to_string(k), else: k), v}
        end)

      columns = Map.keys(string_keyed_params)
      placeholders = Enum.map(1..length(columns), &"$#{&1}")
      values = Map.values(string_keyed_params)

      sql =
        "INSERT INTO #{table} (#{Enum.join(columns, ", ")}) VALUES (#{Enum.join(placeholders, ", ")}) RETURNING *"

      Logger.debug("Crud.create SQL: #{sql} with values: #{inspect(values)}", module: __MODULE__)

      case Repo.query(sql, values) do
        # Exqlite.Result struct contains :columns and :rows (list of lists)
        {:ok, %Exqlite.Result{columns: returned_columns, rows: [[_ | _] = first_row_values | _]}} ->
          [inserted_record | _] = transform_exqlite_result_to_maps(returned_columns, [first_row_values])
          Logger.debug(
            "Crud.create successful for table '#{table}'. Record: #{inspect(inserted_record)}",
            module: __MODULE__
          )
          {:ok, inserted_record}

        # Caso especial para quando o SQLite retorna uma lista de listas diretamente
        {:ok, [[_ | _] = first_row | _]} when is_list(first_row) ->
          # Precisamos obter os nomes das colunas
          case Repo.query("PRAGMA table_info(#{table});", []) do
            {:ok, %Exqlite.Result{columns: _, rows: column_info}} ->
              # O PRAGMA table_info retorna: cid, name, type, notnull, dflt_value, pk
              # Precisamos extrair apenas os nomes das colunas (índice 1)
              column_names = Enum.map(column_info, fn row -> Enum.at(row, 1) end)
              [inserted_record | _] = transform_exqlite_result_to_maps(column_names, [first_row])
              Logger.debug(
                "Crud.create successful for table '#{table}' (direct list format). Record: #{inspect(inserted_record)}",
                module: __MODULE__
              )
              {:ok, inserted_record}

            {:ok, column_info} when is_list(column_info) ->
              # Formato alternativo do PRAGMA
              column_names = Enum.map(column_info, fn row -> Enum.at(row, 1) end)
              [inserted_record | _] = transform_exqlite_result_to_maps(column_names, [first_row])
              Logger.debug(
                "Crud.create successful for table '#{table}' (direct list format). Record: #{inspect(inserted_record)}",
                module: __MODULE__
              )
              {:ok, inserted_record}

            _ ->
              # Se não conseguirmos obter os nomes das colunas, retornamos um mapa com índices numéricos
              Logger.warning(
                "Crud.create não conseguiu obter nomes de colunas para '#{table}'. Criando mapa com índices.",
                module: __MODULE__
              )
              inserted_record = Enum.with_index(first_row) |> Enum.into(%{}, fn {value, index} -> {"column_#{index}", value} end)
              {:ok, inserted_record}
          end

        {:ok, %Exqlite.Result{num_rows: 0, rows: []}} -> # No record returned by RETURNING
          Logger.warning(
            "Crud.create for table '#{table}' did not return a record via RETURNING *. Check table schema, SQLite version, or if INSERT failed silently.",
            module: __MODULE__
          )
          {:error, :creation_failed_no_return}

        {:ok, %Exqlite.Result{rows: []}} -> # Similar to above
            Logger.warning(
              "Crud.create for table '#{table}' (with Result struct) did not return any rows. Assuming creation failed or no return.",
              module: __MODULE__
            )
            {:error, :creation_failed_no_return_via_result_struct}

        {:error, reason} ->
          Logger.error(
            "Crud.create failed for table '#{table}'. Reason: #{inspect(reason)}",
            module: __MODULE__
          )
          {:error, reason}

        other_ok_format -> # Catch-all for other {:ok, ...} formats that don't match
            Logger.warning(
              "Crud.create received an unexpected :ok format from Repo.query for table '#{table}': #{inspect(other_ok_format)}",
              module: __MODULE__
            )
            {:error, {:unexpected_create_return_format, other_ok_format}}
      end
    end
  end

  @doc """
  Retrieves a single record from the table by its primary key (assumed to be 'id').

  Returns `{:ok, record_map}` if found, `{:error, :not_found}` if not found,
  or `{:error, reason}` for other errors.
  """
  @spec get(String.t(), any()) :: {:ok, map()} | {:error, :not_found | any()}
  def get(table, id) when is_binary(table) do
    sql = "SELECT * FROM #{table} WHERE id = $1 LIMIT 1"
    Logger.debug("Crud.get SQL: #{sql} with id: #{id}", module: __MODULE__)

    case Repo.query(sql, [id]) do
      {:ok, %Exqlite.Result{columns: returned_columns, rows: [[_ | _] = first_row_values | _]}} ->
        [record | _] = transform_exqlite_result_to_maps(returned_columns, [first_row_values])
        {:ok, record}

      # Caso especial para quando o SQLite retorna uma lista de listas diretamente
      {:ok, [[_ | _] = first_row | _]} when is_list(first_row) ->
        # Precisamos obter os nomes das colunas
        case Repo.query("PRAGMA table_info(#{table});", []) do
          {:ok, %Exqlite.Result{columns: _, rows: column_info}} ->
            # O PRAGMA table_info retorna: cid, name, type, notnull, dflt_value, pk
            # Precisamos extrair apenas os nomes das colunas (índice 1)
            column_names = Enum.map(column_info, fn row -> Enum.at(row, 1) end)
            [record | _] = transform_exqlite_result_to_maps(column_names, [first_row])
            {:ok, record}

          {:ok, column_info} when is_list(column_info) ->
            # Formato alternativo do PRAGMA
            column_names = Enum.map(column_info, fn row -> Enum.at(row, 1) end)
            [record | _] = transform_exqlite_result_to_maps(column_names, [first_row])
            {:ok, record}

          _ ->
            # Se não conseguirmos obter os nomes das colunas, retornamos um mapa com índices numéricos
            Logger.warning(
              "Crud.get não conseguiu obter nomes de colunas para '#{table}'. Criando mapa com índices.",
              module: __MODULE__
            )
            record = Enum.with_index(first_row) |> Enum.into(%{}, fn {value, index} -> {"column_#{index}", value} end)
            {:ok, record}
        end

      {:ok, %Exqlite.Result{rows: []}} -> # No record found
        {:error, :not_found}

      {:ok, []} -> # No record found (formato alternativo)
        {:error, :not_found}

      {:error, reason} ->
        Logger.error(
          "Crud.get failed for table '#{table}' (id: #{id}). Reason: #{inspect(reason)}",
          module: __MODULE__
        )
        {:error, reason}

      other ->
        Logger.warning(
          "Crud.get received unexpected result from Repo.query for table '#{table}', id: #{id}: #{inspect(other)}",
          module: __MODULE__
        )
        {:error, {:unexpected_repo_result, other}}
    end
  end

  @doc """
  Lists all records from a table.
  """
  @spec list(String.t(), map(), list()) :: {:ok, list(map())} | {:error, any()}
  def list(table, conditions \\ %{}, _opts \\ []) when is_binary(table) do
    if map_size(conditions) > 0 do
      Logger.warning(
        "Crud.list called with conditions for table '#{table}', but condition parsing is not fully implemented yet. Fetching all records.",
        module: __MODULE__
      )
    end

    sql = "SELECT * FROM #{table}"
    Logger.debug("Crud.list SQL: #{sql} for table '#{table}'", module: __MODULE__)

    case Repo.query(sql, []) do
      {:ok, %Exqlite.Result{columns: returned_columns, rows: rows_values}} when is_list(rows_values) ->
        records = transform_exqlite_result_to_maps(returned_columns, rows_values)
        {:ok, records}

      # Caso especial para quando o SQLite retorna uma lista vazia
      {:ok, []} ->
        # Tabela vazia, retornar lista vazia
        Logger.debug(
          "Crud.list encontrou tabela vazia para '#{table}'",
          module: __MODULE__
        )
        {:ok, []}
        
      # Caso especial para quando o SQLite retorna uma lista de listas diretamente
      {:ok, rows_values} when is_list(rows_values) and length(rows_values) > 0 and is_list(hd(rows_values)) ->
        # Precisamos obter os nomes das colunas de outra forma
        # Podemos fazer uma consulta PRAGMA table_info para obter os nomes das colunas
        case Repo.query("PRAGMA table_info(#{table});", []) do
          {:ok, %Exqlite.Result{columns: _, rows: column_info}} ->
            # O PRAGMA table_info retorna: cid, name, type, notnull, dflt_value, pk
            # Precisamos extrair apenas os nomes das colunas (índice 1)
            column_names = Enum.map(column_info, fn row -> Enum.at(row, 1) end)
            records = transform_exqlite_result_to_maps(column_names, rows_values)
            {:ok, records}

          {:ok, column_info} when is_list(column_info) ->
            # Formato alternativo do PRAGMA
            column_names = Enum.map(column_info, fn row -> Enum.at(row, 1) end)
            records = transform_exqlite_result_to_maps(column_names, rows_values)
            {:ok, records}

          _ ->
            # Se não conseguirmos obter os nomes das colunas, retornamos os dados brutos
            Logger.warning(
              "Crud.list não conseguiu obter nomes de colunas para '#{table}'. Retornando dados brutos.",
              module: __MODULE__
            )
            {:ok, rows_values}
        end

      {:error, reason} ->
        Logger.error("Crud.list failed for table '#{table}'. Reason: #{inspect(reason)}",
          module: __MODULE__
        )
        {:error, reason}

      other ->
        Logger.warning(
          "Crud.list received unexpected result from Repo.query for table '#{table}': #{inspect(other)}",
          module: __MODULE__
        )
        {:error, {:unexpected_repo_result, other}}
    end
  end

  @doc """
  Updates a record in the table identified by `id` with the given `params`.

  Returns `{:ok, updated_record_map}` or `{:error, reason}`.
  Returns `{:error, :not_found}` if no record was updated (e.g., ID does not exist).
  Assumes SQLite 3.35.0+ for `RETURNING *`.
  """
  @spec update(String.t(), any(), map()) :: {:ok, map()} | {:error, any()}
  def update(table, id, params) when is_binary(table) and is_map(params) do
    if map_size(params) == 0 do
      Logger.warning("Crud.update called with empty params for table '#{table}', id: #{id}.",
        module: __MODULE__
      )
      {:error, :empty_params}
    else
      string_keyed_params =
        Enum.into(params, %{}, fn {k, v} ->
          {if(is_atom(k), do: Atom.to_string(k), else: k), v}
        end)

      columns_to_update = Map.keys(string_keyed_params)

      set_clauses =
        Enum.map_join(1..length(columns_to_update), ", ", fn i ->
          "#{Enum.at(columns_to_update, i - 1)} = $#{i}"
        end)

      values = Map.values(string_keyed_params) ++ [id]
      id_placeholder_index = length(columns_to_update) + 1

      sql = "UPDATE #{table} SET #{set_clauses} WHERE id = $#{id_placeholder_index} RETURNING *"
      Logger.debug("Crud.update SQL: #{sql} with values: #{inspect(values)}", module: __MODULE__)

      case Repo.query(sql, values) do
        {:ok, %Exqlite.Result{columns: returned_columns, rows: [[_ | _] = first_row_values | _]}} ->
          [updated_record | _] = transform_exqlite_result_to_maps(returned_columns, [first_row_values])
          {:ok, updated_record}

        # Caso especial para quando o SQLite retorna uma lista de listas diretamente
        {:ok, [[_ | _] = first_row | _]} when is_list(first_row) ->
          # Precisamos obter os nomes das colunas
          case Repo.query("PRAGMA table_info(#{table});", []) do
            {:ok, %Exqlite.Result{columns: _, rows: column_info}} ->
              # O PRAGMA table_info retorna: cid, name, type, notnull, dflt_value, pk
              # Precisamos extrair apenas os nomes das colunas (índice 1)
              column_names = Enum.map(column_info, fn row -> Enum.at(row, 1) end)
              [updated_record | _] = transform_exqlite_result_to_maps(column_names, [first_row])
              {:ok, updated_record}

            {:ok, column_info} when is_list(column_info) ->
              # Formato alternativo do PRAGMA
              column_names = Enum.map(column_info, fn row -> Enum.at(row, 1) end)
              [updated_record | _] = transform_exqlite_result_to_maps(column_names, [first_row])
              {:ok, updated_record}

            _ ->
              # Se não conseguirmos obter os nomes das colunas, retornamos um mapa com índices numéricos
              Logger.warning(
                "Crud.update não conseguiu obter nomes de colunas para '#{table}'. Criando mapa com índices.",
                module: __MODULE__
              )
              updated_record = Enum.with_index(first_row) |> Enum.into(%{}, fn {value, index} -> {"column_#{index}", value} end)
              {:ok, updated_record}
          end

        {:ok, %Exqlite.Result{rows: []}} -> # No rows updated/returned (ID not found)
          Logger.info("Crud.update for table '#{table}', id: #{id} did not affect any rows or RETURNING * yielded no result. Assuming not found.", module: __MODULE__)
          {:error, :not_found}

        {:ok, []} -> # No rows updated/returned (ID not found) - formato alternativo
          Logger.info("Crud.update for table '#{table}', id: #{id} did not affect any rows. Assuming not found.", module: __MODULE__)
          {:error, :not_found}

        {:error, reason} ->
          Logger.error(
            "Crud.update failed for table '#{table}' (id: #{id}). Reason: #{inspect(reason)}",
            module: __MODULE__
          )
          {:error, reason}

        other ->
          Logger.warning(
            "Crud.update received unexpected result from Repo.query for table '#{table}', id: #{id}: #{inspect(other)}",
            module: __MODULE__
          )
          {:error, {:unexpected_repo_result, other}}
      end
    end
  end

  @doc """
  Deletes a record from the table by its primary key (assumed to be 'id').

  Returns `{:ok, deleted_record_map}` if `RETURNING *` is effective and record existed.
  Returns `{:error, :not_found}` if no record was deleted.
  Or `{:error, reason}` for other DB errors.
  Assumes SQLite 3.35.0+ for `RETURNING *`.
  """
  @spec delete(String.t(), any()) :: {:ok, map()} | {:error, any()}
  def delete(table, id) when is_binary(table) do
    sql = "DELETE FROM #{table} WHERE id = $1 RETURNING *"
    Logger.debug("Crud.delete SQL: #{sql} with id: #{id}", module: __MODULE__)

    case Repo.query(sql, [id]) do
      {:ok, %Exqlite.Result{columns: returned_columns, rows: [[_ | _] = first_row_values | _]}} ->
        [deleted_record | _] = transform_exqlite_result_to_maps(returned_columns, [first_row_values])
        {:ok, deleted_record}

      # Caso especial para quando o SQLite retorna uma lista de listas diretamente
      {:ok, [[_ | _] = first_row | _]} when is_list(first_row) ->
        # Precisamos obter os nomes das colunas
        case Repo.query("PRAGMA table_info(#{table});", []) do
          {:ok, %Exqlite.Result{columns: _, rows: column_info}} ->
            # O PRAGMA table_info retorna: cid, name, type, notnull, dflt_value, pk
            # Precisamos extrair apenas os nomes das colunas (índice 1)
            column_names = Enum.map(column_info, fn row -> Enum.at(row, 1) end)
            [deleted_record | _] = transform_exqlite_result_to_maps(column_names, [first_row])
            {:ok, deleted_record}

          {:ok, column_info} when is_list(column_info) ->
            # Formato alternativo do PRAGMA
            column_names = Enum.map(column_info, fn row -> Enum.at(row, 1) end)
            [deleted_record | _] = transform_exqlite_result_to_maps(column_names, [first_row])
            {:ok, deleted_record}

          _ ->
            # Se não conseguirmos obter os nomes das colunas, retornamos um mapa com índices numéricos
            Logger.warning(
              "Crud.delete não conseguiu obter nomes de colunas para '#{table}'. Criando mapa com índices.",
              module: __MODULE__
            )
            deleted_record = Enum.with_index(first_row) |> Enum.into(%{}, fn {value, index} -> {"column_#{index}", value} end)
            {:ok, deleted_record}
        end

      {:ok, %Exqlite.Result{rows: []}} -> # No record returned by RETURNING (ID did not exist)
        Logger.info("Crud.delete for table '#{table}', id: #{id}. No record returned by RETURNING *, assuming not found.", module: __MODULE__)
        {:error, :not_found}

      {:ok, []} -> # No record returned by RETURNING (ID did not exist) - formato alternativo
        Logger.info("Crud.delete for table '#{table}', id: #{id}. No record returned, assuming not found.", module: __MODULE__)
        {:error, :not_found}

      {:error, reason} ->
        Logger.error(
          "Crud.delete failed for table '#{table}' (id: #{id}). Reason: #{inspect(reason)}",
          module: __MODULE__
        )
        {:error, reason}

      other ->
        Logger.warning(
          "Crud.delete received unexpected result from Repo.query for table '#{table}', id: #{id}: #{inspect(other)}",
          module: __MODULE__
        )
        {:error, {:unexpected_repo_result, other}}
    end
  end
end
# </file>
