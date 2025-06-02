defmodule Repo.Migrations.CreateBxMassmailerLinks do
  use Ecto.Migration

  def change do
    create table(:bx_massmailer_links, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :letter_hash, :string
      add :hash, :string
      add :link, :string
      add :title, :string
      add :campaign_id, :integer
      add :date_click, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_massmailer_links, [:letter_hash])
    create index(:bx_massmailer_links, [:hash])
    create index(:bx_massmailer_links, [:campaign_id])
  end
end
