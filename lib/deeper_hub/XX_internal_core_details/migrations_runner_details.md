# Documentação Deeper: Executor de Migrações (`mix deeper.migrate`)

Este documento descreve o mecanismo proposto para executar migrações de esquema de banco de dados SQLite no projeto \"Deeper\". Isso geralmente envolve tarefas Mix customizadas como `mix deeper.migrate` e `mix deeper.rollback`.

## 1. Objetivos do Sistema de Migração

*   **Versionamento do Esquema:** Permitir que o esquema do banco de dados evolua de forma controlada e rastreável.
*   **Aplicar Alterações:** Executar scripts SQL (via módulos Elixir) para criar tabelas, adicionar colunas, criar índices, etc. (`up`).
*   **Reverter Alterações:** Executar scripts SQL para desfazer as alterações aplicadas (`down`).
*   **Repetibilidade:** Garantir que as migrações possam ser executadas de forma consistente em diferentes ambientes.
*   **Rastreamento:** Saber quais migrações já foram aplicadas a um determinado banco de dados.

## 2. Rastreamento de Migrações Aplicadas

*   Uma tabela especial no banco de dados será usada para rastrear quais migrações já foram executadas.
*   **Nome da Tabela Sugerido:** `deeper_schema_migrations` (para evitar conflito com a `schema_migrations` do Ecto, se o adapter for usado apenas para `DBConnection`).
*   **Estrutura da Tabela `deeper_schema_migrations`:**

```sql
    CREATE TABLE IF NOT EXISTS deeper_schema_migrations (
      version TEXT PRIMARY KEY, -- Identificador único da migração (ex: timestamp ou nome do módulo)
      module_name TEXT UNIQUE, -- Nome do módulo Elixir da migração (opcional, mas útil)
      applied_at INTEGER NOT NULL -- Unix Timestamp de quando foi aplicada
    );
```

```elixir
    defmodule Deeper.Core.Data.Migrations.YYYYMMDDHHMMSSCreateUsersTable do
      alias Deeper.Core.Data.Repo
      # ...
      def up, do: #... Repo.execute(create_sql)
      def down, do: #... Repo.execute(drop_sql)
    end
```

    *   `version`: Pode ser um timestamp (ex: `20231028120000`) prefixando o nome do arquivo/módulo da migração, ou o nome completo do módulo Elixir se for garantidamente único e sequencial na sua criação. Usar um timestamp como prefixo é uma prática comum para garantir a ordem.

## 3. Estrutura dos Módulos de Migração Elixir

*   Cada alteração no esquema é definida em um módulo Elixir separado, localizado em `lib/deeper/core/data/migrations/`.
*   **Convenção de Nomenclatura:** `YYYYMMDDHHMMSS_nome_descritivo_da_migracao.ex` (ex: `20231028120000_create_users_table.ex`). O timestamp garante a ordem.
*   **Interface do Módulo de Migração:** Cada módulo deve implementar:
    *   `up/0 :: :ok | {:error, any()}`: Contém a lógica (SQL via `Deeper.Core.Data.Repo.execute/2`) para aplicar a migração.
    *   `down/0 :: :ok | {:error, any()}`: Contém a lógica para reverter a migração.

    **Exemplo (já visto):**

## 4. Tarefas Mix Customizadas

Serão criadas tarefas Mix para gerenciar as migrações.

### `mix deeper.migrate`
*   **Lógica:**
    1.  **Descobrir Migrações:** Escaneia o diretório `lib/deeper/core/data/migrations/` para encontrar todos os arquivos de migração (`*.ex`). Ordena-os com base no prefixo de timestamp (ou nome do arquivo).
    2.  **Verificar Migrações Aplicadas:** Consulta a tabela `deeper_schema_migrations` para obter a lista de versões/módulos já aplicados.
    3.  **Determinar Migrações Pendentes:** Compara a lista de todas as migrações com as já aplicadas.
    4.  **Executar Migrações Pendentes:** Para cada migração pendente, na ordem correta:
        *   Invoca a função `up/0` do módulo de migração.
        *   Se `up/0` retornar `:ok`:
            *   Registra a versão/módulo da migração na tabela `deeper_schema_migrations` com o timestamp atual.
            *   Loga o sucesso.
        *   Se `up/0` retornar `{:error, reason}`:
            *   Para a execução.
            *   Loga o erro e a migração que falhou. Nenhuma migração subsequente é executada.
