# Migração gerada com ID único: V1748745504059 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysFormPreValuesTable do
  # Migração gerada com ID único: V1748745504059 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_form_pre_values.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_form_pre_values.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_form_pre_values...", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS sys_form_pre_values (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      "Key" TEXT NOT NULL, -- Chave da lista (FK para sys_form_pre_lists."key")
      "Value" TEXT NOT NULL, -- Valor real do item da lista
      "Order" INTEGER NOT NULL DEFAULT 0,
      LKey TEXT NOT NULL, -- Chave de linguagem para a exibição do item
      LKey2 TEXT, -- Segunda chave de linguagem (opcional)
      Data TEXT, -- Dados adicionais (JSON ou string serializada)
      FOREIGN KEY ("Key") REFERENCES sys_form_pre_lists("key") ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_form_pre_values_key_order ON sys_form_pre_values("Key", "Order");
    -- Para garantir que um valor não seja duplicado dentro da mesma chave (opcional, depende da lógica do UNA)
    -- CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_form_pre_values_key_value ON sys_form_pre_values("Key", "Value");
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_form_pre_values criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_form_pre_values: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_form_pre_values.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_form_pre_values...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_form_pre_values;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_form_pre_values removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_form_pre_values: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end