# Documentação Deeper: Extensões aos Módulos de Acesso a Dados de Arquivos para Administração e Suporte

Este documento descreve funções adicionais ou específicas para `Deeper.Files.StorageRepo` e `Deeper.Files.FilesRepo` para lidar com tabelas de suporte como `sys_storage_ghosts`, `sys_storage_tokens`, e `sys_storage_user_quotas`.

## Extensões ao `Deeper.Files.FilesRepo` (ou um novo `Deeper.Files.GhostsRepo`):

*   **`create_ghost_file_record(params :: map()) :: {:ok, ghost_record :: map()} | {:error, any()}`**
    *   `params`: `file_id` (ID do arquivo na tabela de metadados), `uploader_profile_id`, `storage_object_name`, `content_id` (pode ser 0), `order`.
    *   SQL: `INSERT INTO sys_storage_ghosts (id, profile_id, object, content_id, created, \"order\") VALUES (?, ?, ?, ?, ?, ?) RETURNING *;`
    *   `created = System.os_time(:second)`.

*   **`delete_ghost_file_record(ghost_iid :: integer()) :: :ok | {:error, :not_found | any()}`**
    *   SQL: `DELETE FROM sys_storage_ghosts WHERE iid = ?;`

*   **`delete_ghost_file_records_by_file_id(file_id :: integer(), storage_object_name :: String.t()) :: :ok | {:error, any()}`**
    *   Usado quando um arquivo fantasma é \"confirmado\" e associado a um conteúdo.
    *   SQL: `DELETE FROM sys_storage_ghosts WHERE id = ? AND object = ?;`

*   **`list_expired_ghosts(storage_object_name :: String.t() | nil, older_than_ts :: integer()) :: {:ok, list(map())} | {:error, any()}`**
    *   Para um job de limpeza.
    *   SQL: `SELECT g.iid AS ghost_internal_id, g.id AS file_real_id, g.object, f.remote_id, f.path FROM sys_storage_ghosts g JOIN #{table_files_for_object} f ON g.id = f.id WHERE g.created < ? AND (? IS NULL OR g.object = ?);`
        *   `#{table_files_for_object}` precisa ser determinado a partir de `storage_object_name` ou iterar/unir sobre todos os storage objects se `storage_object_name` for `nil`.

## Extensões ao `Deeper.Files.StorageRepo` (ou um novo `Deeper.Files.TokensRepo`):

*   **`create_file_access_token(file_id :: integer(), storage_object_name :: String.t(), token_hash :: String.t()) :: {:ok, token_record :: map()} | {:error, any()}`**
    *   SQL: `INSERT INTO sys_storage_tokens (id, object, hash, created) VALUES (?, ?, ?, ?) RETURNING *;`
    *   `created = System.os_time(:second)`.

*   **`get_file_by_access_token(token_hash :: String.t()) :: {:ok, %{file_id: integer(), storage_object_name: String.t(), token_created_ts: integer()}} | {:error, :not_found | any()}`**
    *   SQL: `SELECT id, object, created FROM sys_storage_tokens WHERE hash = ? LIMIT 1;`

*   **`delete_file_access_token(token_hash :: String.t()) :: :ok | {:error, any()}`**
    *   SQL: `DELETE FROM sys_storage_tokens WHERE hash = ?;`

*   **`delete_expired_file_access_tokens(storage_configs :: list(map())) :: {:ok, deleted_count :: integer()} | {:error, any()}`**
    *   Para um job de limpeza. Itera sobre `storage_configs` (de `sys_objects_storage`).
    *   Para cada config: `expiry_threshold_ts = System.os_time(:second) - config[\"token_life\"]`.
    *   SQL: `DELETE FROM sys_storage_tokens WHERE object = ? AND created < ?;`

## Extensões ao `Deeper.SystemCore.AccountsRepo` ou um novo `Deeper.Files.UserQuotasRepo`:

*   **`get_user_quota_usage(profile_id :: integer()) :: {:ok, quota_usage :: map()} | {:error, :not_found | any()}`**
    *   SQL: `SELECT profile_id, current_size, current_number, ts FROM sys_storage_user_quotas WHERE profile_id = ? LIMIT 1;`
    *   Se não encontrado, pode retornar `%{current_size: 0, current_number: 0}`.

*   **`update_user_quota_usage(profile_id :: integer(), size_delta :: integer(), number_delta :: integer()) :: {:ok, new_quota_usage :: map()} | {:error, any()}`**
    *   SQL (SQLite):

# Deeper API Backend

## Visão Geral do Projeto

**Deeper** é um backend robusto e moderno construído em **Elixir** e **Phoenix Framework**, projetado para servir como uma camada de API RESTful para o ecossistema de dados do **UNA CMS/Framework**. O objetivo principal é desacoplar o frontend das implementações PHP originais do UNA, permitindo o desenvolvimento de interfaces de cliente modernas (web SPAs, aplicações mobile, etc.) enquanto se aproveita a rica estrutura de dados e lógica de negócios definida pelo banco de dados do UNA.

Inicialmente, o projeto utilizará **SQLite** como banco de dados, com o esquema do UNA portado, para facilitar o desenvolvimento e a portabilidade. As interações com o banco de dados serão feitas primariamente através de SQL direto, gerenciado por uma camada de acesso a dados customizada (`Deeper.Core.Data.Repo`) construída sobre `DBConnection`.

