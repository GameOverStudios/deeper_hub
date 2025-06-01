# Migração gerada com ID único: V1748745504234 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysAclActionsTable do
  # Migração gerada com ID único: V1748745504234 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_acl_actions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_acl_actions.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_acl_actions...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_acl_actions (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Module TEXT NOT NULL,
      Name TEXT NOT NULL,
      AdditionalParamName TEXT,
      Title TEXT NOT NULL,
      "Desc" TEXT,
      Countable INTEGER NOT NULL DEFAULT 0,
      DisabledForLevels INTEGER NOT NULL DEFAULT 3
    );

    -- Este índice garante que a combinação de Módulo, Nome da Ação,
    -- e Parâmetro Adicional (se houver) seja única.
    -- SQLite trata NULL como diferente de outros NULLs em UNIQUE constraints,
    -- o que é o comportamento desejado aqui.
    CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_acl_actions_module_name_param
    ON sys_acl_actions(Module, Name, AdditionalParamName);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_acl_actions criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_acl_actions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_acl_actions.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_acl_actions...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_acl_actions;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_acl_actions removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_acl_actions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end