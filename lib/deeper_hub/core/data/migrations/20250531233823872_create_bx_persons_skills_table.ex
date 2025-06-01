# Migração gerada com ID único: V1748745503871 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateBxPersonsSkillsTable do
  # Migração gerada com ID único: V1748745503871 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela bx_persons_skills.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela bx_persons_skills.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela bx_persons_skills...", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS bx_persons_skills (
      skill_id INTEGER PRIMARY KEY AUTOINCREMENT,
      skill_name TEXT, -- No UNA é VARCHAR(500)
      content_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil que possui a habilidade)
      FOREIGN KEY (content_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_skills_content_id ON bx_persons_skills(content_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_skills_skill_name ON bx_persons_skills(skill_name);
    -- Para evitar duplicatas de skill_name por content_id:
    CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_persons_skills_content_skill ON bx_persons_skills(content_id, skill_name);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_skills criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela bx_persons_skills: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela bx_persons_skills.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela bx_persons_skills...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS bx_persons_skills;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_skills removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela bx_persons_skills: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end