defmodule Repo.Migrations.CreateSysTranscoderImagesFiles do
  use Ecto.Migration

  def change do
    create table(:sys_transcoder_images_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :transcoder_object, :string, null: false
      add :file_id, :integer, null: false
      add :handler, :string, null: false
      add :atime, :integer, null: false
      add :data, :string, null: false
      timestamps()
    end
    create index(:sys_transcoder_images_files, [:transcoder_object])
    create index(:sys_transcoder_images_files, [:file_id])
    create index(:sys_transcoder_images_files, [:atime])
  end
end
