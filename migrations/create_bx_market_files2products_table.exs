defmodule Repo.Migrations.CreateBxMarketFiles2products do
  use Ecto.Migration

  def change do
    create table(:bx_market_files2products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content_id, :integer, null: false
      add :file_id, :integer, null: false
      add :type, :string, null: false, default: "version"
      add :version, :string, null: false
      add :version_to, :string, null: false
      add :downloads, :integer, null: false
      add :order, :integer, null: false
      timestamps()
    end
    create index(:bx_market_files2products, [:content_id])
    create index(:bx_market_files2products, [:file_id])
  end
end
