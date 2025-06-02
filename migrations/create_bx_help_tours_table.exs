defmodule Repo.Migrations.CreateBxHelpTours do
  use Ecto.Migration

  def change do
    create table(:bx_help_tours, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :overlay, :boolean, null: false
      add :page, :string, null: false
      add :order, :integer, null: false
      timestamps()
    end
  end
end
