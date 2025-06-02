defmodule Repo.Migrations.CreateSysObjectsForm do
  use Ecto.Migration

  def change do
    create table(:sys_objects_form, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :module, :string, null: false
      add :title, :string, null: false
      add :action, :string, null: false
      add :form_attrs, :string, null: false
      add :submit_name, :string, null: false
      add :table, :string, null: false
      add :key, :string, null: false
      add :uri, :string, null: false
      add :uri_title, :string, null: false
      add :params, :string, null: false
      add :deletable, :integer, null: false, default: 1
      add :active, :integer, null: false, default: 0
      add :parent_form, :string, null: false, default: ""
      add :override_class_name, :string, null: false
      add :override_class_file, :string, null: false
      timestamps()
    end
    create index(:sys_objects_form, [:object], unique: true)
  end
end
