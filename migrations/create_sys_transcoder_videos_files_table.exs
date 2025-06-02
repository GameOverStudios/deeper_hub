defmodule Repo.Migrations.CreateSysTranscoderVideosFiles do
  use Ecto.Migration

  def change do
    create table(:sys_transcoder_videos_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :transcoder_object, :string, null: false
      add :file_id, :integer, null: false
      add :handler, :string, null: false
      add :atime, :integer, null: false
      timestamps()
    end
    create index(:sys_transcoder_videos_files, [:transcoder_object])
    create index(:sys_transcoder_videos_files, [:file_id])
    create index(:sys_transcoder_videos_files, [:atime])
  end
end
