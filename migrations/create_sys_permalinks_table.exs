defmodule Repo.Migrations.CreateSysPermalinks do
  use Ecto.Migration

  def change do
    create table(:sys_permalinks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :standard, :string, null: false, default: ""
      add :permalink, :string, null: false, default: ""
      add :check, :string, null: false, default: ""
      add :compare_by_prefix, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_permalinks, [:standard])
  end
end
