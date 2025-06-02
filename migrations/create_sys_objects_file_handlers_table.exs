defmodule Repo.Migrations.CreateSysObjectsFileHandlers do
  use Ecto.Migration

  def change do
    create table(:sys_objects_file_handlers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :title, :string, null: false
      add :preg_ext, :string, null: false
      add :active, :integer, null: false
      add :order, :integer, null: false
      add :override_class_name, :string, null: false
      add :override_class_file, :string, null: false
      timestamps()
    end
    create index(:sys_objects_file_handlers, [:object], unique: true)
  end
end
