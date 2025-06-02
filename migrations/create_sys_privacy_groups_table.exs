defmodule Repo.Migrations.CreateSysPrivacyGroups do
  use Ecto.Migration

  def change do
    create table(:sys_privacy_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false, default: ""
      add :check, :string, null: false, default: "''"
      add :active, :integer, null: false, default: 1
      add :visible, :integer, null: false, default: 1
      add :order, :integer, null: false, default: 0
      timestamps()
    end
  end
end
