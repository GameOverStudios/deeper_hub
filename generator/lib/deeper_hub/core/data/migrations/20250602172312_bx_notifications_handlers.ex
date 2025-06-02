defmodule DeeperHub.Core.Data.Migrations.BxNotificationsHandlers do
  @moduledoc """
  Migration para criar e remover a tabela bx_notifications_handlers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_notifications_handlers.
  """
  def up do
    Logger.info("Criando tabela de bx_notifications_handlers...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_notifications_handlers (
id int(11) NOT NULL  auto_increment,
group varchar(64) NOT NULL DEFAULT,
type enum('insert','update','delete') NOT NULL DEFAULT insert,
alert_unit varchar(64) NOT NULL DEFAULT,
alert_action varchar(64) NOT NULL DEFAULT,
content text NOT NULL,
privacy varchar(64) NOT NULL DEFAULT,
priority int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_handlers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_notifications_handlers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_notifications_handlers.
  """
  def down do
    Logger.info("Removendo tabela de bx_notifications_handlers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_notifications_handlers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_handlers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_notifications_handlers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
