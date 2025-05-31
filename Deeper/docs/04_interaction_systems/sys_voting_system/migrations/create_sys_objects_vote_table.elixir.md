# Migração Elixir: Criar Tabela `sys_objects_vote`

Este módulo de migração Elixir é responsável por criar a tabela `sys_objects_vote` no banco de dados SQLite. Esta tabela armazena as configurações para diferentes instâncias de sistemas de votação/avaliação.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_objects_vote_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysObjectsVoteTable do
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
      TableMain TEXT NOT NULL,
      TableTrack TEXT NOT NULL,
      PostTimeout INTEGER NOT NULL DEFAULT 86400,
      MinValue INTEGER NOT NULL DEFAULT 1,
      MaxValue INTEGER NOT NULL DEFAULT 5,
      Pruning INTEGER NOT NULL DEFAULT 0,
      IsUndo INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      IsOn INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      TriggerTable TEXT,
      TriggerFieldId TEXT,
      TriggerFieldRate TEXT,
      TriggerFieldRateCount TEXT,
      ClassName TEXT, -- Específico do UNA PHP
      ClassFile TEXT -- Específico do UNA PHP
    );
    CREATE INDEX IF NOT EXISTS idx_sys_objects_vote_name ON sys_objects_vote(Name);
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

## Notas:

*   `Name`: Identificador único para o sistema de votação (ex: `bx_persons` para avaliação de perfis).
*   `TableMain`: Nome da tabela SQL que armazena os dados agregados dos votos (ex: `bx_persons_votes`).
*   `TableTrack`: Nome da tabela SQL que armazena os votos individuais (ex: `bx_persons_votes_track`).
*   `TriggerTable`, `TriggerFieldId`, `TriggerFieldRate`, `TriggerFieldRateCount`: Usados para atualizar a média e contagem de votos na tabela do conteúdo pai (ex: `bx_persons_data`).