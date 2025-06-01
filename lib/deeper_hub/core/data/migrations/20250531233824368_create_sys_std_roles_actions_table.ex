# Migração gerada com ID único: V1748745504367 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysStdRolesActionsTable do
  # Migração gerada com ID único: V1748745504367 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_std_roles_actions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_std_roles_actions.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_std_roles_actions...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_std_roles_actions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE, -- Nome da ação, ex: 'manage_settings'
      title TEXT NOT NULL, -- Título amigável da ação
      description TEXT
    );

    CREATE INDEX IF NOT EXISTS idx_sys_std_roles_actions_name ON sys_std_roles_actions(name);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_std_roles_actions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_std_roles_actions: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_std_roles_actions.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_std_roles_actions...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_std_roles_actions;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_std_roles_actions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_std_roles_actions: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
