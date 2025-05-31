# Migração Elixir: Criar Tabela `bx_persons_votes_track`

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_votes_track` no banco de dados SQLite. Esta tabela rastreia os votos (geralmente avaliações numéricas, como estrelas) dados a perfis de pessoas.

**Dependências:** `sys_profiles`

## Código da Migração (`lib/deeper/content/persons/migrations/create_bx_persons_votes_track_table.ex`)

```elixir
defmodule Deeper.Content.Persons.Migrations.CreateBxPersonsVotesTrackTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_persons_votes_track.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_votes_track.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_votes_track...\", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_votes_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil votado)
      author_id INTEGER NOT NULL, -- FK para sys_profiles.id (quem votou)
      author_nip INTEGER NOT NULL, -- IP do autor como inteiro (no UNA é INT UNSIGNED)
      value INTEGER NOT NULL, -- O valor do voto, ex: 1 a 5. No UNA é TINYINT(4)
      date INTEGER NOT NULL, -- Unix Timestamp
      FOREIGN KEY (object_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    -- O índice `vote (object_id,author_nip)` do UNA.
    -- Um índice UNIQUE em (object_id, author_id) é comum para que um usuário só vote uma vez.
    CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_persons_vote_track_object_author ON bx_persons_votes_track(object_id, author_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_vote_track_author_id ON bx_persons_votes_track(author_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_votes_track criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_persons_votes_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_persons_votes_track.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_persons_votes_track...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS bx_persons_votes_track;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_votes_track removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_persons_votes_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`, `object_id`, `author_id`, `author_nip`, `date`: `INT` (MySQL) -> `INTEGER` (SQLite).
*   `value`: `TINYINT(4)` (MySQL) -> `INTEGER` (SQLite). Uma `CHECK` constraint poderia ser adicionada para limitar o range de `value` (ex: `CHECK(value >= 1 AND value <= 5)`).
*   **Índice Único:** Adicionado `uidx_bx_persons_vote_track_object_author` para garantir que um usuário só possa votar em um perfil uma vez. Se o sistema permitir mudar o voto, a lógica da aplicação faria um `UPDATE`.
*   **Chaves Estrangeiras:** Definidas para `object_id` e `author_id`.