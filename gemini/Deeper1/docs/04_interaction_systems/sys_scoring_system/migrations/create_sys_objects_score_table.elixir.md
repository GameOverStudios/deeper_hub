# Migração Elixir: Criar Tabela `sys_objects_score`

Este módulo de migração Elixir cria a tabela `sys_objects_score` no banco de dados SQLite, que armazena as configurações para diferentes instâncias de sistemas de pontuação (up/down vote).

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_objects_score_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysObjectsScoreTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_objects_score.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_objects_score.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_objects_score...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_score (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      module TEXT NOT NULL,
      table_main TEXT NOT NULL, -- Tabela de agregação, ex: bx_persons_scores
      table_track TEXT NOT NULL, -- Tabela de rastreamento, ex: bx_persons_scores_track
      post_timeout INTEGER NOT NULL DEFAULT 0, -- Em segundos
      pruning INTEGER NOT NULL DEFAULT 0, -- Dias para manter votos em track
      is_undo INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      is_on INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      trigger_table TEXT,
      trigger_field_id TEXT,
      trigger_field_author TEXT, -- Geralmente não usado para scores
      trigger_field_score TEXT, -- Coluna para score (up-down)
      trigger_field_cup TEXT, -- Coluna para count_up
      trigger_field_cdown TEXT, -- Coluna para count_down
      class_name TEXT, -- Específico do UNA PHP
      class_file TEXT -- Específico do UNA PHP
    );
    CREATE INDEX IF NOT EXISTS idx_sys_objects_score_name ON sys_objects_score(name);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_score criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_objects_score: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_objects_score.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_objects_score...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_objects_score;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_score removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_objects_score: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   `name`: Identificador único para o sistema de pontuação (ex: `bx_persons_score`).
*   `table_main`: Nome da tabela SQL que armazena os dados agregados das pontuações (contagens up/down).
*   `table_track`: Nome da tabela SQL que armazena os votos individuais de up/down.
*   `trigger_table`, `trigger_field_score`, `trigger_field_cup`, `trigger_field_cdown`: Usados para atualizar a pontuação e contagens na tabela do conteúdo pai.