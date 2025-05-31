# Migração Elixir: Criar Tabela `bx_persons_views_track`

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_views_track` no banco de dados SQLite. Esta tabela rastreia as visualizações de perfis de pessoas.

## Código da Migração (`lib/deeper/core/data/migrations/create_bx_persons_views_track_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateBxPersonsViewsTrackTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_persons_views_track.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_views_track.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_views_track...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_views_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- ID do bx_persons_data.id que foi visualizado
      viewer_id INTEGER NOT NULL DEFAULT 0, -- ID do perfil (sys_profiles.id) do visualizador (0 se anônimo)
      viewer_nip INTEGER, -- IP do visualizador como inteiro (NETWORK_IP no UNA)
      date INTEGER NOT NULL -- Unix Timestamp da visualização
      -- Não há FK direta para object_id -> bx_persons_data.id ou viewer_id -> sys_profiles.id
      -- no schema original do UNA para esta tabela, mas poderiam ser adicionadas para integridade.
      -- Para simplificar e manter a fidelidade inicial, omitimos, mas é uma melhoria a considerar.
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_views_track_object_id_date ON bx_persons_views_track(object_id, date);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_views_track_viewer_id ON bx_persons_views_track(viewer_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_views_track criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_persons_views_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_persons_views_track.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_persons_views_track...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS bx_persons_views_track;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_views_track removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_persons_views_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   `object_id` refere-se ao `id` do perfil (`bx_persons_data`) visualizado.
*   `viewer_id` refere-se ao `id` do perfil (`sys_profiles`) do visualizador.
*   `viewer_nip` no UNA é o IP do usuário convertido para um inteiro. A forma de armazenar/anonimizar IPs deve ser considerada.