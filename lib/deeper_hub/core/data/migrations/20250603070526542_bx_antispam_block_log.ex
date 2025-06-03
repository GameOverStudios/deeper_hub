defmodule DeeperHub.Core.Data.Migrations.BxAntispamBlockLog do
  @moduledoc """
  Migration para criar e remover a tabela bx_antispam_block_log.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_antispam_block_log.
  """
  def up do
    Logger.info("Criando tabela de bx_antispam_block_log...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_antispam_block_log (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    ip INTEGER NOT NULL,
    profile_id INTEGER NOT NULL,
    "type" TEXT NOT NULL,
    extra TEXT NOT NULL,
    added INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_antispam_block_log criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_antispam_block_log: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_antispam_block_log: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_antispam_block_log.
  """
  def down do
    Logger.info("Removendo tabela de bx_antispam_block_log...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_antispam_block_log
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_antispam_block_log removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_antispam_block_log: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_antispam_block_log: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
