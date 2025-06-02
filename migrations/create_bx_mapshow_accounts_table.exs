defmodule Repo.Migrations.CreateBxMapshowAccounts do
  use Ecto.Migration

  def change do
    create table(:bx_mapshow_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, :integer, null: false
      add :lng, :float
      add :lat, :float
      timestamps()
    end
    create index(:bx_mapshow_accounts, [:account_id])
  end
end
