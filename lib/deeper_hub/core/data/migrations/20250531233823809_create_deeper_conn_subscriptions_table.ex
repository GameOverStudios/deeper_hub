# Migração gerada com ID único: V1748745503808 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperConnSubscriptionsTable do
  # Migração gerada com ID único: V1748745503808 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela deeper_conn_subscriptions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_conn_subscriptions.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela deeper_conn_subscriptions...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS deeper_conn_subscriptions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      initiator_id INTEGER NOT NULL, -- O seguidor
      content_id INTEGER NOT NULL,   -- O seguido
      added INTEGER NOT NULL,        -- Unix Timestamp

      UNIQUE (initiator_id, content_id),
      FOREIGN KEY (initiator_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (content_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_dcs_initiator_id ON deeper_conn_subscriptions(initiator_id);
    CREATE INDEX IF NOT EXISTS idx_dcs_content_id ON deeper_conn_subscriptions(content_id);
    -- Para listar quem um usuário segue: idx_dcs_initiator_id é suficiente.
    -- Para listar seguidores de um usuário: idx_dcs_content_id é suficiente.
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_conn_subscriptions criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela deeper_conn_subscriptions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela deeper_conn_subscriptions.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela deeper_conn_subscriptions...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS deeper_conn_subscriptions;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_conn_subscriptions removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela deeper_conn_subscriptions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end