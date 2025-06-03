defmodule DeeperHub.Core.Data.Migrations.BxOrganizationsFans do
  @moduledoc """
  Migration para criar e remover a tabela bx_organizations_fans.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_organizations_fans.
  """
  def up do
    Logger.info("Criando tabela de bx_organizations_fans...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_organizations_fans (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    initiator INTEGER NOT NULL,
    content INTEGER NOT NULL,
    mutual INTEGER NOT NULL,
    added INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_organizations_fans criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_organizations_fans: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_organizations_fans: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_organizations_fans.
  """
  def down do
    Logger.info("Removendo tabela de bx_organizations_fans...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_organizations_fans
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_organizations_fans removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_organizations_fans: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_organizations_fans: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
