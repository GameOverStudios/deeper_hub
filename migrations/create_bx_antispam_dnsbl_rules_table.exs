defmodule Repo.Migrations.CreateBxAntispamDnsblRules do
  use Ecto.Migration

  def change do
    create table(:bx_antispam_dnsbl_rules, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :chain, :string, null: false
      add :zonedomain, :string, null: false
      add :postvresp, :string, null: false
      add :url, :string, null: false
      add :recheck, :string, null: false
      add :comment, :string, null: false
      add :added, :integer, null: false
      add :active, :integer, null: false
      timestamps()
    end
  end
end
