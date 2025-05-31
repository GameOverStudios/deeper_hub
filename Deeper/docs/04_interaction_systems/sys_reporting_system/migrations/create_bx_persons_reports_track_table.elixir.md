# Migração Elixir: Criar Tabela `bx_persons_reports_track` (Rastreamento de Denúncias para Pessoas)

Este módulo de migração Elixir cria a tabela `bx_persons_reports_track` no SQLite, para armazenar denúncias individuais feitas contra perfis de pessoas.

Esta é um exemplo de uma tabela `table_track` referenciada em `sys_objects_report`.

## Código da Migração (`lib/deeper/core/data/migrations/create_bx_persons_reports_track_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateBxPersonsReportsTrackTable do
  @moduledoc \"\"\"
  Migração para criar a tabela de rastreamento de denúncias bx_persons_reports_track.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_reports_track.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_reports_track...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_reports_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- FK para bx_persons_data.id (ou ID do comentário, etc.)
      author_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) do denunciante
      author_nip INTEGER, -- IP como inteiro (originalmente INT UNSIGNED)
      type TEXT NOT NULL, -- Tipo da denúncia (ex: 'spam', 'inappropriate')
      text TEXT NOT NULL DEFAULT '', -- Comentário/justificativa da denúncia
      date INTEGER NOT NULL, -- Unix Timestamp
      checked_by INTEGER NOT NULL DEFAULT 0, -- ID do admin que verificou (sys_profiles.id)
      status INTEGER NOT NULL DEFAULT 0 -- 0=pendente, 1=aceita, 2=rejeitada
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_reports_track_object_author ON bx_persons_reports_track(object_id, author_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_reports_track_status_date ON bx_persons_reports_track(status, date);
    -- O UNA não impõe UNIQUE(object_id, author_id) aqui, permitindo múltiplas denúncias do mesmo autor para o mesmo objeto,
    -- possivelmente com tipos ou textos diferentes ao longo do tempo. A lógica da aplicação decide como tratar isso.
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_reports_track criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_persons_reports_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_persons_reports_track.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_persons_reports_track...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS bx_persons_reports_track;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_reports_track removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_persons_reports_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   `object_id`: O ID do conteúdo denunciado.
*   `author_id`: O ID do perfil do denunciante.
*   `type`: Categoria da denúncia.
*   `text`: Justificativa opcional.
*   `checked_by`: ID do administrador que processou a denúncia.
*   `status`: Estado atual da denúncia.