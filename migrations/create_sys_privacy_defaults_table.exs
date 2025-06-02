defmodule Repo.Migrations.CreateSysPrivacyDefaults do
  use Ecto.Migration

  def change do
    create table(:sys_privacy_defaults, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :owner_id, :integer, null: false, default: 0
      add :action_id, :integer, null: false, default: 0
      add :group_id, :integer, null: false, default: 0
      timestamps()
    end
  end
end
