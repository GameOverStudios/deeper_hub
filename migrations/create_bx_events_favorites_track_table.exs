defmodule Repo.Migrations.CreateBxEventsFavoritesTrack do
  use Ecto.Migration

  def change do
    create table(:bx_events_favorites_track, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false, default: 0
      add :author_id, :integer, null: false, default: 0
      add :list_id, :integer, null: false, default: 0
      add :date, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_events_favorites_track, [:object_id])
  end
end
