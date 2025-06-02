defmodule Repo.Migrations.CreateBxStoriesScoresTrack do
  use Ecto.Migration

  def change do
    create table(:bx_stories_scores_track, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false, default: 0
      add :author_id, :integer, null: false, default: 0
      add :author_nip, :integer, null: false, default: 0
      add :type, :string, null: false, default: ""
      add :date, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_stories_scores_track, [:object_id])
  end
end
