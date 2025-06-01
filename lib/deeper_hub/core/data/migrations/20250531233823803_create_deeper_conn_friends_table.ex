# Migração gerada com ID único: V1748745503803 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperConnFriendsTable do
  # Migração gerada com ID único: V1748745503803 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela deeper_conn_friends.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_conn_friends.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela deeper_conn_friends...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS deeper_conn_friends (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      initiator_id INTEGER NOT NULL,
      content_id INTEGER NOT NULL,
      mutual INTEGER NOT NULL DEFAULT 0 CHECK(mutual IN (0,1)), -- 0: pending, 1: mutual
      added INTEGER NOT NULL, -- Unix Timestamp

      UNIQUE (initiator_id, content_id),
      FOREIGN KEY (initiator_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (content_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_dcf_initiator_content_mutual ON deeper_conn_friends(initiator_id, content_id, mutual);
    CREATE INDEX IF NOT EXISTS idx_dcf_content_initiator_mutual ON deeper_conn_friends(content_id, initiator_id, mutual);
    -- Adicionar um índice para listar amigos de um usuário rapidamente:
    -- CREATE INDEX idx_dcf_friends_of_initiator ON deeper_conn_friends(initiator_id, mutual) WHERE mutual = 1;
    -- CREATE INDEX idx_dcf_friends_of_content ON deeper_conn_friends(content_id, mutual) WHERE mutual = 1;
    -- SQLite partial indexes (WHERE clause) são úteis aqui.
    """

    # Nota: A constraint UNIQUE (initiator_id, content_id) garante que um perfil não pode enviar múltiplas
    # solicitações para o mesmo perfil, ou ter múltiplas entradas de amizade na mesma "direção".
    # A lógica da aplicação deve gerenciar a representação de amizades mútuas
    # (ex: uma única linha com IDs ordenados, ou duas linhas marcadas como mutual=1).
    # Para simplificar as queries de "listar amigos", a lógica de criar/aceitar amizade
    # pode precisar garantir que, para um par (A,B), se A < B, a entrada seja sempre (A,B,1).
    # Ou, ao listar amigos de X, buscar por (X, Y, 1) OR (Y, X, 1).

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_conn_friends criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela deeper_conn_friends: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela deeper_conn_friends.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela deeper_conn_friends...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS deeper_conn_friends;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_conn_friends removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela deeper_conn_friends: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end