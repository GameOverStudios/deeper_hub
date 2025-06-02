defmodule Repo.Migrations.CreateBxAdsLicenses do
  use Ecto.Migration

  def change do
    create table(:bx_ads_licenses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false, default: 0
      add :entry_id, :integer, null: false, default: 0
      add :count, :integer, null: false, default: 0
      add :order, :string, null: false, default: ""
      add :license, :string, null: false, default: ""
      add :added, :integer, null: false, default: 0
      add :new, :boolean, null: false, default: true
      timestamps()
    end
    create index(:bx_ads_licenses, [:entry_id])
    create index(:bx_ads_licenses, [:license])
  end
end
