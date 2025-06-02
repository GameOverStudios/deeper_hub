defmodule Repo.Migrations.CreateBxForumVotes do
  use Ecto.Migration

  def change do
    create table(:bx_forum_votes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false, default: 0
      add :count, :integer, null: false, default: 0
      add :sum, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_forum_votes, [:object_id], unique: true)
  end
end
