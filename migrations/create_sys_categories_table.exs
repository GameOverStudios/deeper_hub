defmodule Repo.Migrations.CreateSysCategories do
  use Ecto.Migration

  def change do
    create table(:sys_categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false
      add :added, :integer, null: false
      add :module, :string, null: false
      add :value, :string, null: false
      add :status, :string, null: false, default: "active"
      timestamps()
    end
  end
end
