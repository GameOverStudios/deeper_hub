defmodule Repo.Migrations.CreateBxTimelineRepostsTrack do
  use Ecto.Migration

  def change do
    create table(:bx_timeline_reposts_track, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_id, :integer, null: false, default: 0
      add :author_id, :integer, null: false, default: 0
      add :author_nip, :integer, null: false, default: 0
      add :reposted_id, :integer, null: false, default: 0
      add :date, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 1
      timestamps()
    end
    create index(:bx_timeline_reposts_track, [:event_id], unique: true)
    create index(:bx_timeline_reposts_track, [:reposted_id])
  end
end
