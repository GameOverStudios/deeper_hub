defmodule Repo.Migrations.CreateBxCreditsProfiles do
  use Ecto.Migration

  def change do
    create table(:bx_credits_profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :wdw_clearing, :integer, null: false, default: 0
      add :wdw_minimum, :integer, null: false, default: 0
      add :wdw_remaining, :integer, null: false, default: 0
      add :balance, :float, null: false, default: 0
      timestamps()
    end
  end
end
