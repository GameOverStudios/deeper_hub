defmodule DeeperHub.Core.Data.Migrations.BxCnlContent do
  @moduledoc """
  Migration para criar e remover a tabela bx_cnl_content.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_cnl_content.
  """
  def up do
    Logger.info("Criando tabela de bx_cnl_content...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_cnl_content (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    content_id INTEGER NOT NULL,
    cnl_id INTEGER NOT NULL,
    author_id INTEGER NOT NULL,
    module_name TEXT NOT NULL,
    date INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_cnl_content criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_cnl_content: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_cnl_content: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_cnl_content.
  """
  def down do
    Logger.info("Removendo tabela de bx_cnl_content...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_cnl_content
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_cnl_content removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_cnl_content: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_cnl_content: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
