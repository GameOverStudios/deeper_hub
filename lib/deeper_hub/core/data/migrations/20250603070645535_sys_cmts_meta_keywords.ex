defmodule DeeperHub.Core.Data.Migrations.SysCmtsMetaKeywords do
  @moduledoc """
  Migration para criar e remover a tabela sys_cmts_meta_keywords.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_cmts_meta_keywords.
  """
  def up do
    Logger.info("Criando tabela de sys_cmts_meta_keywords...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_cmts_meta_keywords (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object_id INTEGER NOT NULL,
    keyword TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cmts_meta_keywords criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_cmts_meta_keywords: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_cmts_meta_keywords: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_cmts_meta_keywords.
  """
  def down do
    Logger.info("Removendo tabela de sys_cmts_meta_keywords...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_cmts_meta_keywords
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cmts_meta_keywords removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_cmts_meta_keywords: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_cmts_meta_keywords: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
