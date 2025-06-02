defmodule Repo.Migrations.CreateSysOptionsMixes do
  use Ecto.Migration

  def change do
    create table(:sys_options_mixes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false, default: ""
      add :category, :string, null: false, default: ""
      add :name, :string, null: false, default: ""
      add :title, :string, null: false, default: ""
      add :dark, :boolean, null: false, default: false
      add :active, :boolean, null: false, default: false
      add :published, :boolean, null: false, default: false
      add :editable, :boolean, null: false, default: true
      timestamps()
    end
    create index(:sys_options_mixes, [:name], unique: true)
  end
end
