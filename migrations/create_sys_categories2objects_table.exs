defmodule Repo.Migrations.CreateSysCategories2objects do
  use Ecto.Migration

  def change do
    create table(:sys_categories2objects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :module, :string, null: false
      add :object_id, :integer, null: false
      add :category_id, :integer, null: false
      timestamps()
    end
  end
end
