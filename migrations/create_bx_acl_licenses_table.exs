defmodule Repo.Migrations.CreateBxAclLicenses do
  use Ecto.Migration

  def change do
    create table(:bx_acl_licenses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false, default: 0
      add :price_id, :integer, null: false, default: 0
      add :type, :string, null: false, default: "single"
      add :order, :string, null: false, default: ""
      add :license, :string, null: false, default: ""
      add :added, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_acl_licenses, [:price_id])
    create index(:bx_acl_licenses, [:license])
  end
end
