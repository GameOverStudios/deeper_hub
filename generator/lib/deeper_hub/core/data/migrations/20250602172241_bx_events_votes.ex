defmodule DeeperHub.Core.Data.Migrations.BxEventsVotes do
  @moduledoc """
  Migration para criar e remover a tabela bx_events_votes.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_events_votes.
  """
  def up do
    Logger.info("Criando tabela de bx_events_votes...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_events_votes (
id int(11) NOT NULL  auto_increment,
object_id int(11) NOT NULL DEFAULT 0,
count int(11) NOT NULL DEFAULT 0,
sum int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_events_votes criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_events_votes: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_events_votes.
  """
  def down do
    Logger.info("Removendo tabela de bx_events_votes...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_events_votes
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_events_votes removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_events_votes: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
