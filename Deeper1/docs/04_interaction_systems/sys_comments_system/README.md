# Documentação Deeper: Sistema de Comentários Genérico

Este documento descreve a API \"Deeper\" para o sistema de comentários genérico, permitindo que os usuários comentem em diferentes tipos de conteúdo (perfis, posts, fotos, etc.) na plataforma.

## Sistema de Comentários no UNA:

O UNA possui um sistema de comentários flexível, geralmente configurado através de:

*   **`sys_objects_cmts`**: Esta tabela define \"objetos de comentário\" para diferentes módulos ou tipos de conteúdo. Cada entrada especifica:
    *   `Name`: Um nome único para o sistema de comentários (ex: `bx_persons_profile`, `bx_posts_entity`).
    *   `Table`: O nome da tabela SQL onde os comentários para este objeto são armazenados (ex: `bx_persons_cmts`, `bx_posts_cmts`).
    *   `CharsPostMin`, `CharsPostMax`, `PerView`, `NumberOfLevels`, etc.: Configurações do sistema de comentários.
    *   `TriggerTable`, `TriggerFieldId`, `TriggerFieldComments`: Para atualizar contadores de comentários no conteúdo pai.
*   **Tabelas de Comentários:** Podem ser tabelas específicas do módulo (ex: `bx_persons_cmts`) ou uma tabela mais genérica se a plataforma for customizada. Estas tabelas geralmente contêm:
    *   `cmt_id`, `cmt_parent_id`, `cmt_object_id` (ID do conteúdo sendo comentado), `cmt_author_id`, `cmt_text`, `cmt_time`, etc.
*   **`sys_cmts_ids`**: Uma tabela que pode ser usada para rastrear metadados ou status administrativos de comentários individuais de diferentes sistemas de forma centralizada.

## Estratégia da API \"Deeper\" para Comentários:

A API \"Deeper\" fornecerá endpoints genéricos que podem ser usados para qualquer \"objeto de comentário\" configurado no UNA. A rota da API incluirá um identificador para o `comments_object_name` (que corresponde a `sys_objects_cmts.Name`).

### Módulo de Acesso a Dados (`Deeper.Interactions.CommentsRepo`):

Este repositório genérico precisará ser capaz de operar em diferentes tabelas de comentários.

**Desafios e Abordagem para o `CommentsRepo` Genérico:**

1.  **Nomes de Tabelas Dinâmicos:** A função no `CommentsRepo` precisará saber em qual tabela SQL executar a query (ex: `bx_persons_cmts` ou `bx_posts_cmts`).
    *   **Solução:** O `CommentsRepo` pode ter uma função `get_table_name(comments_object_name :: String.t())` que consulta `sys_objects_cmts` para obter o `Table` correto. As queries SQL seriam então construídas dinamicamente ou passariam o nome da tabela como parâmetro.
        *   `Repo.query(\"SELECT * FROM #{table_name} WHERE ...\", params)` (Cuidado com SQL injection se `table_name` não for estritamente controlado/validado). Uma abordagem mais segura é ter um `case` ou um mapa de dispatch para funções SQL específicas por tabela se o número de tabelas de comentários for limitado.

2.  **Campos Comuns:** Assumiremos que todas as tabelas de comentários seguem uma estrutura de colunas comum (pelo menos para os campos essenciais como `cmt_id`, `cmt_object_id`, `cmt_author_id`, `cmt_text`, `cmt_time`, `cmt_parent_id`).

**Funções Principais e SQLs Esperados (Parametrizados por `table_name`):**

*   **`list_comments(comments_object_name, object_id, opts)`**
    *   Busca o `table_name` de `sys_objects_cmts` usando `comments_object_name`.
    *   SQL: `SELECT c.*, author_profile.fullname AS author_fullname, author_profile.picture AS author_avatar_id FROM #{table_name} c LEFT JOIN sys_profiles author_sp ON c.cmt_author_id = author_sp.id LEFT JOIN bx_persons_data author_profile ON author_sp.content_id = author_profile.id AND author_sp.type = 'bx_persons' WHERE c.cmt_object_id = ? AND c.cmt_parent_id = ? ORDER BY c.cmt_time ? LIMIT ? OFFSET ?;`
        *   `cmt_parent_id` é um filtro em `opts`.
        *   O JOIN para obter dados do autor precisa ser flexível se autores puderem ser de tipos diferentes de 'bx_persons'.
    *   Lógica para construir árvore de comentários/respostas.

