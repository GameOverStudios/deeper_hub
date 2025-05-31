# Migração Elixir: Criar Tabela `bx_persons_views_track`

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_views_track` no banco de dados SQLite. Esta tabela rastreia as visualizações dos perfis de pessoas.

**Dependências:** `sys_profiles`

## Código da Migração (`lib/deeper/content/persons/migrations/create_bx_persons_views_track_table.ex`)

```elixir
defmodule Deeper.Content.Persons.Migrations.CreateBxPersonsViewsTrackTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_persons_views_track.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_views_track.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_views_track...\", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_views_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil que foi visto)
      viewer_id INTEGER NOT NULL DEFAULT 0, -- FK (condicional) para sys_profiles.id (o perfil do visualizador, 0 se anônimo)
      viewer_nip INTEGER, -- IP do visualizador como inteiro (convertido de VARCHAR)
      date INTEGER NOT NULL, -- Unix Timestamp
      FOREIGN KEY (object_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
      -- A FK para viewer_id não é estrita se viewer_id pode ser 0.
      -- Se viewer_id > 0, FOREIGN KEY (viewer_id) REFERENCES sys_profiles(id) ON DELETE SET DEFAULT ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_views_track_object_id ON bx_persons_views_track(object_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_views_track_viewer_id_date ON bx_persons_views_track(viewer_id, date) WHERE viewer_id != 0;
    CREATE INDEX IF NOT EXISTS idx_bx_persons_views_track_date ON bx_persons_views_track(date);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_views_track criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_persons_views_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_persons_views_track.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_persons_views_track...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS bx_persons_views_track;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_views_track removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_persons_views_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`, `object_id`, `viewer_id`, `date`: `INT` (MySQL) -> `INTEGER` (SQLite). `date` é um Timestamp Unix.
*   `viewer_nip`: `INT UNSIGNED` (MySQL, após conversão de IP string) -> `INTEGER` (SQLite).
*   **Chave Estrangeira para `viewer_id`:** Como `viewer_id` pode ser `0` para visualizadores anônimos, uma FK estrita para `sys_profiles.id` (que não teria um perfil com ID 0) não é apropriada sem lógica adicional. A FK para `object_id` é direta. Se uma FK for desejada para `viewer_id` quando ele não for 0, ela pode ser adicionada com uma condição ou gerenciada pela aplicação. `ON DELETE SET DEFAULT` (para `0`) poderia ser uma opção se o SQLite e a lógica suportarem.