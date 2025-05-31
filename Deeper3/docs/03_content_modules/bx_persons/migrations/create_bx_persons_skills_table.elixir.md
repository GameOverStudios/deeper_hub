# Migração Elixir: Criar Tabela `bx_persons_skills`

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_skills` no banco de dados SQLite. Esta tabela armazena as habilidades (skills) associadas aos perfis de pessoas.

**Dependências:** `sys_profiles`

## Código da Migração (`lib/deeper/content/persons/migrations/create_bx_persons_skills_table.ex`)

```elixir
defmodule Deeper.Content.Persons.Migrations.CreateBxPersonsSkillsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_persons_skills.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_skills.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_skills...\", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_skills (
      skill_id INTEGER PRIMARY KEY AUTOINCREMENT,
      skill_name TEXT, -- No UNA é VARCHAR(500)
      content_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil que possui a habilidade)
      FOREIGN KEY (content_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_skills_content_id ON bx_persons_skills(content_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_skills_skill_name ON bx_persons_skills(skill_name);
    -- Para evitar duplicatas de skill_name por content_id:
    CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_persons_skills_content_skill ON bx_persons_skills(content_id, skill_name);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_skills criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_persons_skills: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_persons_skills.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_persons_skills...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS bx_persons_skills;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_skills removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_persons_skills: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `skill_id`, `content_id`: `INT(11)` (MySQL) -> `INTEGER` (SQLite). `skill_id` é `PRIMARY KEY AUTOINCREMENT`.
*   `skill_name`: `VARCHAR(500)` (MySQL) -> `TEXT` (SQLite).
*   **Índice Único:** Adicionado `uidx_bx_persons_skills_content_skill` para garantir que uma mesma habilidade não seja listada múltiplas vezes para o mesmo perfil.
*   **Chave Estrangeira:** Definida para `content_id` referenciando `sys_profiles.id`.