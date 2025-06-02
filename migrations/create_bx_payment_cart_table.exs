defmodule Repo.Migrations.CreateBxPaymentCart do
  use Ecto.Migration

  def change do
    create table(:bx_payment_cart, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :client_id, :integer, null: false, default: 0
      add :items, :string, null: false, default: "''"
      add :customs, :string, null: false, default: "''"
      timestamps()
    end
  end
end