## Objetivos Chave:

1.  **API RESTful Abrangente:** Expor todas as funcionalidades chave do UNA (perfis, conteúdo, interações, configurações, etc.) através de endpoints RESTful bem definidos e documentados.
2.  **Desacoplamento:** Separar a lógica de backend da apresentação, permitindo que múltiplos tipos de clientes consumam a API.
3.  **Performance e Escalabilidade:** Alavancar a concorrência e a resiliência da plataforma Elixir/OTP para construir um backend performático e escalável.
4.  **Modernização:** Oferecer uma alternativa moderna à arquitetura PHP monolítica do UNA para o desenvolvimento de novas experiências de usuário.
5.  **Manutenção do Esquema de Dados UNA:** Preservar a estrutura de dados existente do UNA (portada para SQLite inicialmente) para garantir compatibilidade e aproveitar a modelagem de dados já estabelecida.
6.  **Desenvolvimento Orientado a Documentação:** Utilizar uma abordagem \"documentação primeiro\" para garantir clareza, consistência e facilitar a colaboração e o desenvolvimento (seja por humanos ou IA).

## Tecnologias Principais:

*   **Linguagem:** Elixir
*   **Framework Web/API:** Phoenix Framework
*   **Acesso a Banco de Dados:** `DBConnection` e uma camada de repositório customizada (`Deeper.Core.Data.Repo`) com SQL direto.
*   **Banco de Dados Inicial:** SQLite (com esquema portado do UNA MySQL).
*   **Formato de Dados da API:** JSON.
*   **Autenticação:** JSON Web Tokens (JWT).

## Estrutura do Projeto (Elixir/Phoenix - Conceitual):

```sql
        INSERT INTO sys_storage_user_quotas (profile_id, current_size, current_number, ts)
        VALUES (?, MAX(0, ?), MAX(0, ?), ?)
        ON CONFLICT(profile_id) DO UPDATE SET
          current_size = MAX(0, current_size + ?),
          current_number = MAX(0, current_number + ?),
          ts = ?
        RETURNING profile_id, current_size, current_number, ts;
```

        (Valores para `?`: `profile_id`, `size_delta`, `number_delta`, `current_ts`, `size_delta`, `number_delta`, `current_ts`).
        *   `MAX(0, ...)` para evitar contagens/tamanhos negativos.

## Lógica de Serviço de Suporte ao Armazenamento (Exemplo `Deeper.Files.StorageMaintenanceService`):

*   **`cleanup_expired_ghosts()`**:
    1.  Busca todas as configs de `sys_objects_storage`.
    2.  Para cada config, determina `older_than_ts` (ex: `System.os_time(:second) - (24 * 3600)`).
    3.  Chama `FilesRepo.list_expired_ghosts(nil, older_than_ts)`.
    4.  Para cada ghost retornado:
        *   Deleta o arquivo físico: `PhysicalStorage.delete(ghost[\"object\"], config_params, ghost[\"path\"], ghost[\"remote_id\"])`.
        *   Se a deleção física for bem-sucedida:
            *   `FilesRepo.delete_file_metadata(ghost[\"object\"], ghost[\"file_real_id\"])` (isso também ajustaria `current_size`/`number` no `StorageRepo`).
            *   `FilesRepo.delete_ghost_file_record(ghost[\"ghost_internal_id\"])`.
*   **`cleanup_expired_tokens()`**:
    1.  Busca todas as configs de `sys_objects_storage`.
    2.  Chama `StorageRepo.delete_expired_file_access_tokens(storage_configs)`.

Estes repositórios e serviços de suporte ajudam a manter a integridade e eficiência do sistema de armazenamento.

deeper/
├── apps/
│   └── deeper_web/ # Aplicação Phoenix principal para a API
│       ├── lib/
│       │   └── deeper_web/
│       │       ├── controllers/  # Controladores da API
│       │       ├── views/        # Views para renderizar JSON
│       │       ├── router.ex     # Definição das rotas da API
│       │       └── endpoint.ex
│       └── priv/
│           └── static/         # Arquivos estáticos, se houver
│   └── deeper_core/ # Aplicação OTP para a lógica de negócios e acesso a dados
│       ├── lib/
│       │   └── deeper_core/
│       │       ├── data/         # Módulo Repo, Migrações
│       │       ├── system_core/  # Repos para Accounts, ACL, Options, etc.
│       │       ├── content/      # Repos para módulos de conteúdo (Persons, Posts)
│       │       ├── interactions/ # Repos para Comments, Votes, Favorites, etc.
│       │       ├── forms/        # Repos para Forms Engine
│       │       ├── grids/        # Repos para Grids Engine
│       │       ├── files/        # Repos para File Management
│       │       └── system_tools/ # Repos para CronJobs, etc.
│       └── priv/
│           └── repo/
│               └── migrations/ # Onde os módulos .ex das migrações residirão
├── config/         # Configurações da aplicação
├── deps/           # Dependências
├── docs/           # ESTA DOCUMENTAÇÃO DETALHADA (organizada por funcionalidade)
│   ├── 00_core_concepts/
│   ├── 01_system_core/
│   │   └── ...
│   ├── ...
│   └── 07_studio_admin_api/
│       └── ...
├── lib/            # Código da aplicação raiz (se não for umbrella)
├── priv/
├── test/           # Testes unitários e de integração
├── mix.exs
└── README.md       # Este arquivo