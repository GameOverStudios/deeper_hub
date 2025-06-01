# Migração Elixir: Criar Tabela `bx_persons_scores_track` (Rastreamento de Scores para Pessoas)

Este módulo de migração Elixir cria a tabela `bx_persons_scores_track` no SQLite, para armazenar os votos individuais (up/down) dados por usuários aos perfis de pessoas.

Esta é um exemplo de uma tabela `table_track` referenciada em `sys_objects_score`.

## Código da Migração (`lib/deeper/core/data/migrations/create_bx_persons_scores_track_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateBxPersonsScoresTrackTable do
  @moduledoc \"\"\"
  Migração para criar a tabela de rastreamento de scores bx_persons_scores_track.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_scores_track.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_scores_track...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_scores_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- FK para bx_persons_data.id
      author_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) do votante
      author_nip INTEGER, -- IP como inteiro (originalmente INT UNSIGNED)
      type TEXT NOT NULL CHECK(type IN ('up', 'down')),
      date INTEGER NOT NULL, -- Unix Timestamp
      -- Garante que um usuário só pode ter um tipo de voto (up/down) por objeto.
      -- Se um usuário muda de 'up' para 'down', o registro antigo é substituído ou atualizado.
      UNIQUE (object_id, author_id)
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_scores_track_obj_author ON bx_persons_scores_track(object_id, author_id);
    -- O índice idx_bx_persons_scores_track_author_obj (author_id, object_id) também pode ser útil
    -- se precisarmos buscar todos os scores dados por um autor.
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_scores_track criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_persons_scores_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_persons_scores_track.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_persons_scores_track...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS bx_persons_scores_track;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_scores_track removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_persons_scores_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   `object_id`: Corresponde ao `id` da tabela `bx_persons_data`.
*   `author_id`: Corresponde ao `id` da tabela `sys_profiles` do usuário que votou.
*   `type`: `'up'` ou `'down'`.
*   `date`: Timestamp do voto.
*   A restrição `UNIQUE (object_id, author_id)` é crucial para a lógica de permitir que um usuário tenha apenas um estado de voto (up, down, ou nenhum) para um objeto. Se o usuário votar novamente, o voto anterior é efetivamente alterado ou removido.