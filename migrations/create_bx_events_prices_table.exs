defmodule Repo.Migrations.CreateBxEventsPrices do
  use Ecto.Migration

  def change do
    create table(:bx_events_prices, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false, default: 0
      add :role_id, :integer, null: false, default: 0
      add :name, :string, null: false, default: ""
      add :period, :integer, null: false, default: 1
      add :period_unit, :string, null: false, default: ""
      add :price, :float, null: false, default: 1
      add :order, :integer, null: false
      timestamps()
    end
    create index(:bx_events_prices, [:profile_id])
    create index(:bx_events_prices, [:name], unique: true)
  end
end
