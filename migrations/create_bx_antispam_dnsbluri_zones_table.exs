defmodule Repo.Migrations.CreateBxAntispamDnsbluriZones do
  use Ecto.Migration

  def change do
    create table(:bx_antispam_dnsbluri_zones, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :level, :integer, null: false
      add :zone, :string, null: false
      timestamps()
    end
  end
end
