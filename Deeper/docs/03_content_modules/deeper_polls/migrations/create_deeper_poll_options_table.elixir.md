# Migração Elixir: Criar Tabela `deeper_poll_options`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_poll_options` no banco de dados SQLite. Esta tabela armazena as opções de resposta disponíveis para cada enquete.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_poll_options_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperPollOptionsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_poll_options.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_poll_options.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_poll_options...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_poll_options (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      poll_id INTEGER NOT NULL,
      option_text TEXT NOT NULL,
      order_index INTEGER NOT NULL DEFAULT 0,
      votes_count INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (poll_id) REFERENCES deeper_polls(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_dpo_poll_id_order_index ON deeper_poll_options(poll_id, order_index);
    \"\"\"

    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_poll_options criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_poll_options: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_poll_options.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_poll_options...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_poll_options;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_poll_options removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_poll_options: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Esta tabela depende da existência de `deeper_polls` (para `poll_id`).
*   `ON DELETE CASCADE` para `poll_id` garante que se uma enquete for excluída, todas as suas opções de resposta também serão.
*   `order_index` permite que as opções sejam exibidas em uma ordem específica.
*   `votes_count` é uma contagem denormalizada dos votos para esta opção específica, que será atualizada pela lógica da aplicação ao registrar votos.