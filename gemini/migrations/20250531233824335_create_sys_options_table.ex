# Migração gerada com ID único: V1748745504335 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysOptionsTable do
  # Migração gerada com ID único: V1748745504335 em 2025-05-31 23:38:24
  @moduledoc "Migração para criar a tabela sys_options."
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  def up do
    Logger.info("Criando tabela sys_options...", module: __MODULE__)
    # Repo.execute("PRAGMA foreign_keys = ON;")
    sql = """
    CREATE TABLE IF NOT EXISTS sys_options (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER NOT NULL,
      name TEXT NOT NULL UNIQUE,
      caption TEXT NOT NULL,
      info TEXT,
      value TEXT NOT NULL,
      type TEXT NOT NULL DEFAULT 'digit' CHECK(type IN (
        'value', 'digit', 'text', 'code', 'checkbox', 'select',
        'combobox', 'file', 'image', 'list', 'rlist', 'rgb', 'rgba', 'datetime'
      )),
      extra TEXT,
      "check" TEXT,
      check_params TEXT,
      check_error TEXT,
      "order" INTEGER DEFAULT 0,
      FOREIGN KEY (category_id) REFERENCES sys_options_categories(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_options_category_id ON sys_options(category_id);
    """

    # O índice em `name` é implicitamente criado pela constraint UNIQUE.
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
    |> tap(fn
      :ok ->
        Logger.info("Tabela sys_options criada com sucesso.", module: __MODULE__)

      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_options: #{inspect(reason)}", module: __MODULE__)
    end)
  end

  def down do
    Logger.info("Removendo tabela sys_options...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_options;"

    case Repo.execute(sql) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
    |> tap(fn
      :ok ->
        Logger.info("Tabela sys_options removida com sucesso.", module: __MODULE__)

      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_options: #{inspect(reason)}",
          module: __MODULE__
        )
    end)
  end
end
