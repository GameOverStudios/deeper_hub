defmodule Repo.Migrations.CreateSysInjections do
  use Ecto.Migration

  def change do
    create table(:sys_injections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :page_index, :integer, null: false, default: 0
      add :key, :string, null: false, default: ""
      add :type, :string, null: false, default: "text"
      add :data, :string, null: false, default: "''"
      add :replace, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 1
      timestamps()
    end
  end
end
