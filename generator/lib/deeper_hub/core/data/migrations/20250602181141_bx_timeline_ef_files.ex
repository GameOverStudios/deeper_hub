defmodule DeeperHub.Core.Data.Migrations.BxTimelineEfFiles do
  @moduledoc """
  Migration para criar e remover a tabela bx_timeline_ef_files.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_timeline_ef_files.
  """
  def up do
    Logger.info("Criando tabela de bx_timeline_ef_files...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_timeline_ef_files (
event_id int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (event_id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_ef_files criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_timeline_ef_files: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_timeline_ef_files.
  """
  def down do
    Logger.info("Removendo tabela de bx_timeline_ef_files...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_timeline_ef_files
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_timeline_ef_files removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_timeline_ef_files: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
