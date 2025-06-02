defmodule DeeperHub.Core.Data.Migrations.BxReputationHandlers do
  @moduledoc """
  Migration para criar e remover a tabela bx_reputation_handlers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_reputation_handlers.
  """
  def up do
    Logger.info("Criando tabela de bx_reputation_handlers...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_reputation_handlers (
id int(11) NOT NULL  auto_increment,
group varchar(64) NOT NULL DEFAULT,
type enum('insert','update','delete') NOT NULL DEFAULT insert,
alert_unit varchar(64) NOT NULL DEFAULT,
alert_action varchar(64) NOT NULL DEFAULT,
points_active int(11) NOT NULL DEFAULT 0,
points_passive int(11) NOT NULL DEFAULT 0,
active tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reputation_handlers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_reputation_handlers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_reputation_handlers.
  """
  def down do
    Logger.info("Removendo tabela de bx_reputation_handlers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_reputation_handlers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reputation_handlers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_reputation_handlers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
