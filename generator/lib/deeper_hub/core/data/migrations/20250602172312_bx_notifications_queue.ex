defmodule DeeperHub.Core.Data.Migrations.BxNotificationsQueue do
  @moduledoc """
  Migration para criar e remover a tabela bx_notifications_queue.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_notifications_queue.
  """
  def up do
    Logger.info("Criando tabela de bx_notifications_queue...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_notifications_queue (
id int(11) NOT NULL  auto_increment,
profile_id int(11) NOT NULL DEFAULT 0,
event_id int(11) NOT NULL DEFAULT 0,
delivery varchar(64) NOT NULL DEFAULT,
content text NOT NULL,
date int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_queue criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_notifications_queue: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_notifications_queue.
  """
  def down do
    Logger.info("Removendo tabela de bx_notifications_queue...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_notifications_queue
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_queue removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_notifications_queue: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
