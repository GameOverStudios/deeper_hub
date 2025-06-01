# Migração gerada com ID único: V1748745504345 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysRewriteRulesTable do
  # Migração gerada com ID único: V1748745504345 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_rewrite_rules.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_rewrite_rules.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_rewrite_rules...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_rewrite_rules (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      preg TEXT NOT NULL, -- Expressão regular
      service TEXT NOT NULL, -- Chamada de serviço PHP serializada
      active INTEGER NOT NULL DEFAULT 1 -- 0 ou 1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_rewrite_rules criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_rewrite_rules: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_rewrite_rules.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_rewrite_rules...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_rewrite_rules;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_rewrite_rules removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_rewrite_rules: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end