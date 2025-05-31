# Migração Elixir: Criar Tabela `sys_localization_keys`

Este módulo de migração Elixir é responsável por criar a tabela `sys_localization_keys` no banco de dados SQLite. Esta tabela armazena as chaves de tradução únicas (ex: `_sys_txt_welcome`) e as associa a uma categoria de localização.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_localization_keys_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysLocalizationKeysTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_localization_keys.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_localization_keys.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_localization_keys...\", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_localization_keys (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      IDCategory INTEGER NOT NULL,
      \"Key\" TEXT NOT NULL UNIQUE, -- A chave de tradução, ex: '_sys_txt_hello'
      FOREIGN KEY (IDCategory) REFERENCES sys_localization_categories(ID) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_localization_keys_idcategory ON sys_localization_keys(IDCategory);
    CREATE INDEX IF NOT EXISTS idx_sys_localization_keys_key ON sys_localization_keys(\"Key\");
    -- Para emular o UNIQUE case-sensitive do UNA (utf8_bin) em SQLite, um índice com COLLATE BINARY seria:
    -- CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_localization_keys_key_cs ON sys_localization_keys(\"Key\" COLLATE BINARY);
    -- Por simplicidade inicial, o UNIQUE padrão do SQLite (geralmente case-insensitive para TEXT) é usado.
    -- A aplicação pode precisar lidar com a normalização de caixa se a sensibilidade for crítica.
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_localization_keys criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_localization_keys: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_localization_keys.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_localization_keys...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_localization_keys;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_localization_keys removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_localization_keys: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `ID`: `INT(10) UNSIGNED AUTO_INCREMENT` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `IDCategory`: `INT(6) UNSIGNED` (MySQL) -> `INTEGER` (SQLite). Chave estrangeira para `sys_localization_categories.ID`.
*   `Key`: `VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_bin` com `UNIQUE KEY` (MySQL) -> `\"Key\" TEXT NOT NULL UNIQUE` (SQLite).
    *   A coluna `Key` é referenciada como `\"Key\"` para evitar conflito com a palavra reservada SQL.
    *   **Sensibilidade de Caixa para `UNIQUE`:** O UNA usa `utf8_bin` para a coluna `Key` para garantir que a unicidade seja sensível a maiúsculas e minúsculas. No SQLite, a restrição `UNIQUE` em colunas `TEXT` é geralmente insensível a maiúsculas e minúsculas por padrão. Para replicar o comportamento do UNA, seria necessário um índice `UNIQUE` com `COLLATE BINARY` (comentado no SQL acima). Se essa sensibilidade de caixa for crítica, o índice com `COLLATE BINARY` deve ser usado. Caso contrário, a aplicação pode precisar normalizar a caixa das chaves antes de inseri-las ou buscá-las se a unicidade case-insensitive for aceitável.
*   **Chave Estrangeira:** Definida para `IDCategory`.