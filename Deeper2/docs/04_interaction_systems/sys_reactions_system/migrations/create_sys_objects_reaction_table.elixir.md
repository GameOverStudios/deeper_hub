# Migração Elixir: Criar Tabela `sys_objects_reaction` (Hipotética)

Este módulo de migração Elixir é responsável por criar uma tabela de configuração hipotética `sys_objects_reaction` no banco de dados SQLite. Esta tabela definiria cada \"objeto de reação\" para diferentes tipos de conteúdo, especificando as reações disponíveis, as tabelas de dados e o comportamento.

**Nota:** O dump SQL original do UNA não incluía uma `sys_objects_reaction` para conteúdo principal de forma tão explícita quanto para votos ou scores. Esta definição é uma suposição de como tal sistema poderia ser configurado, ou como uma tabela existente poderia ser adaptada.

## Código da Migração (`lib/deeper/interaction_systems/reactions/migrations/create_sys_objects_reaction_table.ex`)

```elixir
defmodule Deeper.InteractionSystems.Reactions.Migrations.CreateSysObjectsReactionTable do
  @moduledoc \"\"\"
  Migração para criar a tabela de configuração sys_objects_reaction (hipotética).
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_objects_reaction.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_objects_reaction (hipotética)...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_reaction (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      module TEXT NOT NULL,
      reactions_available TEXT NOT NULL DEFAULT '[\"like\", \"love\", \"haha\", \"wow\", \"sad\", \"angry\"]', -- JSON array ou string CSV
      table_summary TEXT NOT NULL, -- Tabela de sumário de reações
      table_track TEXT NOT NULL, -- Tabela de rastreamento de reações
      is_undo INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se reação pode ser desfeita/alterada)
      is_on INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      trigger_table TEXT,
      trigger_field_id TEXT,
      trigger_field_reactions_count TEXT, -- Coluna para contagem total ou JSON de contagens por tipo
      class_name TEXT,
      class_file TEXT
      -- FK para Module (sys_modules.name)
    );

    CREATE INDEX IF NOT EXISTS idx_sys_objects_reaction_name ON sys_objects_reaction(name);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_reaction_module ON sys_objects_reaction(Module);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_reaction criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_objects_reaction: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_objects_reaction.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_objects_reaction...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_objects_reaction;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_reaction removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_objects_reaction: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Esta tabela é uma suposição baseada em outros sistemas de interação do UNA.
*   `reactions_available`: Poderia ser uma string JSON (ex: `[\"like\", \"love\"]`) ou uma referência a uma `sys_form_pre_lists.key` que contém as reações.