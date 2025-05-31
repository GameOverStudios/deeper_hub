# Migração Elixir: Criar Tabela `sys_modules`

Este módulo de migração Elixir cria a tabela `sys_modules` no banco de dados SQLite. Esta tabela é o registro central de todos os módulos instalados no sistema UNA, contendo informações sobre seu tipo, nome, versão, caminho, URI, prefixos e status.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_modules_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysModulesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_modules.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_modules...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_modules (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL DEFAULT 'module' CHECK(type IN ('module', 'template', 'language', 'payment', 'storage', 'profile', 'context')), -- Tipos comuns do UNA
      subtypes INTEGER NOT NULL DEFAULT 0, -- Máscara de bits para subtipos
      name TEXT NOT NULL UNIQUE, -- Nome único do módulo, ex: bx_persons
      title TEXT NOT NULL, -- Título do módulo (pode ser chave de tradução)
      vendor TEXT NOT NULL DEFAULT '',
      version TEXT NOT NULL DEFAULT '',
      help_url TEXT NOT NULL DEFAULT '',
      path TEXT NOT NULL UNIQUE, -- Caminho relativo para os arquivos do módulo
      uri TEXT NOT NULL UNIQUE, -- URI base para o módulo, ex: persons
      class_prefix TEXT NOT NULL UNIQUE, -- Prefixo da classe PHP, ex: BxPersons
      db_prefix TEXT NOT NULL UNIQUE, -- Prefixo para tabelas do módulo, ex: bx_persons_
      lang_category TEXT NOT NULL, -- Categoria de tradução, ex: Persons
      dependencies TEXT NOT NULL DEFAULT '', -- CSV ou JSON de dependências de módulos
      date INTEGER NOT NULL DEFAULT 0, -- Unix Timestamp da instalação/atualização
      enabled INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      pending_uninstall INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      hash TEXT NOT NULL DEFAULT '', -- Hash dos arquivos do módulo
      updated INTEGER NOT NULL DEFAULT 0 -- Unix Timestamp da última atualização de registro
    );
    CREATE INDEX IF NOT EXISTS idx_sys_modules_name ON sys_modules(name);
    CREATE INDEX IF NOT EXISTS idx_sys_modules_uri ON sys_modules(uri);
    CREATE INDEX IF NOT EXISTS idx_sys_modules_enabled ON sys_modules(enabled);
    CREATE INDEX IF NOT EXISTS idx_sys_modules_type ON sys_modules(type);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_modules criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_modules: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_modules...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_modules;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_modules removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_modules: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   `name`: O identificador programático do módulo (ex: `bx_persons`).
*   `path`, `uri`, `class_prefix`, `db_prefix`: Cruciais para o UNA PHP localizar arquivos, classes e tabelas do módulo. A API \"Deeper\" pode usar `db_prefix` para construir nomes de tabelas dinamicamente se necessário, e `uri` pode informar o roteamento do cliente.
*   `enabled`: Indica se o módulo está ativo. A API \"Deeper\" deve primariamente expor funcionalidades de módulos habilitados.
*   `lang_category`: Usado para buscar traduções específicas do módulo.
*   `title`: Pode ser uma chave de tradução (ex: `_bx_persons_module_title`) que o `LocalizationRepo` resolveria.