defmodule Repo.Migrations.CreateBxAdsPromoLicenses do
  use Ecto.Migration

  def change do
    create table(:bx_ads_promo_licenses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false, default: 0
      add :commodity_id, :integer, null: false, default: 0
      add :entry_id, :integer, null: false, default: 0
      add :amount, :float, null: false, default: 0
      add :order, :string, null: false, default: ""
      add :license, :string, null: false, default: ""
      add :added, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_ads_promo_licenses, [:license])
  end
end
