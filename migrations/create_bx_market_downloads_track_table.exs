defmodule Repo.Migrations.CreateBxMarketDownloadsTrack do
  use Ecto.Migration

  def change do
    create table(:bx_market_downloads_track, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :file_id, :integer, null: false, default: 0
      add :profile_id, :integer, null: false, default: 0
      add :profile_nip, :integer, null: false, default: 0
      add :date, :integer, null: false, default: 0
      timestamps()
    end
  end
end
