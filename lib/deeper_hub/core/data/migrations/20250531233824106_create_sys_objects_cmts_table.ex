# Migração gerada com ID único: V1748745504106 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysObjectsCmtsTable do
  # Migração gerada com ID único: V1748745504106 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_objects_cmts.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_objects_cmts.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_objects_cmts...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_cmts (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Name TEXT NOT NULL UNIQUE,
      Module TEXT NOT NULL,
      "Table" TEXT NOT NULL, -- Nome da tabela que armazena os comentários
      CharsPostMin INTEGER NOT NULL DEFAULT 1,
      CharsPostMax INTEGER NOT NULL DEFAULT 2048,
      CharsDisplayMax INTEGER NOT NULL DEFAULT 1000,
      Html INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      PerView INTEGER NOT NULL DEFAULT 10,
      PerViewReplies INTEGER NOT NULL DEFAULT 3,
      BrowseType TEXT NOT NULL DEFAULT 'tail' CHECK(BrowseType IN ('head', 'tail', 'popular', 'author_head', 'author_tail')), -- Adaptado do UNA
      IsBrowseSwitch INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      PostFormPosition TEXT NOT NULL DEFAULT 'bottom' CHECK(PostFormPosition IN ('top', 'bottom')),
      NumberOfLevels INTEGER NOT NULL DEFAULT 0, -- 0 para ilimitado
      IsDisplaySwitch INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      IsRatable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      ViewingThreshold INTEGER NOT NULL DEFAULT -3,
      IsOn INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      RootStylePrefix TEXT NOT NULL DEFAULT 'cmt',
      BaseUrl TEXT NOT NULL,
      ObjectVote TEXT, -- Nome do objeto sys_objects_vote
      ObjectReaction TEXT, -- Nome do objeto sys_objects_reaction
      ObjectScore TEXT, -- Nome do objeto sys_objects_score
      ObjectReport TEXT, -- Nome do objeto sys_objects_report
      TriggerTable TEXT,
      TriggerFieldId TEXT,
      TriggerFieldAuthor TEXT,
      TriggerFieldTitle TEXT,
      TriggerFieldComments TEXT,
      ClassName TEXT,
      ClassFile TEXT
      -- FK para Module (sys_modules.name)
    );

    CREATE INDEX IF NOT EXISTS idx_sys_objects_cmts_name ON sys_objects_cmts(Name);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_cmts_module ON sys_objects_cmts(Module);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_objects_cmts criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_objects_cmts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_objects_cmts.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_objects_cmts...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_objects_cmts;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_objects_cmts removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_objects_cmts: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end