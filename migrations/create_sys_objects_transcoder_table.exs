defmodule Repo.Migrations.CreateSysObjectsTranscoder do
  use Ecto.Migration

  def change do
    create table(:sys_objects_transcoder, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :storage_object, :string, null: false
      add :source_type, :string, null: false
      add :source_params, :string, null: false
      add :private, :string, null: false
      add :atime_tracking, :integer, null: false
      add :atime_pruning, :integer, null: false
      add :ts, :integer, null: false, default: 0
      add :override_class_name, :string, null: false
      add :override_class_file, :string, null: false
      timestamps()
    end
    create index(:sys_objects_transcoder, [:object], unique: true)
  end
end
