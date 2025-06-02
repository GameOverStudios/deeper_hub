defmodule Repo.Migrations.CreateSysPreloader do
  use Ecto.Migration

  def change do
    create table(:sys_preloader, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :module, :string, null: false
      add :type, :string, null: false
      add :content, :string, null: false
      add :active, :integer, null: false, default: 1
      add :order, :integer, null: false, default: 0
      timestamps()
    end
  end
end
