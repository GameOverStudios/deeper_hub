# Migração gerada com ID único: V1748745504247 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysAclLevelsMembersTable do
  # Migração gerada com ID único: V1748745504247 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_acl_levels_members.
  Depende da existência das tabelas `sys_accounts` e `sys_acl_levels`.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_acl_levels_members.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_acl_levels_members...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_acl_levels_members (
      IDMember INTEGER NOT NULL,
      IDLevel INTEGER NOT NULL,
      DateStarts INTEGER NOT NULL, -- Unix Timestamp
      DateExpires INTEGER, -- Unix Timestamp, NULL para nunca expirar
      State TEXT DEFAULT '' CHECK(State IN ('', 'active', 'pending', 'expired')),
      TransactionID TEXT,
      PRIMARY KEY (IDMember, IDLevel, DateStarts),
      FOREIGN KEY (IDMember) REFERENCES sys_accounts(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (IDLevel) REFERENCES sys_acl_levels(ID) ON DELETE CASCADE ON UPDATE CASCADE
    );
    """

    # Habilitar FKs se necessário para esta sessão/transação de migração
    # Repo.execute("PRAGMA foreign_keys = ON;")

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_acl_levels_members criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_acl_levels_members: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_acl_levels_members.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_acl_levels_members...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_acl_levels_members;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_acl_levels_members removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_acl_levels_members: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