*   **`create_comment(comments_object_name, params)`**
    *   `params` inclui `cmt_object_id`, `cmt_author_id`, `cmt_text`, `cmt_parent_id`.
    *   SQL: `INSERT INTO #{table_name} (cmt_object_id, cmt_author_id, cmt_text, ...) VALUES (?, ?, ?, ...) RETURNING *;`
    *   **Lógica Adicional:**
        1.  Buscar `TriggerTable`, `TriggerFieldId`, `TriggerFieldComments` de `sys_objects_cmts`.
        2.  Atualizar o contador de comentários na `TriggerTable`: `UPDATE #{trigger_table} SET #{trigger_field_comments} = #{trigger_field_comments} + 1 WHERE #{trigger_field_id} = ?;` (usando `params.cmt_object_id`).
        3.  Se `cmt_parent_id` não for 0, atualizar o contador `cmt_replies` no comentário pai.

*   **`get_comment_by_id(comments_object_name, comment_id)`**
*   **`update_comment(comments_object_name, comment_id, text)`** (Verificar permissão: autor ou admin)
*   **`delete_comment(comments_object_name, comment_id)`** (Verificar permissão: autor ou admin)
    *   **Lógica Adicional:** Decrementar contadores.

### Endpoints da API (`/api/v1/comments/{comments_object_name}`):

O `{comments_object_name}` na rota corresponde a `sys_objects_cmts.Name` (ex: `bx_persons_profile`, `bx_posts_entity`).

*   **Listar Comentários para um Objeto:**
    *   **Endpoint:** `GET /api/v1/comments/{comments_object_name}/object/{object_id}`
    *   **Path Parameters:**
        *   `comments_object_name`: Ex: `bx_persons_profile`.
        *   `object_id`: O ID do conteúdo sendo comentado (ex: ID do perfil da pessoa, ID do post).
    *   **Query Parameters:** `page`, `per_page`, `sort_by` (ex: `time_desc`), `parent_id` (para buscar respostas de um comentário específico).
    *   **Autenticação:** Opcional (comentários podem ser públicos).
    *   **Resposta de Sucesso (200 OK):**

```json
        {
          \"data\": [
            {
              \"comment_id\": 123,
              \"parent_id\": 0,
              \"text\": \"Este é um ótimo perfil!\",
              \"author\": {
                \"profile_id\": 789,
                \"fullname\": \"Jane Doe\",
                \"avatar_url\": \"/path/to/jane_avatar.jpg\"
              },
              \"timestamp\": 1678886400,
              \"replies_count\": 2,
              \"can_edit\": false, // Se o usuário atual pode editar
              \"can_delete\": false // Se o usuário atual pode deletar
            }
            // ... outros comentários ...
          ],
          \"pagination\": { /* ... */ }
        }
```

```json
        {
          \"text\": \"Adorei este post!\",
          \"parent_id\": 0 // Ou o ID do comentário ao qual está respondendo
        }
```

