defmodule Repo.Migrations.CreateBxStoriesEntriesMedia do
  use Ecto.Migration

  def change do
    create table(:bx_stories_entries_media, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content_id, :integer, null: false
      add :file_id, :integer, null: false
      add :author, :integer, null: false
      add :title, :string, null: false
      add :cf, :integer, null: false, default: 1
      add :data, :string, null: false
      add :order, :integer, null: false
      timestamps()
    end
    create index(:bx_stories_entries_media, [:content_id])
    create index(:bx_stories_entries_media, [:file_id])
    create index(:bx_stories_entries_media, [:title])
  end
end
