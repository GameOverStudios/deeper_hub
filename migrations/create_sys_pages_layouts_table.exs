defmodule Repo.Migrations.CreateSysPagesLayouts do
  use Ecto.Migration

  def change do
    create table(:sys_pages_layouts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :icon, :string, null: false
      add :title, :string, null: false
      add :template, :string, null: false
      add :cells_number, :integer, null: false
      timestamps()
    end
    create index(:sys_pages_layouts, [:name], unique: true)
  end
end
