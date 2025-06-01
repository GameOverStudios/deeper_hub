# Migração gerada com ID único: V1748745504065 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysObjectsFormTable do
  # Migração gerada com ID único: V1748745504065 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_objects_form.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_objects_form.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_objects_form...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_form (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL UNIQUE,
      module TEXT NOT NULL,
      title TEXT NOT NULL,
      action TEXT NOT NULL,
      form_attrs TEXT,
      submit_name TEXT NOT NULL,
      "table" TEXT NOT NULL, -- Tabela do BD onde os dados são salvos
      "key" TEXT NOT NULL, -- Coluna da PK na 'table'
      uri TEXT, -- Coluna para URI/slug na 'table'
      uri_title TEXT, -- Coluna para o título usado para gerar o URI
      params TEXT,
      deletable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      active INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      parent_form TEXT,
      override_class_name TEXT,
      override_class_file TEXT
      -- FK para module (sys_modules.name)
    );

    CREATE INDEX IF NOT EXISTS idx_sys_objects_form_object ON sys_objects_form(object);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_form_module ON sys_objects_form(module);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_objects_form criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_objects_form: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_objects_form.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_objects_form...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_objects_form;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_objects_form removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_objects_form: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
