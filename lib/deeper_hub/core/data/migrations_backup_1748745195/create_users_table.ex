defmodule DeeperHub.Core.Data.Migrations.CreateUsersTable do
  @moduledoc """
  Migração para criar a tabela de usuários no banco de dados.

  Esta migração cria a estrutura básica para armazenar informações de usuários
  no sistema DeeperHub, incluindo dados de autenticação e perfil.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela de usuários.

  Retorna `:ok` se a migração foi aplicada com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela de usuários...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      full_name TEXT,
      bio TEXT,
      avatar_url TEXT,
      status TEXT DEFAULT 'offline',
      last_seen TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
    CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de usuários criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de usuários: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela de usuários.

  Retorna `:ok` se a reversão foi aplicada com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela de usuários...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS users;
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de usuários removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de usuários: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
