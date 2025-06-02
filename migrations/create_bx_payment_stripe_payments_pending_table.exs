defmodule Repo.Migrations.CreateBxPaymentStripePaymentsPending do
  use Ecto.Migration

  def change do
    create table(:bx_payment_stripe_payments_pending, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :subscription_id, :string, null: false, default: ""
      add :amount, :float, null: false, default: 0
      add :currency, :string, null: false, default: ""
      timestamps()
    end
    create index(:bx_payment_stripe_payments_pending, [:subscription_id], unique: true)
  end
end
