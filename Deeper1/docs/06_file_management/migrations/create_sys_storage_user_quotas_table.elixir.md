# Migração Elixir: Criar Tabela `sys_storage_user_quotas`

Este módulo de migração Elixir cria a tabela `sys_storage_user_quotas` no banco de dados SQLite. Esta tabela rastreia o uso atual de armazenamento por perfil de usuário, para impor cotas individuais (que podem ser definidas em `sys_acl_levels`).

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_storage_user_quotas_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysStorageUserQuotasTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_storage_user_quotas.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_storage_user_quotas...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_storage_user_quotas (
      profile_id INTEGER PRIMARY KEY, -- FK para sys_profiles.id
      current_size INTEGER NOT NULL DEFAULT 0, -- Tamanho total usado em bytes
      current_number INTEGER NOT NULL DEFAULT 0, -- Número total de arquivos
      ts INTEGER NOT NULL DEFAULT 0 -- Unix Timestamp da última atualização
      -- FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
    );
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_storage_user_quotas criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_storage_user_quotas: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_storage_user_quotas...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_storage_user_quotas;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_storage_user_quotas removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_storage_user_quotas: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   `profile_id`: O `sys_profiles.id` do usuário.
*   `current_size` e `current_number`: Rastreiam o uso agregado de todos os storage objects pelo usuário.
*   As cotas reais (limites) são geralmente definidas em `sys_acl_levels.QuotaSize` e `sys_acl_levels.QuotaNumber`. A lógica de upload verifica o uso atual nesta tabela contra os limites do nível do usuário.