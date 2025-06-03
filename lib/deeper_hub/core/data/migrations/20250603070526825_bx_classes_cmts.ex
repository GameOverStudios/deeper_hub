defmodule DeeperHub.Core.Data.Migrations.BxClassesCmts do
  @moduledoc """
  Migration para criar e remover a tabela bx_classes_cmts.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_classes_cmts.
  """
  def up do
    Logger.info("Criando tabela de bx_classes_cmts...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_classes_cmts (
    cmt_id INTEGER NOT NULL,
    cmt_parent_id INTEGER NOT NULL DEFAULT 0,
    cmt_vparent_id INTEGER NOT NULL DEFAULT 0,
    cmt_object_id INTEGER NOT NULL DEFAULT 0,
    cmt_author_id INTEGER NOT NULL DEFAULT 0,
    cmt_level INTEGER NOT NULL DEFAULT 0,
    cmt_text TEXT NOT NULL,
    cmt_mood INTEGER NOT NULL DEFAULT 0,
    cmt_rate INTEGER NOT NULL DEFAULT 0,
    cmt_rate_count INTEGER NOT NULL DEFAULT 0,
    cmt_time INTEGER NOT NULL DEFAULT 0,
    cmt_replies INTEGER NOT NULL DEFAULT 0,
    cmt_pinned INTEGER NOT NULL DEFAULT 0,
    cmt_cf INTEGER NOT NULL DEFAULT 1,
      PRIMARY KEY (cmt_id)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_classes_cmts criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_classes_cmts: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_classes_cmts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_classes_cmts.
  """
  def down do
    Logger.info("Removendo tabela de bx_classes_cmts...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_classes_cmts
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_classes_cmts removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_classes_cmts: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_classes_cmts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
