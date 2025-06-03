defmodule DeeperHub.Core.Data.Migrations.BxSpacesAdmins do
  @moduledoc """
  Migration para criar e remover a tabela bx_spaces_admins.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_spaces_admins.
  """
  def up do
    Logger.info("Criando tabela de bx_spaces_admins...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_spaces_admins (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    group_profile_id INTEGER NOT NULL,
    fan_id INTEGER NOT NULL,
    role INTEGER NOT NULL DEFAULT 0,
    "order" TEXT NOT NULL,
    added INTEGER NOT NULL DEFAULT 0,
    expired INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_spaces_admins criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_spaces_admins: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_spaces_admins: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_spaces_admins.
  """
  def down do
    Logger.info("Removendo tabela de bx_spaces_admins...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_spaces_admins
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_spaces_admins removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_spaces_admins: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_spaces_admins: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
