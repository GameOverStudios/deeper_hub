# Documentação Deeper: Sistema de Denúncias Genérico

Esta seção detalha a API RESTful \"Deeper\" para interagir com o sistema de denúncias genérico do UNA. Este sistema permite que usuários denunciem diferentes tipos de conteúdo (perfis, posts, comentários, etc.) por violações, spam, ou outros motivos.

## Tabelas Relevantes do UNA:

*   **`sys_objects_report`**: Tabela de configuração principal. Cada entrada define um \"objeto de denúncia\" para um tipo de conteúdo. Especifica:
    *   `name`: Nome único do objeto de denúncia (ex: `bx_persons_reports`, `bx_posts_reports`). Usado na API.
    *   `module`: Módulo associado.
    *   `table_main`: Nome da tabela SQL que armazena o sumário das denúncias para um item (geralmente apenas uma contagem). Ex: `bx_persons_reports`.
    *   `table_track`: Nome da tabela SQL que armazena cada denúncia individual. Ex: `bx_persons_reports_track`.
    *   `pruning`: Período para limpar denúncias antigas.
    *   `is_on`: Se este sistema de denúncias está ativo.
    *   `object_comment`: (Opcional) Se as denúncias podem ter comentários (geralmente para a equipe de moderação).
    *   `trigger_table`, `trigger_field_id`, `trigger_field_count`: Configurações para atualizar o contador de denúncias na tabela de conteúdo principal.
*   **Tabela de Sumário de Denúncias (especificada em `sys_objects_report.table_main`)**:
    *   Geralmente contém colunas como `object_id` (ID do item denunciado) e `count` (número total de denúncias).
*   **Tabela de Rastreamento de Denúncias (especificada em `sys_objects_report.table_track`)**:
    *   Geralmente contém colunas como `object_id`, `author_id` (quem denunciou), `author_nip` (IP), `type` (tipo da denúncia), `text` (detalhes), `date`, `checked_by` (admin), `status` (da denúncia).

## Responsabilidades da API \"Deeper\":

*   Permitir que usuários submetam denúncias para itens de conteúdo.
*   (Para Admin API) Listar denúncias pendentes, marcar denúncias como verificadas, etc. O foco inicial da API pública será na submissão.

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite da tabela `sys_objects_report` e exemplos de tabelas `table_main` (sumário) e `table_track` (rastreamento).

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar essas tabelas.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.InteractionSystems.ReportingRepo` e suas funções para registrar denúncias e (para admin) gerenciá-las, usando dinamicamente os nomes das tabelas configuradas.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful (ex: `POST /reports/{object_report_name}/item/{item_id}`).

## Fluxo Típico de Submissão de Denúncia:

1.  O cliente exibe um item de conteúdo (ex: post com `id=789`).
2.  O cliente sabe que o objeto de denúncia para posts é, por exemplo, `bx_posts_main_reports`.
3.  O usuário clica em \"Denunciar\" e preenche um formulário com o tipo e texto da denúncia.
4.  O cliente envia `POST /api/v1/reports/object/bx_posts_main_reports/item/789` com os detalhes da denúncia.
5.  A API \"Deeper\" usa o `ReportingRepo` para:
    a.  Buscar a configuração de `bx_posts_main_reports` em `sys_objects_report`.
    b.  Verificar se o usuário já denunciou este item recentemente (para evitar spam de denúncias).
    c.  Inserir a denúncia na `table_track` apropriada.
    d.  Atualizar o sumário na `table_main`.
    e.  Atualizar o contador de denúncias na `TriggerTable` (ex: `bx_posts_data.reports_count`).
6.  A API retorna uma confirmação.