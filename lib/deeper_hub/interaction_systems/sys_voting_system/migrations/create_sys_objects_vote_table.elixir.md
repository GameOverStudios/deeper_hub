# Migração Elixir: Criar Tabela `sys_objects_vote`

Este módulo de migração Elixir é responsável por criar a tabela `sys_objects_vote` no banco de dados SQLite. Esta tabela de configuração define cada \"objeto de voto\" (ou sistema de avaliação) para diferentes tipos de conteúdo no UNA, especificando as tabelas de dados e comportamento.

## Código da Migração (`lib/deeper/interaction_systems/voting/migrations/create_sys_objects_vote_table.ex`)

```elixir
defmodule Deeper.InteractionSystems.Voting.Migrations.CreateSysObjectsVoteTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_objects_vote.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_objects_vote.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_objects_vote...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_vote (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Name TEXT NOT NULL UNIQUE,
      Module TEXT NOT NULL,
      TableMain TEXT NOT NULL, -- Tabela de sumário dos votos
      TableTrack TEXT NOT NULL, -- Tabela de rastreamento de votos
      PostTimeout INTEGER NOT NULL DEFAULT 0,
      MinValue INTEGER NOT NULL DEFAULT 1,
      MaxValue INTEGER NOT NULL DEFAULT 5,
      Pruning INTEGER NOT NULL DEFAULT 31536000, -- 1 ano em segundos
      IsUndo INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      IsOn INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      TriggerTable TEXT,
      TriggerFieldId TEXT,
      TriggerFieldAuthor TEXT,
      TriggerFieldRate TEXT, -- Coluna para média da avaliação
      TriggerFieldRateCount TEXT, -- Coluna para contagem de votos
      ClassName TEXT,
      ClassFile TEXT
      -- FK para Module (sys_modules.name)
    );

    CREATE INDEX IF NOT EXISTS idx_sys_objects_vote_name ON sys_objects_vote(Name);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_vote_module ON sys_objects_vote(Module);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_vote criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_objects_vote: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_objects_vote.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_objects_vote...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_objects_vote;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_vote removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_objects_vote: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `ID`: `INT UNSIGNED` -> `INTEGER PRIMARY KEY AUTOINCREMENT`.
*   Colunas `VARCHAR` e `TEXT` do MySQL -> `TEXT` no SQLite. `Name` é `UNIQUE`.
*   Colunas `INT` e `TINYINT` do MySQL -> `INTEGER` no SQLite.