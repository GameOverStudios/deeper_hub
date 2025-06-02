defmodule Repo.Migrations.CreateSysCmtsVotes do
  use Ecto.Migration

  def change do
    create table(:sys_cmts_votes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false, default: 0
      add :count, :integer, null: false, default: 0
      add :sum, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_cmts_votes, [:object_id], unique: true)
  end
end
