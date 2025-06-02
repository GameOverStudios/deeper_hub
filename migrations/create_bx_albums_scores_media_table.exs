defmodule Repo.Migrations.CreateBxAlbumsScoresMedia do
  use Ecto.Migration

  def change do
    create table(:bx_albums_scores_media, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false, default: 0
      add :count_up, :integer, null: false, default: 0
      add :count_down, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_albums_scores_media, [:object_id], unique: true)
  end
end
