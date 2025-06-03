defmodule DeeperHub.Core.Data.Migrations.SysAudit do
  @moduledoc """
  Migration para criar e remover a tabela sys_audit.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_audit.
  """
  def up do
    Logger.info("Criando tabela de sys_audit...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_audit (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    added INTEGER NOT NULL,
    profile_id INTEGER NOT NULL,
    profile_title TEXT NOT NULL,
    content_id INTEGER NOT NULL,
    content_title TEXT NOT NULL,
    content_module TEXT NOT NULL,
    content_info_object TEXT NOT NULL,
    context_profile_id INTEGER NOT NULL,
    context_profile_title TEXT NOT NULL,
    action_lang_key TEXT NOT NULL,
    action_lang_key_params TEXT NOT NULL,
    extras TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_audit criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_audit: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_audit: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_audit.
  """
  def down do
    Logger.info("Removendo tabela de sys_audit...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_audit
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_audit removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_audit: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_audit: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
