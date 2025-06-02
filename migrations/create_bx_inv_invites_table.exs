defmodule Repo.Migrations.CreateBxInvInvites do
  use Ecto.Migration

  def change do
    create table(:bx_inv_invites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, :integer, null: false
      add :profile_id, :integer, null: false
      add :key, :string, null: false
      add :redirect, :string, null: false, default: ""
      add :email, :string, null: false
      add :date, :integer, null: false, default: 0
      add :date_seen, :integer
      add :date_joined, :integer
      add :joined_account_id, :integer
      add :request_id, :integer
      timestamps()
    end
    create index(:bx_inv_invites, [:request_id])
  end
end
