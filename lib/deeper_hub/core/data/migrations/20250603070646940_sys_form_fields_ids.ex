defmodule DeeperHub.Core.Data.Migrations.SysFormFieldsIds do
  @moduledoc """
  Migration para criar e remover a tabela sys_form_fields_ids.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_form_fields_ids.
  """
  def up do
    Logger.info("Criando tabela de sys_form_fields_ids...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_form_fields_ids (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object_form TEXT NOT NULL,
    module TEXT NOT NULL,
    field_name TEXT NOT NULL,
    content_id INTEGER NOT NULL DEFAULT 0,
    author_id INTEGER NOT NULL DEFAULT 0,
    nested_content_id INTEGER NOT NULL DEFAULT 0,
    rate REAL NOT NULL DEFAULT 0,
    votes INTEGER NOT NULL DEFAULT 0,
    rrate REAL NOT NULL DEFAULT 0,
    rvotes INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_fields_ids criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_form_fields_ids: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_form_fields_ids: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_form_fields_ids.
  """
  def down do
    Logger.info("Removendo tabela de sys_form_fields_ids...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_form_fields_ids
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_fields_ids removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_form_fields_ids: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_form_fields_ids: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
