defmodule Repo.Migrations.CreateSysObjectsPlayer do
  use Ecto.Migration

  def change do
    create table(:sys_objects_player, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :title, :string, null: false
      add :skin, :string, null: false
      add :override_class_name, :string, null: false
      add :override_class_file, :string, null: false
      timestamps()
    end
    create index(:sys_objects_player, [:object], unique: true)
  end
end
