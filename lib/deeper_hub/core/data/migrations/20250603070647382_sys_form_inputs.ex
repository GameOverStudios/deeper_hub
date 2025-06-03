defmodule DeeperHub.Core.Data.Migrations.SysFormInputs do
  @moduledoc """
  Migration para criar e remover a tabela sys_form_inputs.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_form_inputs.
  """
  def up do
    Logger.info("Criando tabela de sys_form_inputs...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_form_inputs (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    module TEXT NOT NULL,
    name TEXT NOT NULL,
    value TEXT NOT NULL,
    "values" TEXT NOT NULL,
    checked INTEGER NOT NULL DEFAULT 0,
    "type" TEXT NOT NULL,
    caption_system TEXT NOT NULL,
    caption TEXT NOT NULL,
    info TEXT NOT NULL,
    help TEXT NOT NULL,
    icon TEXT NOT NULL,
    required INTEGER NOT NULL DEFAULT 0,
    "unique" INTEGER NOT NULL DEFAULT 0,
    collapsed INTEGER NOT NULL DEFAULT 0,
    html INTEGER NOT NULL DEFAULT 0,
    privacy INTEGER NOT NULL DEFAULT 0,
    rateable TEXT NOT NULL,
    attrs TEXT NOT NULL,
    attrs_tr TEXT NOT NULL,
    attrs_wrapper TEXT NOT NULL,
    checker_func TEXT NOT NULL,
    checker_params TEXT NOT NULL,
    checker_error TEXT NOT NULL,
    db_pass TEXT NOT NULL,
    db_params TEXT NOT NULL,
    editable INTEGER NOT NULL DEFAULT 1,
    deletable INTEGER NOT NULL DEFAULT 1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_inputs criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_form_inputs: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_form_inputs: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_form_inputs.
  """
  def down do
    Logger.info("Removendo tabela de sys_form_inputs...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_form_inputs
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_inputs removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_form_inputs: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_form_inputs: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
