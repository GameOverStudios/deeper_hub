# Migração gerada com ID único: V1748745503977 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperPollVotesTable do
  # Migração gerada com ID único: V1748745503977 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela deeper_poll_votes.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_poll_votes.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela deeper_poll_votes...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS deeper_poll_votes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      poll_id INTEGER NOT NULL,
      option_id INTEGER NOT NULL,
      profile_id INTEGER NOT NULL,
      voted_at INTEGER NOT NULL,
      UNIQUE (poll_id, profile_id, option_id), -- Garante que um usuário não vote na mesma opção múltiplas vezes
      FOREIGN KEY (poll_id) REFERENCES deeper_polls(id) ON DELETE CASCADE,
      FOREIGN KEY (option_id) REFERENCES deeper_poll_options(id) ON DELETE CASCADE,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_dpv_poll_id_profile_id ON deeper_poll_votes(poll_id, profile_id);
    CREATE INDEX IF NOT EXISTS idx_dpv_option_id ON deeper_poll_votes(option_id);
    CREATE INDEX IF NOT EXISTS idx_dpv_profile_id ON deeper_poll_votes(profile_id);
    """

    # Repo.execute("PRAGMA foreign_keys = ON;") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_poll_votes criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela deeper_poll_votes: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela deeper_poll_votes.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela deeper_poll_votes...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_poll_votes;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_poll_votes removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela deeper_poll_votes: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
