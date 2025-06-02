defmodule Repo.Migrations.CreateSysObjectsPrivacy do
  use Ecto.Migration

  def change do
    create table(:sys_objects_privacy, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false, default: ""
      add :module, :string, null: false, default: ""
      add :action, :string, null: false, default: ""
      add :title, :string, null: false, default: ""
      add :default_group, :string, null: false, default: "1"
      add :spaces, :string, null: false, default: "all"
      add :table, :string, null: false, default: ""
      add :table_field_id, :string, null: false, default: ""
      add :table_field_author, :string, null: false, default: ""
      add :override_class_name, :string, null: false, default: ""
      add :override_class_file, :string, null: false, default: ""
      timestamps()
    end
    create index(:sys_objects_privacy, [:object], unique: true)
    create index(:sys_objects_privacy, [:module])
  end
end
