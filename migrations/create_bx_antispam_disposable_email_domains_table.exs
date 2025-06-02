defmodule Repo.Migrations.CreateBxAntispamDisposableEmailDomains do
  use Ecto.Migration

  def change do
    create table(:bx_antispam_disposable_email_domains, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :domain, :string, null: false
      add :list, :string, null: false, default: "custom_blacklist"
      timestamps()
    end
    create index(:bx_antispam_disposable_email_domains, [:domain], unique: true)
  end
end
