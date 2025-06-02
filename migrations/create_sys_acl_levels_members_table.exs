defmodule Repo.Migrations.CreateSysAclLevelsMembers do
  use Ecto.Migration

  def change do
    create table(:sys_acl_levels_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :IDMember, :integer, null: false, default: 0
      add :IDLevel, :integer, null: false, default: 0
      add :DateStarts, :naive_datetime, null: false, default: "0000-00-00 00:00:00"
      add :DateExpires, :naive_datetime
      add :State, :string, null: false, default: ""
      add :TransactionID, :string, null: false, default: ""
      timestamps()
    end
  end
end
