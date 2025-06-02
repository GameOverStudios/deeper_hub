defmodule Repo.Migrations.CreateSysProfilesConnSubscriptions do
  use Ecto.Migration

  def change do
    create table(:sys_profiles_conn_subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :initiator, :integer, null: false
      add :content, :integer, null: false
      add :added, :integer, null: false
      timestamps()
    end
    create index(:sys_profiles_conn_subscriptions, [:initiator])
    create index(:sys_profiles_conn_subscriptions, [:content])
  end
end
