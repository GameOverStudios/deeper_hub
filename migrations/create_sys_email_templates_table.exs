defmodule Repo.Migrations.CreateSysEmailTemplates do
  use Ecto.Migration

  def change do
    create table(:sys_email_templates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ID, :integer, null: false
      add :Module, :string, null: false
      add :NameSystem, :string, null: false
      add :Name, :string, null: false
      add :Subject, :string, null: false
      add :Body, :string, null: false
      timestamps()
    end
  end
end
