defmodule Repo.Migrations.CreateBxMassmailerCampaigns do
  use Ecto.Migration

  def change do
    create table(:bx_massmailer_campaigns, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :subject, :string
      add :from_name, :string
      add :reply_to, :string
      add :body, :string
      add :segments, :string
      add :author, :integer, null: false
      add :added, :integer, null: false, default: 0
      add :changed, :integer, null: false, default: 0
      add :date_sent, :integer, null: false, default: 0
      add :email_list, :string
      add :is_one_per_account, :integer, null: false
      add :is_track_links, :integer, null: false
      timestamps()
    end
    create index(:bx_massmailer_campaigns, [:title])
  end
end
