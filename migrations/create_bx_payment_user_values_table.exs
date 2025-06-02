defmodule Repo.Migrations.CreateBxPaymentUserValues do
  use Ecto.Migration

  def change do
    create table(:bx_payment_user_values, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, :integer, null: false, default: 0
      add :option_id, :integer, null: false, default: 0
      add :value, :string, null: false, default: ""
      timestamps()
    end
    create index(:bx_payment_user_values, [:user_id])
  end
end
