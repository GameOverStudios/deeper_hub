defmodule Repo.Migrations.CreateSysPagesContentPlaceholders do
  use Ecto.Migration

  def change do
    create table(:sys_pages_content_placeholders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :module, :string, null: false
      add :title, :string, null: false
      add :template, :string, null: false
      add :order, :integer, null: false
      timestamps()
    end
  end
end
