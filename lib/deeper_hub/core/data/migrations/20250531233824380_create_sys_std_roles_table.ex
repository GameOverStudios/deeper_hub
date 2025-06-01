# Migração gerada com ID único: V1748745504379 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysStdRolesTable do
  # Migração gerada com ID único: V1748745504379 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_std_roles.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_std_roles.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_std_roles...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_std_roles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE, -- Nome do papel, ex: 'admin'
      title TEXT NOT NULL, -- Título amigável, ex: 'Administrator'
      description TEXT,
      active INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      "order" INTEGER NOT NULL DEFAULT 0
    );

    CREATE INDEX IF NOT EXISTS idx_sys_std_roles_name ON sys_std_roles(name);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_std_roles criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_std_roles: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_std_roles.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_std_roles...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_std_roles;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_std_roles removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_std_roles: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end