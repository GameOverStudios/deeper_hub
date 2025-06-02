defmodule Repo.Migrations.CreateSysObjectsRss do
  use Ecto.Migration

  def change do
    create table(:sys_objects_rss, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :class_name, :string, null: false, default: ""
      add :class_file, :string, null: false, default: ""
      timestamps()
    end
  end
end
