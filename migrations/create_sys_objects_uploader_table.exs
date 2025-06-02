defmodule Repo.Migrations.CreateSysObjectsUploader do
  use Ecto.Migration

  def change do
    create table(:sys_objects_uploader, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :active, :integer, null: false
      add :override_class_name, :string, null: false
      add :override_class_file, :string, null: false
      timestamps()
    end
    create index(:sys_objects_uploader, [:object], unique: true)
  end
end
