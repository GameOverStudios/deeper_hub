defmodule DeeperHub.Core.Data.Migrations.SysCmtsIds do
  @moduledoc """
  Migration para criar e remover a tabela sys_cmts_ids.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_cmts_ids.
  """
  def up do
    Logger.info("Criando tabela de sys_cmts_ids...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_cmts_ids (
id int(11) NOT NULL  auto_increment,
system_id int(11) NOT NULL DEFAULT 0,
cmt_id int(11) NOT NULL DEFAULT 0,
author_id int(11) NOT NULL DEFAULT 0,
rate float NOT NULL DEFAULT 0,
votes int(11) NOT NULL DEFAULT 0,
rrate float NOT NULL DEFAULT 0,
rvotes int(11) NOT NULL DEFAULT 0,
score int(11) NOT NULL DEFAULT 0,
sc_up int(11) NOT NULL DEFAULT 0,
sc_down int(11) NOT NULL DEFAULT 0,
reports int(11) NOT NULL DEFAULT 0,
status_admin enum('active','hidden','pending') NOT NULL DEFAULT active,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cmts_ids criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_cmts_ids: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_cmts_ids.
  """
  def down do
    Logger.info("Removendo tabela de sys_cmts_ids...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_cmts_ids
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cmts_ids removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_cmts_ids: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
