defmodule DeeperHub.Repo.Migrations.CreateConfigSettings do
  use Ecto.Migration

  def change do
    create table(:config_settings) do
      add :key, :string, null: false
      add :value, :text
      add :raw_value, :binary
      add :scope, :string, null: false, default: "global"
      add :data_type, :string, null: false
      add :is_sensitive, :boolean, default: false
      add :description, :text
      add :created_by, :string
      add :deleted_at, :utc_datetime
      add :deleted_by, :string

      timestamps()
    end

    # Índice para consultas por chave e escopo
    create unique_index(:config_settings, [:key, :scope], where: "deleted_at IS NULL")

    # Índice para consultas por escopo
    create index(:config_settings, [:scope], where: "deleted_at IS NULL")

    # Índice para consultas por chave com padrão
    create index(:config_settings, [:key], where: "deleted_at IS NULL")
  end
end
