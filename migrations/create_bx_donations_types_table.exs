defmodule Repo.Migrations.CreateBxDonationsTypes do
  use Ecto.Migration

  def change do
    create table(:bx_donations_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :title, :string, null: false, default: ""
      add :period, :integer, null: false, default: 0
      add :period_unit, :string, null: false, default: ""
      add :amount, :float, null: false, default: 0
      add :custom, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 1
      add :order, :integer, null: false
      timestamps()
    end
    create index(:bx_donations_types, [:name], unique: true)
  end
end
