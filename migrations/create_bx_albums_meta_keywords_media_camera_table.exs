defmodule Repo.Migrations.CreateBxAlbumsMetaKeywordsMediaCamera do
  use Ecto.Migration

  def change do
    create table(:bx_albums_meta_keywords_media_camera, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false
      add :keyword, :string, null: false
      timestamps()
    end
    create index(:bx_albums_meta_keywords_media_camera, [:object_id])
    create index(:bx_albums_meta_keywords_media_camera, [:keyword])
  end
end
