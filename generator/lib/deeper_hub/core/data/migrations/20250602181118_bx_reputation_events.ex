defmodule DeeperHub.Core.Data.Migrations.BxReputationEvents do
  @moduledoc """
  Migration para criar e remover a tabela bx_reputation_events.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_reputation_events.
  """
  def up do
    Logger.info("Criando tabela de bx_reputation_events...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_reputation_events (
id int(11) NOT NULL  auto_increment,
owner_id int(11) NOT NULL DEFAULT 0,
type varchar(64) NOT NULL DEFAULT,
action varchar(64) NOT NULL DEFAULT,
object_id int(11) NOT NULL DEFAULT 0,
object_owner_id int(11) NOT NULL DEFAULT 0,
points int(11) NOT NULL DEFAULT 0,
date int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reputation_events criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_reputation_events: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_reputation_events.
  """
  def down do
    Logger.info("Removendo tabela de bx_reputation_events...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_reputation_events
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reputation_events removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_reputation_events: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
