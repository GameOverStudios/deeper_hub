defmodule Repo.Migrations.CreateBxPaymentTransactionsPending do
  use Ecto.Migration

  def change do
    create table(:bx_payment_transactions_pending, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :client_id, :integer, null: false, default: 0
      add :seller_id, :integer, null: false, default: 0
      add :type, :string, null: false, default: "single"
      add :provider, :string, null: false, default: ""
      add :items, :string, null: false, default: "''"
      add :customs, :string, null: false, default: "''"
      add :amount, :float, null: false, default: 0
      add :currency, :string, null: false, default: ""
      add :order, :string, null: false, default: ""
      add :data, :string, null: false
      add :error_code, :string, null: false, default: ""
      add :error_msg, :string, null: false, default: ""
      add :date, :integer, null: false, default: 0
      add :authorized, :integer, null: false, default: 0
      add :processed, :integer, null: false, default: 0
      timestamps()
    end
  end
end
