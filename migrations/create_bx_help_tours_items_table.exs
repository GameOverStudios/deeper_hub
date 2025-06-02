defmodule Repo.Migrations.CreateBxHelpToursItems do
  use Ecto.Migration

  def change do
    create table(:bx_help_tours_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tour, :integer, null: false
      add :name, :string, null: false
      add :element, :string, null: false
      add :arrow, :string
      add :title, :string, null: false
      add :text, :string, null: false
      add :order, :integer, null: false
      timestamps()
    end
    create index(:bx_help_tours_items, [:tour])
  end
end
