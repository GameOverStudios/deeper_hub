defmodule Repo.Migrations.CreateBxInvRequests do
  use Ecto.Migration

  def change do
    create table(:bx_inv_requests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :email, :string, null: false
      add :text, :string, null: false
      add :nip, :integer, null: false, default: 0
      add :date, :integer, null: false, default: 0
      add :status, :integer, default: 0
      timestamps()
    end
  end
end
