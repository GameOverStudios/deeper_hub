defmodule Repo.Migrations.CreateSysContentInfoGrids do
  use Ecto.Migration

  def change do
    create table(:sys_content_info_grids, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :grid_object, :string, null: false
      add :grid_field_id, :string, null: false
      add :condition, :string, null: false, default: "''"
      add :selection, :string, null: false, default: ""
      timestamps()
    end
    create index(:sys_content_info_grids, [:grid_object], unique: true)
  end
end
