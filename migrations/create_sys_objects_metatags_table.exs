defmodule Repo.Migrations.CreateSysObjectsMetatags do
  use Ecto.Migration

  def change do
    create table(:sys_objects_metatags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :module, :string, null: false
      add :table_keywords, :string, null: false
      add :table_locations, :string, null: false
      add :table_mentions, :string, null: false
      add :override_class_name, :string, null: false
      add :override_class_file, :string, null: false
      timestamps()
    end
    create index(:sys_objects_metatags, [:object], unique: true)
  end
end
