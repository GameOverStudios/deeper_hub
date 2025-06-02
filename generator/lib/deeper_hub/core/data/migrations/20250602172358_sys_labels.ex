defmodule DeeperHub.Core.Data.Migrations.SysLabels do
  @moduledoc """
  Migration para criar e remover a tabela sys_labels.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_labels.
  """
  def up do
    Logger.info("Criando tabela de sys_labels...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_labels (
id int(11) NOT NULL  auto_increment,
module varchar(32) NOT NULL,
parent int(11) NOT NULL DEFAULT 0,
level int(11) NOT NULL DEFAULT 0,
order int(11) NOT NULL DEFAULT 0,
value varchar(128) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_labels criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_labels: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_labels.
  """
  def down do
    Logger.info("Removendo tabela de sys_labels...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_labels
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_labels removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_labels: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
