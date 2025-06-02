defmodule DeeperHub.Core.Data.Migrations.BxNotificationsRead do
  @moduledoc """
  Migration para criar e remover a tabela bx_notifications_read.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_notifications_read.
  """
  def up do
    Logger.info("Criando tabela de bx_notifications_read...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_notifications_read (
user_id int(11) NOT NULL DEFAULT 0,
event_id int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_read criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_notifications_read: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_notifications_read.
  """
  def down do
    Logger.info("Removendo tabela de bx_notifications_read...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_notifications_read
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_read removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_notifications_read: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
