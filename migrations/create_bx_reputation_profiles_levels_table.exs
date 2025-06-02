defmodule Repo.Migrations.CreateBxReputationProfilesLevels do
  use Ecto.Migration

  def change do
    create table(:bx_reputation_profiles_levels, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false, default: 0
      add :level_id, :integer, null: false, default: 0
      add :date, :integer, null: false, default: 0
      timestamps()
    end
  end
end
