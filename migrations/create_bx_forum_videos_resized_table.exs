defmodule Repo.Migrations.CreateBxForumVideosResized do
  use Ecto.Migration

  def change do
    create table(:bx_forum_videos_resized, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false
      add :remote_id, :string, null: false
      add :path, :string, null: false
      add :file_name, :string, null: false
      add :mime_type, :string, null: false
      add :ext, :string, null: false
      add :size, :integer, null: false
      add :added, :integer, null: false
      add :modified, :integer, null: false
      add :private, :integer, null: false
      timestamps()
    end
    create index(:bx_forum_videos_resized, [:remote_id], unique: true)
  end
end
