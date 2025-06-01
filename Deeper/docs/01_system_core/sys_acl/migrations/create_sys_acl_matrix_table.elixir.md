# Migração Elixir: Criar Tabela `sys_acl_matrix`

Este módulo de migração Elixir é responsável por criar a tabela `sys_acl_matrix` no banco de dados SQLite. Esta é a tabela central do ACL, definindo quais ações (`sys_acl_actions.ID`) são permitidas para quais níveis (`sys_acl_levels.ID`), e sob quais condições (contagem, período).

## Código da Migração (`lib/deeper/core/data/migrations/acl/create_sys_acl_matrix_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.ACL.CreateSysAclMatrixTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_acl_matrix.
  Depende da existência das tabelas `sys_acl_levels` e `sys_acl_actions`.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_acl_matrix.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_acl_matrix...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_acl_matrix (
      IDLevel INTEGER NOT NULL,
      IDAction INTEGER NOT NULL,
      AllowedCount INTEGER, -- NULL para ilimitado
      AllowedPeriodLen INTEGER, -- Segundos, NULL se não aplicável
      AllowedPeriodStart INTEGER, -- Unix Timestamp
      AllowedPeriodEnd INTEGER, -- Unix Timestamp
      AdditionalParamValue TEXT,
      PRIMARY KEY (IDLevel, IDAction),
      FOREIGN KEY (IDLevel) REFERENCES sys_acl_levels(ID) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (IDAction) REFERENCES sys_acl_actions(ID) ON DELETE CASCADE ON UPDATE CASCADE
    );
    \"\"\"
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_acl_matrix criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_acl_matrix: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_acl_matrix.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_acl_matrix...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_acl_matrix;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_acl_matrix removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_acl_matrix: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   A chave primária `(IDLevel, IDAction)` define uma regra de permissão única.
*   `AllowedCount` especifica o número de vezes que a ação é permitida. Se `NULL`, é ilimitado.
*   `AllowedPeriodLen` define a duração (em segundos) do período em que `AllowedCount` é válido.
*   `AllowedPeriodStart` e `AllowedPeriodEnd` são menos comuns de serem usados diretamente para a lógica de período, que geralmente é gerenciada em conjunto com `sys_acl_actions_track.ValidSince`.
*   `AdditionalParamValue` é usado se a ação em `sys_acl_actions` tiver um `AdditionalParamName`.