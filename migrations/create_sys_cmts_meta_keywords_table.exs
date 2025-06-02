defmodule Repo.Migrations.CreateSysCmtsMetaKeywords do
  use Ecto.Migration

  def change do
    create table(:sys_cmts_meta_keywords, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false
      add :keyword, :string, null: false
      timestamps()
    end
    create index(:sys_cmts_meta_keywords, [:object_id])
    create index(:sys_cmts_meta_keywords, [:keyword])
  end
end
