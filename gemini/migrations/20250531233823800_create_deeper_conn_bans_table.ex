# Migração gerada com ID único: V1748745503782 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperConnBansTable do
  # Migração gerada com ID único: V1748745503782 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela deeper_conn_bans.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_conn_bans.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela deeper_conn_bans...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS deeper_conn_bans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      initiator_id INTEGER NOT NULL, -- Quem bloqueou
      content_id INTEGER NOT NULL,   -- Quem foi bloqueado
      added INTEGER NOT NULL,        -- Unix Timestamp

      UNIQUE (initiator_id, content_id),
      FOREIGN KEY (initiator_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (content_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_dcb_initiator_id ON deeper_conn_bans(initiator_id);
    CREATE INDEX IF NOT EXISTS idx_dcb_content_id ON deeper_conn_bans(content_id);
    -- Para verificar se X bloqueou Y: idx_dcb_initiator_id + content_id na cláusula WHERE
    -- Para verificar se Y foi bloqueado por X: idx_dcb_content_id + initiator_id na cláusula WHERE
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_conn_bans criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela deeper_conn_bans: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela deeper_conn_bans.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela deeper_conn_bans...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS deeper_conn_bans;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_conn_bans removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela deeper_conn_bans: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
