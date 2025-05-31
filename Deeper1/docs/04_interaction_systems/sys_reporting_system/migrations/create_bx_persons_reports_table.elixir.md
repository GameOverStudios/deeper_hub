# Migração Elixir: Criar Tabela `bx_persons_reports` (Agregação de Denúncias para Pessoas)

Este módulo de migração Elixir cria a tabela `bx_persons_reports` no SQLite, para agregação de denúncias de perfis de pessoas.

Esta é um exemplo de uma tabela `table_main` referenciada em `sys_objects_report`.

## Código da Migração (`lib/deeper/core/data/migrations/create_bx_persons_reports_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateBxPersonsReportsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela de agregação de denúncias bx_persons_reports.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_reports.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_reports...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_reports (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL UNIQUE, -- FK para bx_persons_data.id
      count INTEGER NOT NULL DEFAULT 0
      -- FOREIGN KEY (object_id) REFERENCES bx_persons_data(id) ON DELETE CASCADE -- Opcional
    );
    CREATE INDEX IF NOT EXISTS idx_bx_persons_reports_object_id ON bx_persons_reports(object_id);
    \"\"\"
    # O schema original do UNA tem id como PK e object_id como UNIQUE.
    # Esta abordagem é mantida.

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_reports criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_persons_reports: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_persons_reports.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_persons_reports...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS bx_persons_reports;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_reports removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_persons_reports: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   `object_id`: Corresponde ao `id` da tabela `bx_persons_data` (o perfil que foi denunciado).
*   `count`: Número total de denúncias recebidas por este `object_id`.