defmodule Repo.Migrations.CreateBxCreditsWithdrawals do
  use Ecto.Migration

  def change do
    create table(:bx_credits_withdrawals, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :performer_id, :integer, null: false, default: 0
      add :profile_id, :integer, null: false, default: 0
      add :amount, :float, null: false, default: 0
      add :rate, :float, null: false, default: 0
      add :message, :string, null: false, default: "''"
      add :order, :string, null: false, default: ""
      add :added, :integer, null: false, default: 0
      add :confirmed, :integer, null: false, default: 0
      add :status, :string, null: false, default: "requested"
      timestamps()
    end
  end
end
