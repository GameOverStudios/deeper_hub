defmodule Repo.Migrations.CreateBxPollsSubentries do
  use Ecto.Migration

  def change do
    create table(:bx_polls_subentries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entry_id, :integer, null: false, default: 0
      add :title, :string, null: false
      add :rate, :float, null: false, default: 0
      add :votes, :integer, null: false, default: 0
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_polls_subentries, [:title])
  end
end
