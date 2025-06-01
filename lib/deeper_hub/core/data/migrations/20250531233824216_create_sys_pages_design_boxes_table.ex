# Migração gerada com ID único: V1748745504216 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysPagesDesignBoxesTable do
  # Migração gerada com ID único: V1748745504216 em 2025-05-31 23:38:24
  @moduledoc "Migração para criar a tabela sys_pages_design_boxes."
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  def up do
    Logger.info("Criando tabela sys_pages_design_boxes...", module: __MODULE__)
    sql = """
    CREATE TABLE IF NOT EXISTS sys_pages_design_boxes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      template TEXT NOT NULL,
      "order" INTEGER NOT NULL DEFAULT 0
    );
    """
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela sys_pages_design_boxes criada com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao criar tabela sys_pages_design_boxes: #{inspect(reason)}", module: __MODULE__)
    end)
  end

  def down do
    Logger.info("Removendo tabela sys_pages_design_boxes...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_pages_design_boxes;"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela sys_pages_design_boxes removida com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao remover tabela sys_pages_design_boxes: #{inspect(reason)}", module: __MODULE__)
    end)
  end
end