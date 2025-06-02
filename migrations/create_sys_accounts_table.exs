defmodule Repo.Migrations.CreateSysAccounts do
  use Ecto.Migration

  def change do
    create table(:sys_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false
      add :name, :string, null: false
      add :picture, :integer, null: false, default: 0
      add :email, :string, null: false
      add :email_confirmed, :integer, null: false, default: 0
      add :phone, :string, null: false
      add :phone_confirmed, :integer, null: false, default: 0
      add :receive_updates, :integer, null: false, default: 1
      add :receive_news, :integer, null: false, default: 1
      add :password, :string, null: false
      add :password_changed, :integer, null: false, default: 0
      add :salt, :string, null: false
      add :role, :integer, null: false, default: 1
      add :lang_id, :integer, null: false, default: 0
      add :added, :integer, null: false, default: 0
      add :changed, :integer, null: false, default: 0
      add :logged, :integer, null: false, default: 0
      add :ip, :string, null: false, default: ""
      add :referred, :string, null: false, default: ""
      add :login_attempts, :integer, null: false, default: 0
      add :locked, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_accounts, [:profile_id])
    create index(:sys_accounts, [:email], unique: true)
    create index(:sys_accounts, [:added])
    create index(:sys_accounts, [:logged])
  end
end
