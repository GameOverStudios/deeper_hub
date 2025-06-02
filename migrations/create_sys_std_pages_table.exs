defmodule Repo.Migrations.CreateSysStdPages do
  use Ecto.Migration

  def change do
    create table(:sys_std_pages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :index, :integer, null: false, default: 0
      add :name, :string, null: false, default: ""
      add :header, :string, null: false, default: ""
      add :caption, :string, null: false, default: ""
      add :icon, :string, null: false, default: ""
      timestamps()
    end
    create index(:sys_std_pages, [:name], unique: true)
  end
end
