defmodule Repo.Migrations.CreateBxAdsOffers do
  use Ecto.Migration

  def change do
    create table(:bx_ads_offers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content_id, :integer, null: false, default: 0
      add :author_id, :integer, null: false, default: 0
      add :added, :integer, null: false, default: 0
      add :changed, :integer, null: false, default: 0
      add :amount, :float, null: false, default: 0
      add :quantity, :integer, null: false, default: 0
      add :message, :string, null: false
      add :status, :string, null: false, default: "awaiting"
      timestamps()
    end
  end
end
