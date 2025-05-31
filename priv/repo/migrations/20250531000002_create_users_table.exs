defmodule DeeperHub.DataAccess.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def up do
    # Remove índices anteriores se existirem
    execute "DROP INDEX IF EXISTS users_email_index"
    execute "DROP INDEX IF EXISTS users_username_index"
    execute "DROP INDEX IF EXISTS usuarios_email_index"
    execute "DROP INDEX IF EXISTS usuarios_nome_usuario_index"
    
    # Remove tabela anterior se existir
    execute "DROP TABLE IF EXISTS usuarios"
    
    # Cria nova tabela users
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :email, :string, null: false
      add :username, :string, null: false
      add :password_hash, :string
      add :active, :boolean, default: true, null: false
      add :last_login, :utc_datetime

      timestamps()
    end

    # Índices com novos nomes para evitar conflitos
    create index(:users, [:email], name: "users_email_idx")
    create index(:users, [:username], name: "users_username_idx")
    
    # Constraints de unicidade com novos nomes
    create unique_index(:users, [:email], name: "users_email_unique_idx")
    create unique_index(:users, [:username], name: "users_username_unique_idx")
  end
  
  def down do
    drop_if_exists table(:users)
    execute "DROP INDEX IF EXISTS users_email_idx"
    execute "DROP INDEX IF EXISTS users_username_idx"
    execute "DROP INDEX IF EXISTS users_email_unique_idx"
    execute "DROP INDEX IF EXISTS users_username_unique_idx"
  end
end
