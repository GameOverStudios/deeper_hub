defmodule Repo.Migrations.CreateBxPollsVotesTrack do
  use Ecto.Migration

  def change do
    create table(:bx_polls_votes_track, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false, default: 0
      add :author_id, :integer, null: false, default: 0
      add :author_nip, :integer, null: false, default: 0
      add :value, :integer, null: false, default: 0
      add :date, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_polls_votes_track, [:object_id])
  end
end
