defmodule Repo.Migrations.CreateBxMassmailerSegments do
  use Ecto.Migration

  def change do
    create table(:bx_massmailer_segments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :info, :string
      add :email_list, :string
      timestamps()
    end
  end
end
