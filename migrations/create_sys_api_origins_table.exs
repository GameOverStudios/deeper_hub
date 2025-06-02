defmodule Repo.Migrations.CreateSysApiOrigins do
  use Ecto.Migration

  def change do
    create table(:sys_api_origins, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :url, :string, null: false
      add :order, :integer, null: false
      timestamps()
    end
  end
end
