defmodule Repo.Migrations.CreateSysAclActions do
  use Ecto.Migration

  def change do
    create table(:sys_acl_actions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ID, :integer, null: false
      add :Module, :string, null: false
      add :Name, :string, null: false, default: ""
      add :AdditionalParamName, :string
      add :Title, :string, null: false
      add :Desc, :string, null: false
      add :Countable, :integer, null: false, default: 0
      add :DisabledForLevels, :integer, null: false, default: 3
      timestamps()
    end
    create index(:sys_acl_actions, [:Module])
  end
end
