defmodule Repo.Migrations.CreateBxOrganizationsFavoritesLists do
  use Ecto.Migration

  def change do
    create table(:bx_organizations_favorites_lists, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :author_id, :integer, null: false, default: 0
      add :date, :integer, null: false, default: 0
      add :allow_view_favorite_list_to, :string, null: false, default: "3"
      timestamps()
    end
  end
end
