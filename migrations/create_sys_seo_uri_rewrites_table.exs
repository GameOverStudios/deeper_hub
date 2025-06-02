defmodule Repo.Migrations.CreateSysSeoUriRewrites do
  use Ecto.Migration

  def change do
    create table(:sys_seo_uri_rewrites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :uri_orig, :string, null: false
      add :uri_rewrite, :string, null: false
      timestamps()
    end
    create index(:sys_seo_uri_rewrites, [:uri_orig], unique: true)
    create index(:sys_seo_uri_rewrites, [:uri_rewrite], unique: true)
  end
end
