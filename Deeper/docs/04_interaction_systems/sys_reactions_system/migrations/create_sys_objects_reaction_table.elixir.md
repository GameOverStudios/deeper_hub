# Migração Elixir: Criar Tabela `sys_objects_reaction`

Este módulo de migração Elixir cria a tabela `sys_objects_reaction` no banco de dados SQLite. Esta tabela armazena as configurações para diferentes instâncias de sistemas de reações (like, love, etc.).

*Nota: Esta tabela é uma generalização baseada nas tabelas de reação existentes no UNA (`sys_cmts_reactions`, `sys_form_fields_reaction`). Se uma tabela de configuração global para reações não existir no schema UNA que você está portando, esta pode ser uma adição \"Deeper\" ou adaptada de uma estrutura existente.*

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_objects_reaction_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysObjectsReactionTable do
  @moduledoc \"\"\"
  Migração para criar a tabela de configuração sys_objects_reaction.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_objects_reaction...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_reaction (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE, -- Nome do objeto de reação, ex: bx_posts_reactions
      module TEXT NOT NULL,
      -- Lista de reações permitidas, ex: '[\"like\", \"love\", \"haha\"]'
      available_reactions TEXT DEFAULT '[\"like\",\"love\",\"haha\",\"wow\",\"sad\",\"angry\"]',
      table_main TEXT NOT NULL, -- Tabela de agregação de contagem por tipo de reação
      table_track TEXT NOT NULL, -- Tabela de rastreamento de reações individuais
      is_undo INTEGER NOT NULL DEFAULT 1, -- Se o usuário pode mudar/remover a reação (geralmente sim)
      trigger_table TEXT, -- Tabela do conteúdo pai
      trigger_field_id TEXT, -- Coluna ID na trigger_table
      -- Coluna na trigger_table para armazenar um resumo JSON das reações
      trigger_field_reactions_summary TEXT
    );
    CREATE INDEX IF NOT EXISTS idx_sys_objects_reaction_name ON sys_objects_reaction(name);
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
  Reverte a migração.
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

*   `available_reactions`: Armazena um array JSON (como string) das reações permitidas (ex: `[\"like\", \"love\", \"haha\"]`).
*   `table_main`: Nome da tabela que armazena a contagem agregada para cada `reaction_type` por `object_id`.
*   `table_track`: Nome da tabela que armazena a reação individual de cada usuário para um `object_id`.
*   `trigger_field_reactions_summary`: Nome da coluna na `trigger_table` que pode armazenar um resumo JSON de todas as contagens de reações para fácil acesso.