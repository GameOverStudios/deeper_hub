defmodule DeeperHub.Core.Data.Migrations.BxContactEntries do
  @moduledoc """
  Migration para criar e remover a tabela bx_contact_entries.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_contact_entries.
  """
  def up do
    Logger.info("Criando tabela de bx_contact_entries...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_contact_entries (
id int(11) NOT NULL  auto_increment,
name varchar(255) NOT NULL,
email varchar(128) NOT NULL,
subject varchar(128) NOT NULL,
body text NOT NULL,
uri varchar(255) NOT NULL,
date int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_contact_entries criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_contact_entries: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_contact_entries.
  """
  def down do
    Logger.info("Removendo tabela de bx_contact_entries...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_contact_entries
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_contact_entries removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_contact_entries: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
