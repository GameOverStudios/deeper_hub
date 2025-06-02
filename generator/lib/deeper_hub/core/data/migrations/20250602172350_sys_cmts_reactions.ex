defmodule DeeperHub.Core.Data.Migrations.SysCmtsReactions do
  @moduledoc """
  Migration para criar e remover a tabela sys_cmts_reactions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_cmts_reactions.
  """
  def up do
    Logger.info("Criando tabela de sys_cmts_reactions...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_cmts_reactions (
id int(11) NOT NULL  auto_increment,
object_id int(11) NOT NULL DEFAULT 0,
reaction varchar(32) NOT NULL DEFAULT,
count int(11) NOT NULL DEFAULT 0,
sum int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cmts_reactions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_cmts_reactions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_cmts_reactions.
  """
  def down do
    Logger.info("Removendo tabela de sys_cmts_reactions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_cmts_reactions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cmts_reactions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_cmts_reactions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
