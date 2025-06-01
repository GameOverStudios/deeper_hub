# Migração Elixir: Criar Tabela `deeper_forum_read_topics`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_forum_read_topics` no banco de dados SQLite. Esta tabela rastreia o último post lido por um usuário em um tópico específico, ajudando a UI a indicar conteúdo novo.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_forum_read_topics_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperForumReadTopicsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_forum_read_topics.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_forum_read_topics.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_forum_read_topics...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_forum_read_topics (
      profile_id INTEGER NOT NULL,
      topic_id INTEGER NOT NULL,
      last_read_post_id INTEGER NOT NULL,
      last_read_at INTEGER NOT NULL,
      PRIMARY KEY (profile_id, topic_id),
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (topic_id) REFERENCES deeper_forum_topics(id) ON DELETE CASCADE,
      FOREIGN KEY (last_read_post_id) REFERENCES deeper_forum_posts(id) ON DELETE CASCADE
    );
    \"\"\"
    # Não são necessários índices adicionais além da chave primária composta,
    # a menos que haja queries específicas que não a utilizem bem.

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_forum_read_topics criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_forum_read_topics: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_forum_read_topics.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_forum_read_topics...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_forum_read_topics;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_forum_read_topics removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_forum_read_topics: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Depende de `sys_profiles`, `deeper_forum_topics`, e `deeper_forum_posts`.
*   A chave primária `(profile_id, topic_id)` garante que haja apenas um registro de \"lido\" por usuário por tópico.
*   `ON DELETE CASCADE` garante que os registros de leitura sejam limpos se o perfil, tópico ou o post específico lido forem excluídos. A FK para `last_read_post_id` com `ON DELETE CASCADE` é importante; se um post que foi o \"último lido\" for excluído, essa entrada de rastreamento de leitura também deve ser removida para evitar referências órfãs.