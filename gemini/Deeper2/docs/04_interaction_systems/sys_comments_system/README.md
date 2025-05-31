# Documentação Deeper: Sistema de Comentários Genérico

Esta seção detalha a API RESTful \"Deeper\" para interagir com o sistema de comentários genérico do UNA. Este sistema permite que usuários adicionem comentários a vários tipos de conteúdo (perfis, posts, fotos, etc.) que foram configurados para suportar comentários.

## Tabelas Relevantes do UNA:

*   **`sys_objects_cmts`**: Tabela de configuração principal. Cada entrada aqui define um \"objeto de comentários\" para um tipo de conteúdo específico. Ela especifica:
    *   `Name`: Nome único do objeto de comentários (ex: `bx_persons_profile_cmts`, `bx_posts_item_cmts`). Este nome será usado na API.
    *   `Table`: O nome da tabela SQL que armazena os comentários para este objeto (ex: `bx_persons_cmts`, `bx_posts_cmts`).
    *   `CharsPostMin`, `CharsPostMax`, `CharsDisplayMax`, `Html`, `PerView`, `PerViewReplies`, `BrowseType`, `IsBrowseSwitch`, `PostFormPosition`, `NumberOfLevels`, `IsDisplaySwitch`, `IsRatable`, `ViewingThreshold`, `IsOn`.
    *   `ObjectVote`, `ObjectReaction`, `ObjectScore`, `ObjectReport`: Nomes de objetos de interação para votos, reações, etc., aplicados aos próprios comentários.
    *   `TriggerTable`, `TriggerFieldId`, `TriggerFieldAuthor`, `TriggerFieldTitle`, `TriggerFieldComments`: Configurações para atualizar a tabela de conteúdo principal quando um comentário é adicionado/removido (ex: incrementar `bx_persons_data.comments`).
*   **Tabela de Conteúdo de Comentários (especificada em `sys_objects_cmts.Table`)**:
    *   Contém os dados reais de cada comentário (ID, texto, autor, data, parent_id para respostas, etc.). A estrutura é geralmente padronizada (ex: colunas `cmt_id`, `cmt_object_id`, `cmt_author_id`, `cmt_text`, `cmt_time`, `cmt_parent_id`).
*   **`sys_cmts_ids`**: Tabela que armazena metadados adicionais ou status para cada comentário individual em todos os sistemas (ex: `status_admin`, contadores de votos/reports do próprio comentário).
*   **Tabelas de interações para comentários** (ex: `sys_cmts_votes`, `sys_cmts_reports_track`): Se os comentários em si puderem ser votados ou denunciados.

## Responsabilidades da API \"Deeper\":

*   Listar comentários para um item de conteúdo específico.
*   Permitir que usuários postem novos comentários (e respostas).
*   Permitir que usuários editem/deletem seus próprios comentários (com permissão).
*   Lidar com interações nos próprios comentários (votos, denúncias), se aplicável.

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas `sys_objects_cmts`, `sys_cmts_ids`, e um exemplo de tabela de conteúdo de comentários (ex: `example_module_cmts`).

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar essas tabelas.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.InteractionSystems.CommentsRepo` e suas funções para ler e escrever comentários, usando dinamicamente o nome da tabela de comentários configurada em `sys_objects_cmts`.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful (ex: `GET /comments/{object_interaction_name}/item/{item_id}`).

## Fluxo Típico:

1.  O cliente precisa exibir comentários para um item de conteúdo (ex: perfil com `id=456`).
2.  O cliente sabe (ou descobre via API de página/conteúdo) que o objeto de comentários para perfis é, por exemplo, `bx_persons_profile_cmts`.
3.  O cliente chama `GET /api/v1/comments/object/bx_persons_profile_cmts/item/456`.
4.  A API \"Deeper\":
    a.  Usa o `CommentsRepo` para buscar a configuração de `bx_persons_profile_cmts` em `sys_objects_cmts`.
    b.  Descobre que a tabela de comentários é, por exemplo, `custom_person_comments_table`.
    c.  O `CommentsRepo` consulta `custom_person_comments_table` (e `sys_cmts_ids`) para buscar os comentários do `item_id=456`, aplicando paginação, ordenação e filtrando por `cmt_parent_id` para obter comentários de nível superior.
    d.  Também busca detalhes dos autores dos comentários (JOIN com `sys_profiles` e `bx_persons_data`).
5.  A API retorna a lista de comentários.
6.  Para postar um comentário, o cliente envia `POST /api/v1/comments/object/bx_persons_profile_cmts/item/456` com o texto do comentário. O `CommentsRepo` insere na tabela correta e atualiza o contador na tabela de conteúdo principal (`bx_persons_data.comments`) conforme `TriggerFieldComments`.