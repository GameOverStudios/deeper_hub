# Migração Elixir: Criar Tabela `deeper_file_versions` (Opcional)

Este módulo de migração Elixir cria a tabela `deeper_file_versions` no SQLite. Esta tabela é opcional e serve para rastrear diferentes versões ou transformações (ex: thumbnails) de um arquivo original armazenado em `deeper_files`.

## Código da Migração (`lib/deeper/core/data/migrations/file_management/create_deeper_file_versions_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.FileManagement.CreateDeeperFileVersionsTable do
  @moduledoc \"Migração para criar a tabela deeper_file_versions.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_file_versions...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_file_versions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      original_file_id INTEGER NOT NULL,
      version_profile_name TEXT NOT NULL,
      storage_backend_name TEXT NOT NULL,
      stored_filename TEXT NOT NULL, -- Pode não ser UNIQUE globalmente, mas sim por original_file_id + version_profile_name
      stored_path TEXT,
      mime_type TEXT NOT NULL,
      size_bytes INTEGER NOT NULL,
      meta_data TEXT, -- JSON (ex: dimensões da versão)
      created_at INTEGER NOT NULL,
      UNIQUE (original_file_id, version_profile_name),
      FOREIGN KEY (original_file_id) REFERENCES deeper_files(id) ON DELETE CASCADE ON UPDATE CASCADE
      -- FK lógica para storage_backend_name -> deeper_storage_backends.storage_name
    );

    CREATE INDEX IF NOT EXISTS idx_dfv_original_file ON deeper_file_versions(original_file_id);
    CREATE INDEX IF NOT EXISTS idx_dfv_storage_filename ON deeper_file_versions(storage_backend_name, stored_path, stored_filename);
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_file_versions criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela deeper_file_versions: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela deeper_file_versions...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_file_versions;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela deeper_file_versions removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela deeper_file_versions: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```

```

---

Com estas migrações, temos a estrutura do banco de dados para o sistema de gerenciamento de arquivos.

O próximo passo lógico para esta seção (`06_file_management`) seria o **`data_access_module.md`**, detalhando o `Deeper.FileManagement.FileRepo` (para metadados) e o `Deeper.FileManagement.StorageManager` (para interagir com os backends de armazenamento). O `StorageManager` seria mais um Behaviour ou um conjunto de módulos (um por engine: Local, S3) do que um \"Repo\" tradicional.

Pronto para continuar com os módulos de acesso a dados para arquivos?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""console
"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Entendido. Vamos \"simular\" a saída do console para as migrações que acabamos de definir, assumindo que elas são executadas na ordem correta e com sucesso.

**Explicação da Saída Simulada do Console:**

*   **Comando de Migração:** O comando `mix deeper.migrate` é hipotético, representando a tarefa Mix que você usaria para executar as migrações. O nome real dependerá de como você estrutura suas tarefas Mix.
*   **Execução por Módulo:** Cada módulo de migração é executado individualmente.
*   **Logs:**
    *   A primeira linha de log para cada migração indica qual módulo está sendo executado e o nome da função (`up/0`).
    *   A segunda linha de log vem da sua chamada `Logger.info(\"Criando tabela ...\")` dentro da função `up`.
    *   A terceira linha de log confirma o sucesso da criação da tabela, também da sua chamada `Logger.info`.
    *   A quarta linha (ex: `[info] Migrated ... (0.012s)`) seria uma saída padrão do runner de migração, indicando que o módulo foi processado e o tempo que levou.
*   **Ordem:** As migrações são executadas na ordem definida pelo seu runner de migração (geralmente baseado em timestamps nos nomes dos arquivos de migração ou uma ordem explícita). Para este exemplo, simulei a ordem correta.
*   **Sucesso:** A mensagem final indica que todas as migrações foram aplicadas com sucesso.

Se houvesse um erro (ex: erro de sintaxe SQL, falha ao criar um índice UNIQUE devido a dados duplicados, ou uma FK não resolvida), o console mostraria a mensagem de erro do `Logger.error` e o runner de migração provavelmente pararia e indicaria a falha.

Exemplo de erro: