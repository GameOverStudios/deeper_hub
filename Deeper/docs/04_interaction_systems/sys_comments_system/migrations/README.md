# Documentação Deeper: Migrações para Sistema de Comentários

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao Sistema de Comentários Genérico.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_cmts` (`create_sys_objects_cmts_table.elixir.md`)**](./create_sys_objects_cmts_table.elixir.md):
    *   Responsável por criar a tabela `sys_objects_cmts`. Esta tabela é crucial, pois define as configurações para cada \"instância\" de sistema de comentários usada por diferentes módulos ou tipos de conteúdo (ex: comentários em perfis de pessoas, comentários em posts). A API \"Deeper\" usará esta tabela para saber qual tabela de comentários real consultar e como atualizar contadores.

2.  **Migrações para Tabelas de Comentários Específicas (Ex: `bx_persons_cmts`):**
    *   Estas migrações são definidas dentro dos respectivos módulos de conteúdo. Por exemplo, a migração para `bx_persons_cmts` está em `docs/03_content_modules/bx_persons/migrations/create_bx_persons_cmts_table.elixir.md`.
    *   O `CommentsRepo` genérico precisará ler de `sys_objects_cmts` para determinar qual dessas tabelas específicas usar.

3.  **(Opcional) Criar Tabela `sys_cmts_ids` (`create_sys_cmts_ids_table.elixir.md`)**:
    *   Se o sistema UNA utiliza `sys_cmts_ids` para rastreamento centralizado de metadados de comentários, sua migração seria definida aqui. Esta tabela no UNA original tem campos como `system_id` (FK para `sys_objects_cmts.ID`), `cmt_id` (ID do comentário na tabela específica), `author_id`, `rate`, `votes`, `reports`, `status_admin`.
    *   Para a API \"Deeper\" inicial, podemos focar em interagir diretamente com as tabelas de comentários específicas (`bx_persons_cmts`, etc.) e adiar a complexidade de `sys_cmts_ids` a menos que seja essencial para funcionalidades básicas.

## Ordem e Dependências:

*   `sys_objects_cmts` deve existir para que o `CommentsRepo` possa funcionar dinamicamente.
*   As tabelas de comentários específicas (ex: `bx_persons_cmts`) devem existir para armazenar os comentários.