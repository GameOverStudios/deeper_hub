# Migração Elixir: (Exemplo) Criar Tabela de Sumário de Votos (`example_votes_summary`)

Este módulo de migração Elixir é um **exemplo** de como uma tabela de sumário de votos (referenciada por `sys_objects_vote.TableMain`) seria criada. O nome real da tabela (aqui `example_votes_summary`) é dinâmico.

Por exemplo, para o objeto de voto `bx_persons_ratings`, a `TableMain` poderia ser `bx_persons_votes`.

## Código da Migração (`lib/deeper/interaction_systems/voting/migrations/create_example_votes_summary_table.ex`)

```elixir
defmodule Deeper.InteractionSystems.Voting.Migrations.CreateExampleVotesSummaryTable do
  @moduledoc \"\"\"
  Migração EXEMPLO para criar uma tabela de sumário de votos.
  O nome real da tabela viria de sys_objects_vote.TableMain.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @table_name \"example_votes_summary\" # Este nome seria dinâmico

  @doc \"\"\"
  Executa a migração para criar a tabela de exemplo.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela de exemplo de sumário de votos: #{@table_name}...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS #{@table_name} (
      -- A PK no UNA varia; às vezes é 'id' AUTO_INCREMENT, às vezes 'object_id' é PK.
      -- Vamos usar 'id' AUTO_INCREMENT e 'object_id' UNIQUE para este exemplo.
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL UNIQUE, -- ID do item de conteúdo que foi votado
      count INTEGER NOT NULL DEFAULT 0, -- Número total de votos
      sum INTEGER NOT NULL DEFAULT 0 -- Soma de todos os valores de votos
      -- A FK para object_id dependeria do tipo de conteúdo específico.
    );

    CREATE INDEX IF NOT EXISTS idx_#{@table_name}_object_id ON #{@table_name}(object_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela #{@table_name} criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela #{@table_name}: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela de exemplo.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela #{@table_name}...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS #{@table_name};\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela #{@table_name} removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela #{@table_name}: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   A estrutura exata (especialmente a chave primária) das tabelas `TableMain` no UNA pode variar. Algumas usam `object_id` como PK, outras têm um `id` autoincrementável separado. Este exemplo usa `id` autoincrementável e `object_id UNIQUE`.