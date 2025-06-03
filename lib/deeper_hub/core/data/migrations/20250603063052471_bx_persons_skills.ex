defmodule DeeperHub.Core.Data.Migrations.BxPersonsSkills do
  @moduledoc """
  Migration para criar e remover a tabela bx_persons_skills.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_persons_skills.
  """
  def up do
    Logger.info("Criando tabela de bx_persons_skills...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_persons_skills (
    skill_id INTEGER NOT NULL,
    skill_name TEXT NULL,
    content_id INTEGER NOT NULL,
      PRIMARY KEY (id)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_persons_skills criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_persons_skills: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_persons_skills.
  """
  def down do
    Logger.info("Removendo tabela de bx_persons_skills...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_persons_skills
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_persons_skills removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_persons_skills: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
