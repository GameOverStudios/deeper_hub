# Migração gerada com ID único: V1748745503824 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateBxOrganizationsCategoriesTable do
  # Migração gerada com ID único: V1748745503824 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela bx_organizations_categories.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela bx_organizations_categories.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela bx_organizations_categories...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_organizations_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parent_id INTEGER NOT NULL DEFAULT 0,
      name TEXT NOT NULL,
      title TEXT NOT NULL,
      uri TEXT NOT NULL,
      order_index INTEGER NOT NULL DEFAULT 0
    );

    CREATE INDEX IF NOT EXISTS idx_bx_org_cat_parent_id ON bx_organizations_categories(parent_id);
    CREATE UNIQUE INDEX IF NOT EXISTS idx_bx_org_cat_name ON bx_organizations_categories(name);
    CREATE UNIQUE INDEX IF NOT EXISTS idx_bx_org_cat_uri ON bx_organizations_categories(uri);
    """
    # Nota: 'name' e 'uri' devem ser únicos. 'title' pode ser uma chave de tradução.

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_organizations_categories criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela bx_organizations_categories: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela bx_organizations_categories.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela bx_organizations_categories...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS bx_organizations_categories;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_organizations_categories removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela bx_organizations_categories: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end