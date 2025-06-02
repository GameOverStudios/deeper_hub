defmodule Repo.Migrations.CreateSysSeoLinks do
  use Ecto.Migration

  def change do
    create table(:sys_seo_links, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :module, :string, null: false
      add :page_uri, :string, null: false
      add :param_name, :string, null: false
      add :param_value, :string, null: false
      add :uri, :string, null: false
      add :added, :integer, null: false
      timestamps()
    end
    create index(:sys_seo_links, [:module])
    create index(:sys_seo_links, [:param_name])
  end
end
