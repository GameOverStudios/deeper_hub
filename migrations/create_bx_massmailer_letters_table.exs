defmodule Repo.Migrations.CreateBxMassmailerLetters do
  use Ecto.Migration

  def change do
    create table(:bx_massmailer_letters, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :campaign_id, :integer, null: false
      add :email, :string, null: false
      add :date_sent, :integer, null: false, default: 0
      add :date_seen, :integer, null: false, default: 0
      add :date_click, :integer, null: false, default: 0
      add :hash, :string, null: false
      timestamps()
    end
    create index(:bx_massmailer_letters, [:campaign_id])
    create index(:bx_massmailer_letters, [:hash])
  end
end
