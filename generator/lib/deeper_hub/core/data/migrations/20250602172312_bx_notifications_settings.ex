defmodule DeeperHub.Core.Data.Migrations.BxNotificationsSettings do
  @moduledoc """
  Migration para criar e remover a tabela bx_notifications_settings.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_notifications_settings.
  """
  def up do
    Logger.info("Criando tabela de bx_notifications_settings...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_notifications_settings (
id int(11) NOT NULL  auto_increment,
group varchar(64) NOT NULL DEFAULT,
handler_id int(11) NOT NULL DEFAULT 0,
delivery enum('site','email','push') NOT NULL DEFAULT site,
type enum('personal','follow_member','follow_context','other') NOT NULL DEFAULT personal,
title varchar(64) NOT NULL DEFAULT,
value tinyint(4) NOT NULL DEFAULT 1,
active tinyint(4) NOT NULL DEFAULT 1,
order int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_settings criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_notifications_settings: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_notifications_settings.
  """
  def down do
    Logger.info("Removendo tabela de bx_notifications_settings...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_notifications_settings
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_notifications_settings removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_notifications_settings: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
