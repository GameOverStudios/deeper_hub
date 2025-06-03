defmodule DeeperHub.Core.Data.Migrations.SysObjectsForm do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_form.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_form.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_form...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_form (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    module TEXT NOT NULL,
    title TEXT NOT NULL,
    "action" TEXT NOT NULL,
    form_attrs TEXT NOT NULL,
    submit_name TEXT NOT NULL,
    "table" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    uri TEXT NOT NULL,
    uri_title TEXT NOT NULL,
    params TEXT NOT NULL,
    deletable INTEGER NOT NULL DEFAULT 1,
    active INTEGER NOT NULL DEFAULT 0,
    parent_form TEXT NOT NULL,
    override_class_name TEXT NOT NULL,
    override_class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_form criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_form: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_form: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_form.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_form...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_form
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_form removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_form: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_form: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
