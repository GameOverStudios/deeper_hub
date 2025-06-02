defmodule Repo.Migrations.CreateSysPagesTypes do
  use Ecto.Migration

  def change do
    create table(:sys_pages_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :template, :string, null: false
      add :order, :integer, null: false
      timestamps()
    end
  end
end
