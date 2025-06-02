defmodule Repo.Migrations.CreateSysProfilesConnBans do
  use Ecto.Migration

  def change do
    create table(:sys_profiles_conn_bans, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :module, :string, null: false, default: ""
      add :initiator, :integer, null: false
      add :content, :integer, null: false
      add :added, :integer, null: false
      timestamps()
    end
    create index(:sys_profiles_conn_bans, [:initiator])
    create index(:sys_profiles_conn_bans, [:content])
  end
end
