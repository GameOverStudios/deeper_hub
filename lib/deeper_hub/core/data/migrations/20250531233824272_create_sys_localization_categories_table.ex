# Migração gerada com ID único: V1748745504271 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysLocalizationCategoriesTable do
  # Migração gerada com ID único: V1748745504271 em 2025-05-31 23:38:24
  @moduledoc "Migração para criar a tabela sys_localization_categories."
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  def up do
    Logger.info("Criando tabela sys_localization_categories...", module: __MODULE__)
    sql = """
    CREATE TABLE IF NOT EXISTS sys_localization_categories (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Name TEXT NOT NULL UNIQUE
    );
    """
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela sys_localization_categories criada com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao criar tabela sys_localization_categories: #{inspect(reason)}", module: __MODULE__)
    end)
  end

  def down do
    Logger.info("Removendo tabela sys_localization_categories...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_localization_categories;"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela sys_localization_categories removida com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao remover tabela sys_localization_categories: #{inspect(reason)}", module: __MODULE__)
    end)
  end
end