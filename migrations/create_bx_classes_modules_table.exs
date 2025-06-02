defmodule Repo.Migrations.CreateBxClassesModules do
  use Ecto.Migration

  def change do
    create table(:bx_classes_modules, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false
      add :module_title, :string, null: false
      add :author, :integer, null: false
      add :added, :integer, null: false
      add :changed, :integer, null: false
      add :order, :integer, null: false
      timestamps()
    end
  end
end
