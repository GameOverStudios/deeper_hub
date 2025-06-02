defmodule Repo.Migrations.CreateSysRewriteRules do
  use Ecto.Migration

  def change do
    create table(:sys_rewrite_rules, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :preg, :string, null: false
      add :service, :string, null: false
      add :active, :integer, null: false, default: 1
      timestamps()
    end
  end
end
