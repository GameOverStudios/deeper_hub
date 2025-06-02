defmodule DeeperHub.Core.Data.Migrations.BxNotificationsEvents do
  @moduledoc """
  Migration para criar e remover a tabela bx_notifications_events.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_notifications_events.
  """
  def up do
    Logger.info("Criando tabela de bx_notifications_events...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_notifications_events (
id int(11) NOT NULL  auto_increment,
owner_id int(11) NOT NULL DEFAULT 0,
type varchar(255) NOT NULL,
action varchar(255) NOT NULL,
object_id text NOT NULL,
object_owner_id int(11) NOT NULL DEFAULT 0,
object_privacy_view varchar(32) NOT NULL DEFAULT 3,
subobject_id int(11) NOT NULL DEFAULT 0,
content text NOT NULL,
source varchar(32) NOT NULL DEFAULT,
allow_view_event_to varchar(32) NOT NULL DEFAULT 3,
date int(11) NOT NULL DEFAULT 0,
processed tinyint(4) NOT NULL DEFAULT 0,
active tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_events criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_notifications_events: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_notifications_events.
  """
  def down do
    Logger.info("Removendo tabela de bx_notifications_events...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_notifications_events
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_events removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_notifications_events: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
