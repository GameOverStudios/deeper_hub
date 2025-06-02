defmodule Repo.Migrations.CreateSysStorageMimeTypes do
  use Ecto.Migration

  def change do
    create table(:sys_storage_mime_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ext, :string, null: false
      add :mime_type, :string, null: false
      add :icon, :string, null: false
      add :icon_font, :string, null: false
      timestamps()
    end
  end
end
