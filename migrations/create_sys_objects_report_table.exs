defmodule Repo.Migrations.CreateSysObjectsReport do
  use Ecto.Migration

  def change do
    create table(:sys_objects_report, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :module, :string, null: false, default: ""
      add :table_main, :string, null: false
      add :table_track, :string, null: false
      add :pruning, :integer, null: false, default: 31536000
      add :is_on, :integer, null: false, default: 1
      add :base_url, :string, null: false, default: ""
      add :object_comment, :string, null: false
      add :trigger_table, :string, null: false
      add :trigger_field_id, :string, null: false
      add :trigger_field_author, :string, null: false
      add :trigger_field_count, :string, null: false
      add :class_name, :string, null: false, default: ""
      add :class_file, :string, null: false, default: ""
      timestamps()
    end
  end
end
