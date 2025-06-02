defmodule Repo.Migrations.CreateBxAdsPromoTracker do
  use Ecto.Migration

  def change do
    create table(:bx_ads_promo_tracker, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entry_id, :integer, null: false, default: 0
      add :date, :integer, null: false, default: 0
      add :impressions, :integer, null: false, default: 0
      add :clicks, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_ads_promo_tracker, [:entry_id])
  end
end
