# Migração gerada com ID único: V1748745504090 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperCommentVotesTrackTable do
  # Migração gerada com ID único: V1748745504090 em 2025-05-31 23:38:24
  @moduledoc "Migração para criar a tabela deeper_comment_votes_track."
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  def up do
    Logger.info("Criando tabela deeper_comment_votes_track...", module: __MODULE__)
    # Repo.execute("PRAGMA foreign_keys = ON;")
    sql = """
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
    """
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela deeper_comment_votes_track criada com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao criar tabela deeper_comment_votes_track: #{inspect(reason)}", module: __MODULE__)
    end)
  end

  def down do
    Logger.info("Removendo tabela deeper_comment_votes_track...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_comment_votes_track;"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela deeper_comment_votes_track removida com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao remover tabela deeper_comment_votes_track: #{inspect(reason)}", module: __MODULE__)
    end)
  end
end