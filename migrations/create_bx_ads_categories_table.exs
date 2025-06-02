defmodule Repo.Migrations.CreateBxAdsCategories do
  use Ecto.Migration

  def change do
    create table(:bx_ads_categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :parent_id, :integer, null: false, default: 0
      add :level, :integer, null: false, default: 0
      add :type, :integer, null: false, default: 0
      add :name, :string, null: false, default: ""
      add :title, :string, null: false, default: ""
      add :text, :string, null: false
      add :icon, :string, null: false, default: ""
      add :items, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 1
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_ads_categories, [:name], unique: true)
    create index(:bx_ads_categories, [:title])
  end
end
