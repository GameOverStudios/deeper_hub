defmodule Repo.Migrations.CreateSysObjectsCategory do
  use Ecto.Migration

  def change do
    create table(:sys_objects_category, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :module, :string, null: false
      add :search_object, :string, null: false
      add :form_object, :string, null: false
      add :list_name, :string, null: false
      add :table, :string, null: false
      add :field, :string, null: false
      add :join, :string, null: false
      add :where, :string, null: false
      add :override_class_name, :string, null: false
      add :override_class_file, :string, null: false
      timestamps()
    end
    create index(:sys_objects_category, [:object], unique: true)
    create index(:sys_objects_category, [:form_object])
  end
end
