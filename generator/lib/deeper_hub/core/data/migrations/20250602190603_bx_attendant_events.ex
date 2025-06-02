defmodule DeeperHub.Core.Data.Migrations.BxAttendantEvents do
  @moduledoc """
  Migration para criar e remover a tabela bx_attendant_events.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_attendant_events.
  """
  def up do
    Logger.info("Criando tabela de bx_attendant_events...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_attendant_events (
id int(10) unsigned NOT NULL  auto_increment,
method varchar(50) NOT NULL,
event varchar(50) NOT NULL,
added int(11) NULL,
processed int(11) NULL,
action varchar(10) NOT NULL,
object_id int(11) NULL,
profile_id int(11) NULL,
module varchar(50) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_attendant_events criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_attendant_events: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_attendant_events.
  """
  def down do
    Logger.info("Removendo tabela de bx_attendant_events...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_attendant_events
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_attendant_events removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_attendant_events: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
