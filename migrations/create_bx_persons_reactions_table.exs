defmodule Repo.Migrations.CreateBxPersonsReactions do
  use Ecto.Migration

  def change do
    create table(:bx_persons_reactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false, default: 0
      add :reaction, :string, null: false, default: ""
      add :count, :integer, null: false, default: 0
      add :sum, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_persons_reactions, [:object_id])
  end
end
