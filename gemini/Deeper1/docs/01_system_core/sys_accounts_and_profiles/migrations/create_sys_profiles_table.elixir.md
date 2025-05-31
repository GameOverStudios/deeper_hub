# Migração Elixir: Criar Tabela `sys_profiles`

Este módulo de migração Elixir é responsável por criar a tabela `sys_profiles` no banco de dados SQLite. Esta tabela serve como um elo entre uma conta de usuário (`sys_accounts`) e os dados específicos de um tipo de perfil (por exemplo, dados de uma pessoa em `bx_persons_data`).

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_profiles_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysProfilesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_profiles.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_profiles.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_profiles...\", module: __MODULE__)

    # Habilitar chaves estrangeiras para esta conexão, se não for o padrão do Repo
    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Descomente se necessário e se seu Repo não fizer isso automaticamente

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_profiles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      account_id INTEGER NOT NULL,
      type TEXT NOT NULL, -- Ex: 'bx_persons', 'bx_organizations'
      content_id INTEGER NOT NULL, -- ID na tabela de dados específica do tipo
      status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'pending', 'suspended')),
      FOREIGN KEY (account_id) REFERENCES sys_accounts(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_profiles_account_id ON sys_profiles(account_id);
    CREATE INDEX IF NOT EXISTS idx_sys_profiles_type_content_id ON sys_profiles(type, content_id);
    CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_profiles_account_type_content ON sys_profiles(account_id, type, content_id);
    \"\"\"
    # Adicionamos ON UPDATE CASCADE para a FK, embora o SQLite tenha um suporte limitado/comportamento específico para isso.
    # A principal preocupação é o ON DELETE CASCADE.

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_profiles criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_profiles: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_profiles.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_profiles...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_profiles;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_profiles removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_profiles: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   A coluna `account_id` possui uma chave estrangeira (`FOREIGN KEY`) que referencia `sys_accounts(id)`.
    *   `ON DELETE CASCADE`: Se uma conta em `sys_accounts` for deletada, todos os perfis associados em `sys_profiles` também serão deletados automaticamente.
    *   `ON UPDATE CASCADE`: Se o `id` de uma conta em `sys_accounts` for alterado (o que é incomum para chaves primárias autoincrementais, mas possível se fossem, por exemplo, UUIDs mutáveis), o `account_id` correspondente em `sys_profiles` seria atualizado. O suporte do SQLite para `ON UPDATE CASCADE` em chaves primárias autoincrementais é geralmente irrelevante, pois elas não mudam.
*   `type` e `content_id` juntos identificam o registro específico nos dados do módulo do perfil (ex: um registro em `bx_persons_data`).
*   Um índice único `idx_sys_profiles_account_type_content` garante que uma conta não possa ter múltiplos perfis do mesmo tipo apontando para o mesmo `content_id`.
*   É importante que a tabela `sys_accounts` exista antes de executar esta migração devido à dependência da chave estrangeira. O sistema de execução de migrações deve garantir a ordem correta.