defmodule Repo.Migrations.CreateSysIframelyData do
  use Ecto.Migration

  def change do
    create table(:sys_iframely_data, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :url, :string
      add :data, :string
      add :added, :integer
      add :theme, :string
      timestamps()
    end
  end
end
