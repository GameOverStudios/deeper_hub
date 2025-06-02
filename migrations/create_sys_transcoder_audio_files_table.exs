defmodule Repo.Migrations.CreateSysTranscoderAudioFiles do
  use Ecto.Migration

  def change do
    create table(:sys_transcoder_audio_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :transcoder_object, :string, null: false
      add :file_id, :integer, null: false
      add :handler, :string, null: false
      add :atime, :integer, null: false
      timestamps()
    end
    create index(:sys_transcoder_audio_files, [:transcoder_object])
    create index(:sys_transcoder_audio_files, [:file_id])
    create index(:sys_transcoder_audio_files, [:atime])
  end
end
