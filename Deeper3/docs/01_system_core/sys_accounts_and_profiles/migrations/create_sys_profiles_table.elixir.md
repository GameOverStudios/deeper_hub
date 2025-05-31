# Migração Elixir: Criar Tabela `sys_profiles`

Este módulo de migração Elixir é responsável por criar a tabela `sys_profiles` no banco de dados SQLite. Esta tabela serve como um elo entre uma conta de usuário (`sys_accounts`) e os dados específicos de seus diferentes tipos de perfis (ex: um perfil de pessoa em `bx_persons_data`, um perfil de organização em uma futura tabela `bx_organizations_data`, etc.).

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

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_profiles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      account_id INTEGER NOT NULL,
      type TEXT NOT NULL,
      content_id INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'pending', 'suspended')),
      FOREIGN KEY (account_id) REFERENCES sys_accounts(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_profiles_account_id ON sys_profiles(account_id);
    CREATE INDEX IF NOT EXISTS idx_sys_profiles_type_content_id ON sys_profiles(type, content_id);
    CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_profiles_account_type_content ON sys_profiles(account_id, type, content_id);
    \"\"\"
    # Adicionando PRAGMA para habilitar FKs se necessário para esta sessão de execução
    # Idealmente, isso é configurado na conexão do Repo.
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")

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

*   A coluna `account_id` é uma chave estrangeira que referencia `sys_accounts.id`. A cláusula `ON DELETE CASCADE` garante que, se uma conta for excluída, todos os seus perfis associados também serão removidos. `ON UPDATE CASCADE` (se suportado e desejado para SQLite neste contexto) propagaria atualizações no `sys_accounts.id` (embora IDs de PK raramente mudem).
*   A coluna `type` armazena uma string que identifica o tipo de perfil (ex: \"bx_persons\", \"bx_organizations\").
*   A coluna `content_id` armazena o ID da entrada na tabela de dados específica para aquele `type` (ex: `id` da tabela `bx_persons_data`).
*   O índice `idx_sys_profiles_account_type_content` garante que uma conta não possa ter múltiplos perfis do mesmo tipo apontando para o mesmo `content_id`.
*   **Habilitação de Chaves Estrangeiras no SQLite:** Para que as constraints de chave estrangeira funcionem no SQLite, elas precisam ser habilitadas por conexão usando `PRAGMA foreign_keys = ON;`. É importante garantir que o módulo `Deeper.Core.Data.Repo` configure isso ao abrir conexões, ou que seja executado antes de DMLs que dependam de FKs. Para DDLs como `CREATE TABLE`, a definição da FK é geralmente aceita mesmo que a pragma não esteja ativa, mas a *imposição* da restrição ocorre em tempo de execução de DMLs se a pragma estiver `ON`.