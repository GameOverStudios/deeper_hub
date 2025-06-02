defmodule Repo.Migrations.CreateBxPaymentInvoices do
  use Ecto.Migration

  def change do
    create table(:bx_payment_invoices, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :commissionaire_id, :string, null: false, default: ""
      add :committent_id, :string, null: false, default: ""
      add :amount, :float, null: false, default: 0
      add :currency, :string, null: false, default: ""
      add :period_start, :integer, null: false, default: 0
      add :period_end, :integer, null: false, default: 0
      add :date_issue, :integer, null: false, default: 0
      add :date_due, :integer, null: false, default: 0
      add :status, :string, null: false, default: "unpaid"
      add :ntf_exp, :integer, null: false, default: 0
      add :ntf_due, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_payment_invoices, [:name], unique: true)
  end
end
