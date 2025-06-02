defmodule Repo.Migrations.CreateBxFilesBookmarks do
  use Ecto.Migration

  def change do
    create table(:bx_files_bookmarks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false, default: 0
      add :profile_id, :integer, null: false, default: 0
      timestamps()
    end
  end
end
