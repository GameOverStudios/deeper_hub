defmodule Repo.Migrations.CreateSysOptionsCategories do
  use Ecto.Migration

  def change do
    create table(:sys_options_categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type_id, :integer, null: false, default: 0
      add :name, :string, null: false, default: ""
      add :caption, :string, null: false, default: ""
      add :hidden, :boolean, null: false, default: false
      add :order, :integer, default: 0
      timestamps()
    end
    create index(:sys_options_categories, [:name], unique: true)
  end
end
