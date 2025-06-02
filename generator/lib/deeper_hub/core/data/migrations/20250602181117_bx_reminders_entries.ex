defmodule DeeperHub.Core.Data.Migrations.BxRemindersEntries do
  @moduledoc """
  Migration para criar e remover a tabela bx_reminders_entries.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_reminders_entries.
  """
  def up do
    Logger.info("Criando tabela de bx_reminders_entries...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_reminders_entries (
id int(11) NOT NULL  auto_increment,
type_id int(11) NOT NULL DEFAULT 0,
rmd_pid int(11) NOT NULL DEFAULT 0,
cnt_pid int(11) NOT NULL DEFAULT 0,
params text NOT NULL DEFAULT '',
notified text NOT NULL DEFAULT '',
active tinyint(4) NOT NULL DEFAULT 0,
visible tinyint(4) NOT NULL DEFAULT 0,
added int(11) NOT NULL,
expired int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reminders_entries criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_reminders_entries: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_reminders_entries.
  """
  def down do
    Logger.info("Removendo tabela de bx_reminders_entries...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_reminders_entries
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reminders_entries removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_reminders_entries: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
