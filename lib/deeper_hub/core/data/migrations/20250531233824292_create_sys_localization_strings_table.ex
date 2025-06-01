# Migração gerada com ID único: V1748745504292 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysLocalizationStringsTable do
  # Migração gerada com ID único: V1748745504292 em 2025-05-31 23:38:24
  @moduledoc "Migração para criar a tabela sys_localization_strings."
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  def up do
    Logger.info("Criando tabela sys_localization_strings...", module: __MODULE__)
    # Repo.execute("PRAGMA foreign_keys = ON;")
    sql = """
    CREATE TABLE IF NOT EXISTS sys_localization_strings (
      IDKey INTEGER NOT NULL,
      IDLanguage INTEGER NOT NULL,
      String TEXT NOT NULL,
      PRIMARY KEY (IDKey, IDLanguage),
      FOREIGN KEY (IDKey) REFERENCES sys_localization_keys(ID) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (IDLanguage) REFERENCES sys_localization_languages(ID) ON DELETE CASCADE ON UPDATE CASCADE
    );
    """

    Repo.execute(sql)
    |> tap(fn
      {:ok, _} ->
        Logger.info("Tabela sys_localization_strings criada com sucesso.", module: __MODULE__)

      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_localization_strings: #{inspect(reason)}",
          module: __MODULE__
        )
    end)
  end

  def down do
    Logger.info("Removendo tabela sys_localization_strings...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_localization_strings;"

    Repo.execute(sql)
    |> tap(fn
      {:ok, _} ->
        Logger.info("Tabela sys_localization_strings removida com sucesso.", module: __MODULE__)

      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_localization_strings: #{inspect(reason)}",
          module: __MODULE__
        )
    end)
  end
end
