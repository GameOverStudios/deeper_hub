defmodule Repo.Migrations.CreateBxReputationLevels do
  use Ecto.Migration

  def change do
    create table(:bx_reputation_levels, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :title, :string, null: false, default: ""
      add :icon, :string, null: false
      add :points_in, :integer, null: false, default: 0
      add :points_out, :integer, null: false, default: 0
      add :date, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 1
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_reputation_levels, [:name], unique: true)
  end
end
