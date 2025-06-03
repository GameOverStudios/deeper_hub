defmodule DeeperHub.Core.Data.Migrations.SysFormPreLists do
  @moduledoc """
  Migration para criar e remover a tabela sys_form_pre_lists.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_form_pre_lists.
  """
  def up do
    Logger.info("Criando tabela de sys_form_pre_lists...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_form_pre_lists (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    module TEXT NOT NULL,
    "key" TEXT NOT NULL,
    title TEXT NOT NULL,
    use_for_sets INTEGER NOT NULL DEFAULT 1,
    extendable INTEGER NOT NULL DEFAULT 1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_pre_lists criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_form_pre_lists: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_form_pre_lists: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_form_pre_lists.
  """
  def down do
    Logger.info("Removendo tabela de sys_form_pre_lists...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_form_pre_lists
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_pre_lists removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_form_pre_lists: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_form_pre_lists: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
