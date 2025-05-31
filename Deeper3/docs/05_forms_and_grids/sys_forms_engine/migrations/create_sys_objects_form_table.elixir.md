# Migração Elixir: Criar Tabela `sys_objects_form`

Este módulo de migração Elixir é responsável por criar a tabela `sys_objects_form` no banco de dados SQLite. Esta tabela é a principal definição para cada instância de formulário no sistema UNA, especificando seu nome de objeto, módulo, tabela de destino dos dados, e outras configurações.

## Código da Migração (`lib/deeper/forms/migrations/create_sys_objects_form_table.ex`)

```elixir
defmodule Deeper.Forms.Migrations.CreateSysObjectsFormTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_objects_form.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_objects_form.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_objects_form...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_form (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL UNIQUE,
      module TEXT NOT NULL,
      title TEXT NOT NULL,
      action TEXT NOT NULL,
      form_attrs TEXT,
      submit_name TEXT NOT NULL,
      \"table\" TEXT NOT NULL, -- Tabela do BD onde os dados são salvos
      \"key\" TEXT NOT NULL, -- Coluna da PK na 'table'
      uri TEXT, -- Coluna para URI/slug na 'table'
      uri_title TEXT, -- Coluna para o título usado para gerar o URI
      params TEXT,
      deletable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      active INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      parent_form TEXT,
      override_class_name TEXT,
      override_class_file TEXT
      -- FK para module (sys_modules.name)
    );

    CREATE INDEX IF NOT EXISTS idx_sys_objects_form_object ON sys_objects_form(object);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_form_module ON sys_objects_form(module);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_form criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_objects_form: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_objects_form.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_objects_form...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_objects_form;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_form removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_objects_form: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11)` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT`.
*   Colunas `VARCHAR`/`TEXT` do MySQL -> `TEXT`. `object` é `UNIQUE`.
*   Colunas `TINYINT` (para booleanos) -> `INTEGER`.
*   `\"table\"` e `\"key\"` estão entre aspas para evitar conflito com palavras reservadas.