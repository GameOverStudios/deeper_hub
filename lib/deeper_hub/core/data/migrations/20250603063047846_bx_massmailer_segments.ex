defmodule DeeperHub.Core.Data.Migrations.BxMassmailerSegments do
  @moduledoc """
  Migration para criar e remover a tabela bx_massmailer_segments.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_massmailer_segments.
  """
  def up do
    Logger.info("Criando tabela de bx_massmailer_segments...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_massmailer_segments (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    title TEXT NULL,
    info TEXT NULL,
    email_list TEXT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_massmailer_segments criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_massmailer_segments: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_massmailer_segments.
  """
  def down do
    Logger.info("Removendo tabela de bx_massmailer_segments...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_massmailer_segments
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_massmailer_segments removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_massmailer_segments: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
