defmodule Repo.Migrations.CreateBxHelpToursTrackViews do
  use Ecto.Migration

  def change do
    create table(:bx_help_tours_track_views, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account, :integer, null: false
      add :tour, :integer, null: false
      timestamps()
    end
  end
end
