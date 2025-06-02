defmodule Repo.Migrations.CreateBxAdsCommodities do
  use Ecto.Migration

  def change do
    create table(:bx_ads_commodities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entry_id, :integer, null: false, default: 0
      add :type, :string, null: false, default: ""
      add :amount, :float, null: false
      add :added, :integer, null: false
      timestamps()
    end
  end
end
