# Migração gerada com ID único: V1748745504279 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysLocalizationKeysTable do
  # Migração gerada com ID único: V1748745504279 em 2025-05-31 23:38:24
  @moduledoc "Migração para criar a tabela sys_localization_keys."
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  def up do
    Logger.info("Criando tabela sys_localization_keys...", module: __MODULE__)
    # Repo.execute("PRAGMA foreign_keys = ON;")
    sql = """
    CREATE TABLE IF NOT EXISTS sys_localization_keys (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      IDCategory INTEGER NOT NULL,
      "Key" TEXT NOT NULL UNIQUE,
      FOREIGN KEY (IDCategory) REFERENCES sys_localization_categories(ID) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_localization_keys_idcategory ON sys_localization_keys(IDCategory);
    """
    # O índice em "Key" é criado pela constraint UNIQUE.
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela sys_localization_keys criada com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao criar tabela sys_localization_keys: #{inspect(reason)}", module: __MODULE__)
    end)
  end

  def down do
    Logger.info("Removendo tabela sys_localization_keys...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_localization_keys;"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela sys_localization_keys removida com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao remover tabela sys_localization_keys: #{inspect(reason)}", module: __MODULE__)
    end)
  end
end