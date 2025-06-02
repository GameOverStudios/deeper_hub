defmodule Repo.Migrations.CreateBxForumCategories do
  use Ecto.Migration

  def change do
    create table(:bx_forum_categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :category, :integer, null: false, default: 0
      add :visible_for_levels, :integer, null: false, default: 2147483647
      add :icon, :string, null: false
      timestamps()
    end
  end
end
