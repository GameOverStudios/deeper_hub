defmodule DeeperHub.Core.Data.Migrations.SysCmtsImages2entries do
  @moduledoc """
  Migration para criar e remover a tabela sys_cmts_images2entries.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_cmts_images2entries.
  """
  def up do
    Logger.info("Criando tabela de sys_cmts_images2entries...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_cmts_images2entries (
id int(11) NOT NULL  auto_increment,
system_id int(11) NOT NULL DEFAULT 0,
cmt_id int(11) NOT NULL DEFAULT 0,
image_id int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cmts_images2entries criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_cmts_images2entries: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_cmts_images2entries.
  """
  def down do
    Logger.info("Removendo tabela de sys_cmts_images2entries...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_cmts_images2entries
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_cmts_images2entries removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_cmts_images2entries: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
