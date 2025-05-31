# Migração Elixir: Criar Tabela `sys_objects_cmts`

Este módulo de migração Elixir é responsável por criar a tabela `sys_objects_cmts` no banco de dados SQLite. Esta tabela armazena as configurações para diferentes instâncias de sistemas de comentários usados por módulos ou tipos de conteúdo no UNA.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_objects_cmts_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysObjectsCmtsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_objects_cmts.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_objects_cmts.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_objects_cmts...\", module: __MODULE__)

    # No schema original do UNA, a coluna `Name` é o identificador principal.
    # Renomeada para `ObjectName` para evitar conflito com `Name` de idioma.
    # No entanto, o dump usa `Name` então vamos manter `Name` por fidelidade inicial.
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_cmts (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Name TEXT NOT NULL UNIQUE, -- Nome do objeto de comentário, ex: bx_persons_profile
      Module TEXT NOT NULL,
      \"Table\" TEXT NOT NULL, -- Nome da tabela SQL dos comentários, ex: bx_persons_cmts
      CharsPostMin INTEGER NOT NULL DEFAULT 1,
      CharsPostMax INTEGER NOT NULL DEFAULT 1000,
      CharsDisplayMax INTEGER NOT NULL DEFAULT 200,
      Html INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      PerView INTEGER NOT NULL DEFAULT 10,
      PerViewReplies INTEGER NOT NULL DEFAULT 3,
      BrowseType TEXT DEFAULT 'list', -- 'list', 'tree'
      IsBrowseSwitch INTEGER NOT NULL DEFAULT 1,
      PostFormPosition TEXT DEFAULT 'bottom', -- 'bottom', 'top'
      NumberOfLevels INTEGER NOT NULL DEFAULT 3,
      IsDisplaySwitch INTEGER NOT NULL DEFAULT 1,
      IsRatable INTEGER NOT NULL DEFAULT 0, -- Renomeado de IsRatable no dump para 0 para evitar erro. Original é 1.
      ViewingThreshold INTEGER NOT NULL DEFAULT -3,
      IsOn INTEGER NOT NULL DEFAULT 1,
      RootStylePrefix TEXT DEFAULT 'cmt',
      BaseUrl TEXT,
      ObjectVote TEXT DEFAULT '',
      ObjectReaction TEXT DEFAULT '',
      ObjectScore TEXT DEFAULT '',
      ObjectReport TEXT DEFAULT '',
      TriggerTable TEXT,
      TriggerFieldId TEXT,
      TriggerFieldAuthor TEXT,
      TriggerFieldTitle TEXT,
      TriggerFieldComments TEXT,
      ClassName TEXT,
      ClassFile TEXT
    );
    CREATE INDEX IF NOT EXISTS idx_sys_objects_cmts_name ON sys_objects_cmts(Name);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_cmts criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_objects_cmts: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_objects_cmts.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_objects_cmts...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_objects_cmts;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_cmts removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_objects_cmts: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   A coluna `Name` (no UNA, `ObjectName` em algumas referências, mas o dump SQL usa `Name`) é o identificador chave que a API \"Deeper\" usará para selecionar a configuração correta do sistema de comentários (ex: `/api/v1/comments/{comments_object_name}/...`).
*   A coluna `\"Table\"` (com aspas para evitar conflito com a palavra-chave SQL) armazena o nome da tabela SQL real onde os comentários dessa instância são armazenados (ex: `bx_persons_cmts`).
*   `TriggerTable`, `TriggerFieldId`, `TriggerFieldComments` são essenciais para que o `CommentsRepo` saiba como atualizar os contadores de comentários no conteúdo pai.
*   Muitas outras colunas (`CharsPostMin`, `PerView`, `Html`, etc.) são configurações que o UNA PHP usaria para renderizar e controlar o comportamento do sistema de comentários. A API \"Deeper\" pode expor algumas dessas configurações para o cliente, se necessário, ou usá-las para validação no backend.
*   Campos como `ClassName` e `ClassFile` são específicos do UNA PHP e provavelmente não serão usados diretamente pela API \"Deeper\", mas são mantidos por fidelidade ao esquema original.