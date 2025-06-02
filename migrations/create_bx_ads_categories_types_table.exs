defmodule Repo.Migrations.CreateBxAdsCategoriesTypes do
  use Ecto.Migration

  def change do
    create table(:bx_ads_categories_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :title, :string, null: false, default: ""
      add :display_add, :string, null: false, default: ""
      add :display_edit, :string, null: false, default: ""
      add :display_view, :string, null: false, default: ""
      timestamps()
    end
    create index(:bx_ads_categories_types, [:name], unique: true)
  end
end
