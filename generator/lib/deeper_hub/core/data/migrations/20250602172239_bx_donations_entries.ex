defmodule DeeperHub.Core.Data.Migrations.BxDonationsEntries do
  @moduledoc """
  Migration para criar e remover a tabela bx_donations_entries.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_donations_entries.
  """
  def up do
    Logger.info("Criando tabela de bx_donations_entries...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_donations_entries (
id int(11) unsigned NOT NULL  auto_increment,
profile_id int(11) unsigned NOT NULL DEFAULT 0,
type_id int(11) NOT NULL DEFAULT 0,
period int(11) unsigned NOT NULL DEFAULT 0,
period_unit varchar(32) NOT NULL DEFAULT,
amount float unsigned NOT NULL DEFAULT 0,
order varchar(32) NOT NULL DEFAULT,
license varchar(32) NOT NULL DEFAULT,
added int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_donations_entries criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_donations_entries: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_donations_entries.
  """
  def down do
    Logger.info("Removendo tabela de bx_donations_entries...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_donations_entries
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_donations_entries removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_donations_entries: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
