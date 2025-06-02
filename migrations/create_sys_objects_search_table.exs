defmodule Repo.Migrations.CreateSysObjectsSearch do
  use Ecto.Migration

  def change do
    create table(:sys_objects_search, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ID, :integer, null: false
      add :ObjectName, :string, null: false, default: ""
      add :Title, :string, null: false, default: ""
      add :Order, :integer, null: false
      add :GlobalSearch, :integer, null: false, default: 1
      add :ClassName, :string, null: false, default: ""
      add :ClassPath, :string, null: false, default: ""
      timestamps()
    end
  end
end
