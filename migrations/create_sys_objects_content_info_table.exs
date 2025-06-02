defmodule Repo.Migrations.CreateSysObjectsContentInfo do
  use Ecto.Migration

  def change do
    create table(:sys_objects_content_info, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :title, :string, null: false
      add :alert_unit, :string, null: false
      add :alert_action_add, :string, null: false
      add :alert_action_update, :string, null: false
      add :alert_action_delete, :string, null: false
      add :class_name, :string, null: false, default: ""
      add :class_file, :string, null: false, default: ""
      timestamps()
    end
    create index(:sys_objects_content_info, [:name], unique: true)
    create index(:sys_objects_content_info, [:alert_unit])
  end
end
