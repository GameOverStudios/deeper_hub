defmodule Repo.Migrations.CreateBxDonationsEntriesDeleted do
  use Ecto.Migration

  def change do
    create table(:bx_donations_entries_deleted, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false, default: 0
      add :type_id, :integer, null: false, default: 0
      add :period, :integer, null: false, default: 0
      add :period_unit, :string, null: false, default: ""
      add :amount, :float, null: false, default: 0
      add :order, :string, null: false, default: ""
      add :license, :string, null: false, default: ""
      add :added, :integer, null: false, default: 0
      add :reason, :string, null: false, default: ""
      add :deleted, :integer, null: false, default: 0
      timestamps()
    end
  end
end
