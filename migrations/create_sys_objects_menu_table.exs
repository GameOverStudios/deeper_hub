defmodule Repo.Migrations.CreateSysObjectsMenu do
  use Ecto.Migration

  def change do
    create table(:sys_objects_menu, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :title, :string, null: false
      add :set_name, :string, null: false
      add :module, :string, null: false
      add :template_id, :integer, null: false
      add :config_api, :string, null: false
      add :persistent, :integer, null: false, default: 0
      add :deletable, :integer, null: false, default: 1
      add :active, :integer, null: false, default: 0
      add :override_class_name, :string, null: false
      add :override_class_file, :string, null: false
      timestamps()
    end
    create index(:sys_objects_menu, [:object], unique: true)
  end
end
