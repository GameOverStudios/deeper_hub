defmodule DeeperHub.Core.Data.Migrations.SysFormFieldsReactionTrack do
  @moduledoc """
  Migration para criar e remover a tabela sys_form_fields_reaction_track.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_form_fields_reaction_track.
  """
  def up do
    Logger.info("Criando tabela de sys_form_fields_reaction_track...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_form_fields_reaction_track (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object_id INTEGER NOT NULL DEFAULT 0,
    author_id INTEGER NOT NULL DEFAULT 0,
    author_nip INTEGER NOT NULL DEFAULT 0,
    reaction TEXT NOT NULL,
    value INTEGER NOT NULL DEFAULT 0,
    date INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_fields_reaction_track criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_form_fields_reaction_track: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_form_fields_reaction_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_form_fields_reaction_track.
  """
  def down do
    Logger.info("Removendo tabela de sys_form_fields_reaction_track...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_form_fields_reaction_track
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_fields_reaction_track removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_form_fields_reaction_track: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_form_fields_reaction_track: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
