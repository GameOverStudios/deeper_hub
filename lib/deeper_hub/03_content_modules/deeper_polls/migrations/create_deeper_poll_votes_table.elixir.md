# Migração Elixir: Criar Tabela `deeper_poll_votes`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_poll_votes` no banco de dados SQLite. Esta tabela registra os votos individuais dos usuários nas opções das enquetes.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_poll_votes_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperPollVotesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_poll_votes.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_poll_votes.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_poll_votes...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_poll_votes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      poll_id INTEGER NOT NULL,
      option_id INTEGER NOT NULL,
      profile_id INTEGER NOT NULL,
      voted_at INTEGER NOT NULL,
      UNIQUE (poll_id, profile_id, option_id), -- Garante que um usuário não vote na mesma opção múltiplas vezes
      FOREIGN KEY (poll_id) REFERENCES deeper_polls(id) ON DELETE CASCADE,
      FOREIGN KEY (option_id) REFERENCES deeper_poll_options(id) ON DELETE CASCADE,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_dpv_poll_id_profile_id ON deeper_poll_votes(poll_id, profile_id);
    CREATE INDEX IF NOT EXISTS idx_dpv_option_id ON deeper_poll_votes(option_id);
    CREATE INDEX IF NOT EXISTS idx_dpv_profile_id ON deeper_poll_votes(profile_id);
    \"\"\"

    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_poll_votes criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_poll_votes: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_poll_votes.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_poll_votes...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_poll_votes;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_poll_votes removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_poll_votes: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Esta tabela depende da existência de `deeper_polls`, `deeper_poll_options`, e `sys_profiles`.
*   A constraint `UNIQUE (poll_id, profile_id, option_id)` é importante. Para enquetes de voto único (onde `deeper_polls.allow_multiple_choices = 0`), a lógica da aplicação precisará garantir que, ao inserir um novo voto para um `(poll_id, profile_id)`, qualquer voto existente para essa combinação (em uma `option_id` diferente) seja removido antes, ou a tentativa de inserir um segundo voto seja rejeitada se o usuário já votou naquela enquete. A constraint `UNIQUE` aqui apenas impede votos duplicados na *mesma opção*.
*   `ON DELETE CASCADE` para as chaves estrangeiras garante que os registros de votos sejam limpos se a enquete, a opção, ou o perfil do votante forem excluídos.