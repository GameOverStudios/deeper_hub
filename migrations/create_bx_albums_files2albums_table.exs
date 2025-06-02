defmodule Repo.Migrations.CreateBxAlbumsFiles2albums do
  use Ecto.Migration

  def change do
    create table(:bx_albums_files2albums, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content_id, :integer, null: false
      add :file_id, :integer, null: false
      add :author, :integer, null: false
      add :title, :string, null: false
      add :views, :integer, null: false
      add :rate, :float, null: false
      add :votes, :integer, null: false
      add :score, :integer, null: false, default: 0
      add :sc_up, :integer, null: false, default: 0
      add :sc_down, :integer, null: false, default: 0
      add :favorites, :integer, null: false, default: 0
      add :comments, :integer, null: false
      add :reports, :integer, null: false, default: 0
      add :featured, :integer, null: false, default: 0
      add :cf, :integer, null: false, default: 1
      add :data, :string, null: false
      add :exif, :string, null: false
      add :order, :integer, null: false
      timestamps()
    end
    create index(:bx_albums_files2albums, [:content_id])
    create index(:bx_albums_files2albums, [:file_id])
    create index(:bx_albums_files2albums, [:title])
  end
end
