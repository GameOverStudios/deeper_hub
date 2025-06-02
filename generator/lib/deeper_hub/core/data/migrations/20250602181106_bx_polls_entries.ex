defmodule DeeperHub.Core.Data.Migrations.BxPollsEntries do
  @moduledoc """
  Migration para criar e remover a tabela bx_polls_entries.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_polls_entries.
  """
  def up do
    Logger.info("Criando tabela de bx_polls_entries...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_polls_entries (
id int(10) unsigned NOT NULL  auto_increment,
author int(10) unsigned NOT NULL,
added int(11) NOT NULL,
changed int(11) NOT NULL,
thumb int(11) NOT NULL,
text text NOT NULL,
cat int(11) NOT NULL,
labels text NOT NULL,
location text NOT NULL,
views int(11) NOT NULL DEFAULT 0,
rate float NOT NULL DEFAULT 0,
votes int(11) NOT NULL DEFAULT 0,
rrate float NOT NULL DEFAULT 0,
rvotes int(11) NOT NULL DEFAULT 0,
score int(11) NOT NULL DEFAULT 0,
sc_up int(11) NOT NULL DEFAULT 0,
sc_down int(11) NOT NULL DEFAULT 0,
favorites int(11) NOT NULL DEFAULT 0,
comments int(11) NOT NULL DEFAULT 0,
reports int(11) NOT NULL DEFAULT 0,
featured int(11) NOT NULL DEFAULT 0,
cf int(11) NOT NULL DEFAULT 1,
allow_view_to varchar(16) NOT NULL DEFAULT 3,
anonymous tinyint(4) NOT NULL DEFAULT 0,
hidden_results tinyint(4) NOT NULL DEFAULT 0,
status enum('active','hidden') NOT NULL DEFAULT active,
status_admin enum('active','hidden','pending') NOT NULL DEFAULT active,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_polls_entries criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_polls_entries: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_polls_entries.
  """
  def down do
    Logger.info("Removendo tabela de bx_polls_entries...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_polls_entries
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_polls_entries removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_polls_entries: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
