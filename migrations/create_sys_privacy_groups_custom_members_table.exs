defmodule Repo.Migrations.CreateSysPrivacyGroupsCustomMembers do
  use Ecto.Migration

  def change do
    create table(:sys_privacy_groups_custom_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :group_id, :integer, null: false, default: 0
      add :member_id, :integer, null: false, default: 0
      timestamps()
    end
  end
end
