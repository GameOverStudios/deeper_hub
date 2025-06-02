defmodule Repo.Migrations.CreateSysObjectsFeature do
  use Ecto.Migration

  def change do
    create table(:sys_objects_feature, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :module, :string, null: false, default: ""
      add :is_on, :integer, null: false, default: 1
      add :is_undo, :integer, null: false, default: 1
      add :base_url, :string, null: false, default: ""
      add :trigger_table, :string, null: false
      add :trigger_field_id, :string, null: false
      add :trigger_field_author, :string, null: false
      add :trigger_field_flag, :string, null: false
      add :class_name, :string, null: false, default: ""
      add :class_file, :string, null: false, default: ""
      timestamps()
    end
  end
end
