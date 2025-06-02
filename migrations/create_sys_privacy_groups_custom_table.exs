defmodule Repo.Migrations.CreateSysPrivacyGroupsCustom do
  use Ecto.Migration

  def change do
    create table(:sys_privacy_groups_custom, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false, default: 0
      add :content_id, :integer, null: false, default: 0
      add :object, :string, null: false, default: ""
      add :group_id, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_privacy_groups_custom, [:profile_id])
  end
end