```sql
    CREATE TABLE IF NOT EXISTS sys_objects_cmts (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      ObjectName TEXT NOT NULL UNIQUE, -- No schema original é só `Name`
      Module TEXT NOT NULL,
      \"Table\" TEXT NOT NULL, -- Nome da tabela de comentários (ex: bx_persons_cmts)
      CharsPostMin INTEGER NOT NULL DEFAULT 1,
      CharsPostMax INTEGER NOT NULL DEFAULT 1000,
      CharsDisplayMax INTEGER NOT NULL DEFAULT 200,
      Html INTEGER NOT NULL DEFAULT 0, -- 0 ou 1 (se HTML é permitido)
      PerView INTEGER NOT NULL DEFAULT 10, -- Comentários por página
      PerViewReplies INTEGER NOT NULL DEFAULT 3,
      BrowseType TEXT, -- 'list', 'tree'
      IsBrowseSwitch INTEGER NOT NULL DEFAULT 1,
      PostFormPosition TEXT, -- 'bottom', 'top'
      NumberOfLevels INTEGER NOT NULL DEFAULT 3, -- Profundidade de aninhamento
      IsDisplaySwitch INTEGER NOT NULL DEFAULT 1,
      IsRatable INTEGER NOT NULL DEFAULT 1, -- Se comentários podem ser avaliados
      ViewingThreshold INTEGER NOT NULL DEFAULT -3,
      IsOn INTEGER NOT NULL DEFAULT 1, -- Se o sistema de comentários está ativo
      RootStylePrefix TEXT DEFAULT 'cmt',
      BaseUrl TEXT, -- URL base para links de comentários no UNA PHP
      ObjectVote TEXT, -- Nome do sys_objects_vote para os comentários
      ObjectReaction TEXT,
      ObjectScore TEXT,
      ObjectReport TEXT,
      TriggerTable TEXT, -- Tabela onde o contador de comentários é atualizado
      TriggerFieldId TEXT, -- Coluna ID na TriggerTable
      TriggerFieldAuthor TEXT, -- Coluna do autor na TriggerTable
      TriggerFieldTitle TEXT, -- Coluna do título na TriggerTable
      TriggerFieldComments TEXT, -- Coluna do contador de comentários na TriggerTable
      ClassName TEXT, -- Classe PHP no UNA
      ClassFile TEXT -- Arquivo da classe PHP no UNA
    );
```

*   **Adicionar um Novo Comentário:**
    *   **Endpoint:** `POST /api/v1/comments/{comments_object_name}/object/{object_id}`
    *   **Autenticação:** Requer JWT.
    *   **Corpo da Requisição (JSON):**

    *   **Resposta de Sucesso (201 Created):** Retorna o comentário recém-criado.
    *   **Respostas de Erro:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden` (ex: se o usuário não tem permissão para comentar neste objeto).

*   **Atualizar um Comentário:**
    *   **Endpoint:** `PUT /api/v1/comments/{comments_object_name}/comment/{comment_id}`
        *   Alternativa: `PUT /api/v1/comments/{comment_id}` (se `comment_id` for globalmente único e pudermos inferir `comments_object_name` ou a tabela a partir dele, ou se o `CommentsRepo` puder buscar em todas as tabelas de comentários, o que é menos ideal). A primeira opção é mais explícita.
    *   **Autenticação:** Requer JWT.
    *   **Autorização:** Usuário deve ser o autor do comentário ou ter permissões de moderação.
    *   **Corpo da Requisição (JSON):** `{\"text\": \"Texto atualizado do comentário.\"}`
    *   **Resposta de Sucesso (200 OK):** Retorna o comentário atualizado.

*   **Deletar um Comentário:**
    *   **Endpoint:** `DELETE /api/v1/comments/{comments_object_name}/comment/{comment_id}`
    *   **Autenticação:** Requer JWT.
    *   **Autorização:** Usuário deve ser o autor ou moderador.
    *   **Resposta de Sucesso (204 No Content).**

## Tabelas de Comentários (Esquema SQLite):

*   **`sys_objects_cmts` (Configuração - apenas leitura pela API \"Deeper\"):**

*   **Exemplo de Tabela de Comentários Específica (`bx_persons_cmts`):**
    *   Já definida em `docs/03_content_modules/bx_persons/database_schema.md`.
    *   Se outras tabelas de comentários (ex: `bx_posts_cmts`) forem necessárias, elas seguirão uma estrutura similar.

## Considerações:

*   **ACL para Comentar:** A permissão para comentar em um objeto específico (ex: perfil, post) é geralmente controlada pelo sistema de ACL do módulo pai (ex: `bx_persons` pode ter uma ação \"pode comentar em perfis\"). A API `POST /comments/...` precisará verificar essa permissão.
*   **Hierarquia/Aninhamento:** A API de listagem de comentários precisa suportar a busca de respostas para um `parent_id` e o cliente precisará de lógica para renderizar a árvore de comentários.
*   **Notificações:** A criação de um novo comentário ou resposta no UNA geralmente dispara notificações. A API \"Deeper\" precisará replicar essa lógica (possivelmente publicando eventos para um sistema de notificações).
*   **Moderação:** A API precisará de endpoints (provavelmente na seção de Admin) para moderadores gerenciarem comentários (editar, deletar qualquer um, aprovar).

Este sistema de comentários genérico, quando implementado, pode servir a muitos módulos de conteúdo diferentes com uma base de código unificada na API \"Deeper\".