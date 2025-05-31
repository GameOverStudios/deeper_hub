# Migração Elixir: Criar Tabela `deeper_comment_votes_track`

Este módulo de migração Elixir cria a tabela `deeper_comment_votes_track` no SQLite. Esta tabela é usada para rastrear votos, reações, ou outras interações (como denúncias específicas) em comentários individuais.

## Código da Migração (`lib/deeper/core/data/migrations/interaction_systems/comments/create_deeper_comment_votes_track_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.InteractionSystems.Comments.CreateDeeperCommentVotesTrackTable do
  @moduledoc \"Migração para criar a tabela deeper_comment_votes_track.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_comment_votes_track...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_comment_votes_track (
      comment_id INTEGER NOT NULL,
      voter_profile_id INTEGER NOT NULL,
      vote_type TEXT NOT NULL DEFAULT 'score' CHECK(vote_type IN ('score', 'reaction', 'report_type')),
      value INTEGER NOT NULL,
      voted_at INTEGER NOT NULL,
      PRIMARY KEY (comment_id, voter_profile_id, vote_type),
      FOREIGN KEY (comment_id) REFERENCES deeper_comments(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (voter_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );
    -- Índices adicionais podem ser úteis dependendo das queries, mas a PK cobre o caso mais comum.
    CREATE INDEX IF NOT EXISTS idx_dcvt_voter_comment ON deeper_comment_votes_track(voter_profile_id, comment_id);
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_comment_votes_track criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela deeper_comment_votes_track: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_comment_votes_track...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_comment_votes_track;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_comment_votes_track removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela deeper_comment_votes_track: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```