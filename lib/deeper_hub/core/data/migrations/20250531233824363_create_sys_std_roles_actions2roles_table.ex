# Migração gerada com ID único: V1748745504363 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysStdRolesActions2RolesTable do
  # Migração gerada com ID único: V1748745504363 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_std_roles_actions2roles.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_std_roles_actions2roles.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_std_roles_actions2roles...", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS sys_std_roles_actions2roles (
      role_id INTEGER NOT NULL, -- FK para sys_std_roles.id
      action_id INTEGER NOT NULL, -- FK para sys_std_roles_actions.id
      PRIMARY KEY (role_id, action_id),
      FOREIGN KEY (role_id) REFERENCES sys_std_roles(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (action_id) REFERENCES sys_std_roles_actions(id) ON DELETE CASCADE ON UPDATE CASCADE
    );
    """
    # Índices para FKs são geralmente criados automaticamente pelo SQLite quando a FK é definida,
    # mas podem ser adicionados explicitamente se necessário para otimizar queries que não usam a PK.
    # CREATE INDEX IF NOT EXISTS idx_sys_std_roles_actions2roles_action_id ON sys_std_roles_actions2roles(action_id);


    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_std_roles_actions2roles criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_std_roles_actions2roles: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_std_roles_actions2roles.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_std_roles_actions2roles...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_std_roles_actions2roles;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_std_roles_actions2roles removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_std_roles_actions2roles: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end