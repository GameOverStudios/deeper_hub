defmodule Repo.Migrations.CreateSysProfilesConnRelations do
  use Ecto.Migration

  def change do
    create table(:sys_profiles_conn_relations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :initiator, :integer, null: false, default: 0
      add :content, :integer, null: false, default: 0
      add :relation, :integer, null: false, default: 0
      add :mutual, :integer, null: false, default: 0
      add :added, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_profiles_conn_relations, [:initiator])
    create index(:sys_profiles_conn_relations, [:content])
  end
end
