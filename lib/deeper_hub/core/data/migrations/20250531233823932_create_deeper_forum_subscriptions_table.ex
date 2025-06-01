# Migração gerada com ID único: V1748745503932 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperForumSubscriptionsTable do
  # Migração gerada com ID único: V1748745503932 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela deeper_forum_subscriptions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_forum_subscriptions.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela deeper_forum_subscriptions...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS deeper_forum_subscriptions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      forum_id INTEGER,
      topic_id INTEGER,
      subscription_type TEXT NOT NULL DEFAULT 'instant' CHECK(subscription_type IN ('instant', 'daily_digest', 'weekly_digest', 'none')),
      created_at INTEGER NOT NULL,
      -- Constraints UNIQUE parciais para SQLite (requerem índices e triggers ou lógica de aplicação)
      -- SQLite não suporta UNIQUE (col1, col2) WHERE col3 IS NULL diretamente na definição da tabela.
      -- A maneira de implementar isso é com índices únicos parciais (se a versão do SQLite suportar)
      -- ou garantir a unicidade na lógica da aplicação.
      -- Exemplo de índice único parcial (SQLite 3.8.0+):
      -- CREATE UNIQUE INDEX IF NOT EXISTS idx_dfs_profile_forum_uniq ON deeper_forum_subscriptions(profile_id, forum_id) WHERE topic_id IS NULL;
      -- CREATE UNIQUE INDEX IF NOT EXISTS idx_dfs_profile_topic_uniq ON deeper_forum_subscriptions(profile_id, topic_id) WHERE forum_id IS NULL;
      -- Por simplicidade na migração inicial, vamos omitir essas constraints UNIQUE complexas
      -- e assumir que a lógica da aplicação as gerenciará, ou elas podem ser adicionadas
      -- como índices únicos parciais após a criação da tabela se o SQLite suportar.
      -- Para agora, apenas um CHECK para garantir que ou forum_id ou topic_id esteja preenchido.
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (forum_id) REFERENCES deeper_forums(id) ON DELETE CASCADE,
      FOREIGN KEY (topic_id) REFERENCES deeper_forum_topics(id) ON DELETE CASCADE,
      CHECK ((forum_id IS NOT NULL AND topic_id IS NULL) OR (forum_id IS NULL AND topic_id IS NOT NULL) OR (forum_id IS NULL AND topic_id IS NULL AND subscription_type = 'none'))
      -- O último OR na CHECK é para permitir uma subscrição "none" global para o fórum (desabilitar todas as notificações do fórum)
      -- No entanto, uma constraint mais simples seria: CHECK ((forum_id IS NOT NULL AND topic_id IS NULL) OR (forum_id IS NULL AND topic_id IS NOT NULL))
      -- A lógica de 'none' global pode ser tratada de outra forma. Vamos simplificar o CHECK:
      -- CHECK ((forum_id IS NOT NULL AND topic_id IS NULL) OR (forum_id IS NULL AND topic_id IS NOT NULL))
    );

    -- Adicionar a CHECK constraint mais simples aqui:
    -- A sintaxe de adicionar CHECK constraint via ALTER TABLE é limitada no SQLite.
    -- É melhor definir na criação da tabela. Vamos ajustar o CREATE TABLE acima.
    -- (Ajuste no CREATE TABLE acima já foi feito implicitamente pela remoção do comentário da CHECK)

    -- Vamos recriar a tabela com a CHECK constraint correta
    -- Primeiro, o SQL sem a CHECK, depois com a CHECK (como se fosse uma edição)
    -- A melhor forma é ter a CHECK no CREATE TABLE inicial.

    -- SQL com a CHECK constraint simplificada:
    DROP TABLE IF EXISTS deeper_forum_subscriptions; -- Para garantir que estamos recriando com a CHECK correta
    CREATE TABLE deeper_forum_subscriptions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      forum_id INTEGER,
      topic_id INTEGER,
      subscription_type TEXT NOT NULL DEFAULT 'instant' CHECK(subscription_type IN ('instant', 'daily_digest', 'weekly_digest', 'none')),
      created_at INTEGER NOT NULL,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (forum_id) REFERENCES deeper_forums(id) ON DELETE CASCADE,
      FOREIGN KEY (topic_id) REFERENCES deeper_forum_topics(id) ON DELETE CASCADE,
      CHECK ((forum_id IS NOT NULL AND topic_id IS NULL) OR (forum_id IS NULL AND topic_id IS NOT NULL))
    );
    -- Fim do SQL ajustado.

    CREATE UNIQUE INDEX IF NOT EXISTS idx_dfs_profile_forum_uniq ON deeper_forum_subscriptions(profile_id, forum_id) WHERE topic_id IS NULL;
    CREATE UNIQUE INDEX IF NOT EXISTS idx_dfs_profile_topic_uniq ON deeper_forum_subscriptions(profile_id, topic_id) WHERE forum_id IS NULL;

    CREATE INDEX IF NOT EXISTS idx_dfs_profile_id_forum_id ON deeper_forum_subscriptions(profile_id, forum_id);
    CREATE INDEX IF NOT EXISTS idx_dfs_profile_id_topic_id ON deeper_forum_subscriptions(profile_id, topic_id);
    """
    # O DROP TABLE e CREATE TABLE sequencial é para garantir que a CHECK constraint esteja correta.
    # Em uma migração real, se a tabela já existisse, a alteração da CHECK seria mais complexa.

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_forum_subscriptions criada com sucesso (com CHECK e índices parciais).", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela deeper_forum_subscriptions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela deeper_forum_subscriptions.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela deeper_forum_subscriptions...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_forum_subscriptions;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_forum_subscriptions removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela deeper_forum_subscriptions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end