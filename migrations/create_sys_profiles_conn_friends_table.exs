defmodule Repo.Migrations.CreateSysProfilesConnFriends do
  use Ecto.Migration

  def change do
    create table(:sys_profiles_conn_friends, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :initiator, :integer, null: false
      add :content, :integer, null: false
      add :mutual, :integer, null: false
      add :added, :integer, null: false
      timestamps()
    end
    create index(:sys_profiles_conn_friends, [:initiator])
    create index(:sys_profiles_conn_friends, [:content])
  end
end
