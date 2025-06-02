defmodule Repo.Migrations.CreateBxQuoteofdayInternal do
  use Ecto.Migration

  def change do
    create table(:bx_quoteofday_internal, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :text, :string, null: false
      add :added, :integer
      add :status, :string, default: "active"
      timestamps()
    end
    create index(:bx_quoteofday_internal, [:text])
  end
end
