# Migração gerada com ID único: V1748745504195 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysMenuSetsTable do
  # Migração gerada com ID único: V1748745504195 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_menu_sets.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_menu_sets.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_menu_sets...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_menu_sets (
      set_name TEXT PRIMARY KEY NOT NULL,
      module TEXT NOT NULL,
      title TEXT NOT NULL,
      deletable INTEGER NOT NULL DEFAULT 1 -- 0 ou 1
    );

    CREATE INDEX IF NOT EXISTS idx_sys_menu_sets_module ON sys_menu_sets(module);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_menu_sets criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_menu_sets: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_menu_sets.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_menu_sets...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_menu_sets;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_menu_sets removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_menu_sets: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
