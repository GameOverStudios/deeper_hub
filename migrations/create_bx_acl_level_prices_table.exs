defmodule Repo.Migrations.CreateBxAclLevelPrices do
  use Ecto.Migration

  def change do
    create table(:bx_acl_level_prices, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :level_id, :integer, null: false, default: 0
      add :name, :string, null: false, default: ""
      add :period, :integer, null: false, default: 1
      add :period_unit, :string, null: false, default: ""
      add :trial, :integer, null: false, default: 0
      add :price, :float, null: false, default: 1
      add :immediate, :integer, null: false, default: 1
      add :order, :integer, null: false
      timestamps()
    end
    create index(:bx_acl_level_prices, [:level_id])
    create index(:bx_acl_level_prices, [:name], unique: true)
  end
end
