defmodule Repo.Migrations.CreateBxPhotosMetaKeywordsCamera do
  use Ecto.Migration

  def change do
    create table(:bx_photos_meta_keywords_camera, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false
      add :keyword, :string, null: false
      timestamps()
    end
    create index(:bx_photos_meta_keywords_camera, [:object_id])
    create index(:bx_photos_meta_keywords_camera, [:keyword])
  end
end
