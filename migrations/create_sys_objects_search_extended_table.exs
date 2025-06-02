defmodule Repo.Migrations.CreateSysObjectsSearchExtended do
  use Ecto.Migration

  def change do
    create table(:sys_objects_search_extended, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false, default: ""
      add :object_content_info, :string, null: false, default: ""
      add :module, :string, null: false, default: ""
      add :title, :string, null: false, default: ""
      add :filter, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 0
      add :class_name, :string, null: false, default: ""
      add :class_file, :string, null: false, default: ""
      timestamps()
    end
    create index(:sys_objects_search_extended, [:object], unique: true)
  end
end
