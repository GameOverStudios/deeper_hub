defmodule Repo.Migrations.CreateBxAlbumsViewsMediaTrack do
  use Ecto.Migration

  def change do
    create table(:bx_albums_views_media_track, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false, default: 0
      add :viewer_id, :integer, null: false, default: 0
      add :viewer_nip, :integer, null: false, default: 0
      add :date, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_albums_views_media_track, [:object_id])
  end
end
