defmodule Repo.Migrations.CreateSysAccountsPassword do
  use Ecto.Migration

  def change do
    create table(:sys_accounts_password, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, :integer, null: false
      add :password, :string, null: false
      add :password_changed, :integer, null: false, default: 0
      add :salt, :string, null: false
      timestamps()
    end
  end
end
