defmodule DeeperHub.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :topic, :string, null: false
      add :payload, :binary, null: false
      add :metadata, :map, default: %{}
      add :scope, :string, null: false, default: "global"
      add :status, :string, null: false, default: "pending"
      add :published_at, :utc_datetime, null: false
      add :delivered_at, :utc_datetime
      add :retry_count, :integer, default: 0
      add :publisher_id, :string
      add :error_message, :string

      timestamps()
    end

    # Índice para consultas por tópico
    create index(:events, [:topic])

    # Índice para consultas por status
    create index(:events, [:status])

    # Índice para consultas por data de publicação
    create index(:events, [:published_at])

    # Índice composto para tópico e escopo
    create index(:events, [:topic, :scope])
  end
end
