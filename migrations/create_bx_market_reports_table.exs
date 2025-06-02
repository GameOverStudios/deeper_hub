defmodule Repo.Migrations.CreateBxMarketReports do
  use Ecto.Migration

  def change do
    create table(:bx_market_reports, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false, default: 0
      add :count, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_market_reports, [:object_id], unique: true)
  end
end
