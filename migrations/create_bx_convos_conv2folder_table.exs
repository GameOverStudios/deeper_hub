defmodule Repo.Migrations.CreateBxConvosConv2folder do
  use Ecto.Migration

  def change do
    create table(:bx_convos_conv2folder, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :conv_id, :integer, null: false
      add :folder_id, :integer, null: false
      add :collaborator, :integer, null: false
      add :read_comments, :integer, null: false, default: -1
      timestamps()
    end
    create index(:bx_convos_conv2folder, [:conv_id])
    create index(:bx_convos_conv2folder, [:collaborator])
  end
end
