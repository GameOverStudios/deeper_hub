defmodule Repo.Migrations.CreateBxAntispamIpTable do
  use Ecto.Migration

  def change do
    create table(:bx_antispam_ip_table, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ID, :integer, null: false
      add :From, :integer, null: false
      add :To, :integer, null: false
      add :Type, :string, null: false, default: "deny"
      add :LastDT, :integer, null: false
      add :Desc, :string, null: false
      timestamps()
    end
    create index(:bx_antispam_ip_table, [:From])
    create index(:bx_antispam_ip_table, [:To])
  end
end
