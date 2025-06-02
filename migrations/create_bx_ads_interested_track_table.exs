defmodule Repo.Migrations.CreateBxAdsInterestedTrack do
  use Ecto.Migration

  def change do
    create table(:bx_ads_interested_track, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entry_id, :integer, null: false, default: 0
      add :profile_id, :integer, null: false, default: 0
      add :date, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_ads_interested_track, [:entry_id])
  end
end
