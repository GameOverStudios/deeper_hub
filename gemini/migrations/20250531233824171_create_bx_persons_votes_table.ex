# Migração gerada com ID único: V1748745504171 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateBxPersonsVotesTable do
  # Migração gerada com ID único: V1748745504171 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela de agregação de votos bx_persons_votes.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela bx_persons_votes.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela bx_persons_votes...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_persons_votes (
      object_id INTEGER PRIMARY KEY, -- FK para bx_persons_data.id
      count INTEGER NOT NULL DEFAULT 0,
      sum INTEGER NOT NULL DEFAULT 0
      -- No schema original do UNA, esta tabela não tem uma FK explícita para bx_persons_data
      -- mas o object_id refere-se a bx_persons_data.id.
      -- Poderíamos adicionar: FOREIGN KEY (object_id) REFERENCES bx_persons_data(id) ON DELETE CASCADE
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_votes criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela bx_persons_votes: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela bx_persons_votes.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela bx_persons_votes...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS bx_persons_votes;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_votes removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela bx_persons_votes: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
