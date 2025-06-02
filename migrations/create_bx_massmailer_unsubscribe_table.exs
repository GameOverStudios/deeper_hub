defmodule Repo.Migrations.CreateBxMassmailerUnsubscribe do
  use Ecto.Migration

  def change do
    create table(:bx_massmailer_unsubscribe, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, :integer
      add :campaign_id, :integer
      add :unsubscribed, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_massmailer_unsubscribe, [:campaign_id])
  end
end
