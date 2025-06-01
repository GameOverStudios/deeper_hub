# Migração gerada com ID único: V1748745504200 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysMenuTemplatesTable do
  # Migração gerada com ID único: V1748745504200 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_menu_templates.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_menu_templates.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_menu_templates...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_menu_templates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      template TEXT NOT NULL UNIQUE,
      title TEXT NOT NULL,
      visible INTEGER NOT NULL DEFAULT 1 -- 0 ou 1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_menu_templates criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_menu_templates: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_menu_templates.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_menu_templates...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_menu_templates;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_menu_templates removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_menu_templates: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
