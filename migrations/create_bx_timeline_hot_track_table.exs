defmodule Repo.Migrations.CreateBxTimelineHotTrack do
  use Ecto.Migration

  def change do
    create table(:bx_timeline_hot_track, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_id, :integer, null: false, default: 0
      add :value, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_timeline_hot_track, [:event_id], unique: true)
  end
end
