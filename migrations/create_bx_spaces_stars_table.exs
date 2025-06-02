defmodule Repo.Migrations.CreateBxSpacesStars do
  use Ecto.Migration

  def change do
    create table(:bx_spaces_stars, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false, default: 0
      add :count, :integer, null: false, default: 0
      add :sum, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_spaces_stars, [:object_id], unique: true)
  end
end
