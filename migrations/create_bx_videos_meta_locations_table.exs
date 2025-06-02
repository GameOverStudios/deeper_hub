defmodule Repo.Migrations.CreateBxVideosMetaLocations do
  use Ecto.Migration

  def change do
    create table(:bx_videos_meta_locations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false
      add :lat, :float, null: false
      add :lng, :float, null: false
      add :country, :string, null: false
      add :state, :string, null: false
      add :city, :string, null: false
      add :zip, :string, null: false
      add :street, :string, null: false
      add :street_number, :string, null: false
      timestamps()
    end
    create index(:bx_videos_meta_locations, [:country])
  end
end
