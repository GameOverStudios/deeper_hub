defmodule Repo.Migrations.CreateBxSpacesFans do
  use Ecto.Migration

  def change do
    create table(:bx_spaces_fans, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :initiator, :integer, null: false
      add :content, :integer, null: false
      add :mutual, :integer, null: false
      add :added, :integer, null: false
      timestamps()
    end
    create index(:bx_spaces_fans, [:initiator])
    create index(:bx_spaces_fans, [:content])
  end
end