*   **Opções:**
    *   `mix deeper.migrate --step N`: Aplica as próximas `N` migrações pendentes.
    *   `mix deeper.migrate --to VERSION`: Aplica migrações até (inclusive) a `VERSION` especificada.

### `mix deeper.rollback`
*   **Lógica:**
    1.  **Obter Última Migração Aplicada:** Consulta `deeper_schema_migrations` para encontrar a migração mais recente aplicada (maior `applied_at` ou maior `version`).
    2.  **Executar `down/0`:** Invoca a função `down/0` do módulo da última migração aplicada.
    3.  Se `down/0` retornar `:ok`:
        *   Remove o registro da migração da tabela `deeper_schema_migrations`.
        *   Loga o sucesso.
    4.  Se `down/0` retornar `{:error, reason}`:
        *   Para a execução.
        *   Loga o erro. O registro na `deeper_schema_migrations` permanece (o estado do BD pode estar inconsistente).
*   **Opções:**
    *   `mix deeper.rollback --step N`: Reverte as últimas `N` migrações aplicadas.
    *   `mix deeper.rollback --to VERSION`: Reverte migrações até (inclusive) a `VERSION` especificada ser a última aplicada (ou seja, reverte as que vieram depois dela).

### `mix deeper.migrate.status`
*   **Lógica:**
    1.  Descobre todas as migrações.
    2.  Consulta `deeper_schema_migrations`.
    3.  Exibe uma lista de todas as migrações, indicando seu status (`up` ou `down`) e, se `up`, quando foi aplicada.

## 5. Implementação do Runner (Esboço)

A tarefa Mix envolveria:

*   Compilar os módulos de migração.
*   Usar `Path.wildcard/1` e `File.stream!/1` ou `Code.Identifier.string_to_quoted/2` para encontrar e carregar dinamicamente os módulos.
*   Interagir com `Deeper.Core.Data.Repo` para ler/escrever na `deeper_schema_migrations` e para executar as funções `up/0` e `down/0` (que por sua vez usam o Repo).

## Considerações:

*   **Atomicidade das Migrações:** Idealmente, cada função `up/0` e `down/0` que executa múltiplas declarações DDL deveria envolvê-las em uma transação, se o SQLite e o `DBConnection` adapter suportarem DDL transacional de forma confiável (o SQLite suporta, mas nem todas as operações DDL são transacionais da mesma forma em todos os BDs). Para SQLite, `CREATE TABLE`, `ALTER TABLE`, `DROP TABLE` dentro de uma transação geralmente funcionam.
*   **Nomes dos Módulos de Migração:** Usar o timestamp como prefixo no nome do *arquivo* é suficiente para a ordenação. O nome do *módulo* Elixir pode ser mais limpo, como `Deeper.Core.Data.Migrations.CreateUsersTable`. O runner precisaria mapear o nome do arquivo para o nome do módulo. Uma convenção seria o nome do arquivo `YYYYMMDDHHMMSS_create_users_table.ex` corresponder ao módulo `Deeper.Core.Data.Migrations.CreateUsersTable` (omitindo o timestamp do nome do módulo, mas usando-o para ordenação e como `version`).
*   **Geração de Arquivos de Migração:** Poderia haver uma tarefa Mix `mix deeper.gen.migration create_users_table` que cria o arquivo `.ex` de esqueleto com o timestamp atual e a estrutura do módulo.

Este sistema de migração, embora mais manual que o do Ecto, fornece controle total e é perfeitamente viável para gerenciar a evolução do esquema do banco de dados SQLite do \"Deeper\".