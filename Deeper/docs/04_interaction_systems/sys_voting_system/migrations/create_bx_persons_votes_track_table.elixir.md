# Migração Elixir: Criar Tabela `bx_persons_votes_track` (Rastreamento de Votos para Pessoas)

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_votes_track` no banco de dados SQLite. Esta tabela armazena os votos individuais dados por usuários aos perfis de pessoas.

Esta é um exemplo de uma tabela `TableTrack` referenciada em `sys_objects_vote`.

## Código da Migração (`lib/deeper/core/data/migrations/create_bx_persons_votes_track_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateBxPersonsVotesTrackTable do
  @moduledoc \"\"\"
  Migração para criar a tabela de rastreamento de votos bx_persons_votes_track.
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

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_votes_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- FK para bx_persons_data.id
      author_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) do votante
      author_nip INTEGER, -- IP do votante como inteiro (originalmente INT UNSIGNED)
      value INTEGER NOT NULL, -- O voto (ex: 1-5)
      date INTEGER NOT NULL -- Unix Timestamp
      -- Considerar: UNIQUE (object_id, author_id) se um usuário só pode votar uma vez.
      -- Depende da configuração IsUndo e PostTimeout em sys_objects_vote.
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_votes_track_obj_author ON bx_persons_votes_track(object_id, author_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_votes_track_author_obj ON bx_persons_votes_track(author_id, object_id);
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

## Notas:

*   `object_id`: Corresponde ao `id` da tabela `bx_persons_data`.
*   `author_id`: Corresponde ao `id` da tabela `sys_profiles` do usuário que votou.
*   `author_nip`: IP do votante, convertido para inteiro.
*   `value`: A nota/voto dado.
*   `date`: Timestamp do voto.