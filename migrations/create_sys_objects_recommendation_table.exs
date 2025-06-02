defmodule Repo.Migrations.CreateSysObjectsRecommendation do
  use Ecto.Migration

  def change do
    create table(:sys_objects_recommendation, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :module, :string, null: false, default: ""
      add :connection, :string, null: false, default: ""
      add :content_info, :string, null: false, default: ""
      add :countable, :integer, null: false, default: 1
      add :active, :integer, null: false, default: 1
      add :class_name, :string, null: false, default: ""
      add :class_file, :string, null: false, default: ""
      timestamps()
    end
    create index(:sys_objects_recommendation, [:name], unique: true)
  end
end
