# Migração Elixir: Criar Tabela `sys_storage_tokens`

Este módulo de migração Elixir cria a tabela `sys_storage_tokens` no banco de dados SQLite. Esta tabela é usada no UNA para armazenar tokens de acesso de curta duração para arquivos privados, permitindo o acesso sem expor credenciais de longo prazo ou exigir uma sessão de usuário completa para cada download.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_storage_tokens_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysStorageTokensTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_storage_tokens.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_storage_tokens...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_storage_tokens (
      iid INTEGER PRIMARY KEY AUTOINCREMENT, -- Chave primária interna
      id INTEGER NOT NULL, -- ID do arquivo na sua tabela de metadados
      object TEXT NOT NULL, -- Nome do sys_objects_storage
      hash TEXT NOT NULL, -- O token de acesso em si (geralmente um hash aleatório)
      created INTEGER NOT NULL -- Unix Timestamp de criação do token
    );
    -- Um token deve ser único para um arquivo em um storage object.
    CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_storage_tokens_id_object_hash ON sys_storage_tokens(id, object, hash);
    CREATE INDEX IF NOT EXISTS idx_sys_storage_tokens_created ON sys_storage_tokens(created);
    CREATE INDEX IF NOT EXISTS idx_sys_storage_tokens_hash ON sys_storage_tokens(hash); -- Para busca rápida pelo token
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_storage_tokens criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_storage_tokens: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_storage_tokens...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_storage_tokens;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_storage_tokens removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_storage_tokens: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   `id` e `object`: Identificam o arquivo específico para o qual o token é válido.
*   `hash`: O valor do token aleatório.
*   `created`: Usado para calcular a expiração do token (ex: `created + sys_objects_storage.token_life`).
*   Tokens expirados são limpos periodicamente por um cron job no UNA.