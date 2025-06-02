defmodule Repo.Migrations.CreateBxReputationProfiles do
  use Ecto.Migration

  def change do
    create table(:bx_reputation_profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :points, :integer, null: false, default: 0
      timestamps()
    end
  end
end
