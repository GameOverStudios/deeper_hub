defmodule Repo.Migrations.CreateSysAclLevels do
  use Ecto.Migration

  def change do
    create table(:sys_acl_levels, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ID, :integer, null: false
      add :Name, :string, null: false, default: ""
      add :Icon, :string, null: false, default: "''"
      add :Description, :string, null: false, default: ""
      add :Active, :string, null: false, default: "no"
      add :Purchasable, :string, null: false, default: "yes"
      add :Removable, :string, null: false, default: "yes"
      add :QuotaSize, :integer, null: false
      add :QuotaNumber, :integer, null: false
      add :QuotaMaxFileSize, :integer, null: false
      add :Order, :integer, null: false, default: 0
      add :PasswordExpired, :integer, null: false, default: 0
      add :PasswordExpiredNotify, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_acl_levels, [:Name], unique: true)
    create index(:sys_acl_levels, [:Description])
  end
end
