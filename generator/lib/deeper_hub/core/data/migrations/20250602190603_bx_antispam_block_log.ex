defmodule DeeperHub.Core.Data.Migrations.BxAntispamBlockLog do
  @moduledoc """
  Migration para criar e remover a tabela bx_antispam_block_log.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_antispam_block_log.
  """
  def up do
    Logger.info("Criando tabela de bx_antispam_block_log...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_antispam_block_log (
id int(11) NOT NULL  auto_increment,
ip int(10) unsigned NOT NULL,
profile_id int(10) unsigned NOT NULL,
type varchar(32) NOT NULL,
extra text NOT NULL,
added int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_antispam_block_log criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_antispam_block_log: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_antispam_block_log.
  """
  def down do
    Logger.info("Removendo tabela de bx_antispam_block_log...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_antispam_block_log
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_antispam_block_log removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_antispam_block_log: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
