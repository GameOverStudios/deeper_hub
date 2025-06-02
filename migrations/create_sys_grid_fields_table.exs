defmodule Repo.Migrations.CreateSysGridFields do
  use Ecto.Migration

  def change do
    create table(:sys_grid_fields, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :name, :string, null: false
      add :title, :string, null: false
      add :width, :string, null: false
      add :translatable, :integer, null: false, default: 0
      add :chars_limit, :integer, null: false, default: 0
      add :params, :string, null: false
      add :hidden_on, :string, null: false, default: ""
      add :order, :integer, null: false
      timestamps()
    end
    create index(:sys_grid_fields, [:object])
  end
end
