# Documentação Deeper: Módulo de Conteúdo - Grupos (`deeper_groups`)

Este documento descreve a API \"Deeper\" para o módulo de gerenciamento de Grupos ou Comunidades. Este módulo permite aos usuários criar, descobrir, juntar-se e interagir dentro de grupos temáticos.

No sistema UNA original, isso corresponderia a um módulo como `bx_groups`.

## Responsabilidades Principais da API:

*   Permitir a criação de novos grupos.
*   Listar grupos disponíveis com filtros (ex: por categoria, tipo de privacidade, tags).
*   Exibir detalhes de um grupo específico, incluindo sua lista de membros, discussões, etc.
*   Permitir que usuários solicitem adesão ou se juntem a grupos (dependendo da privacidade do grupo).
*   Gerenciar a membresia de grupos (aprovar/rejeitar pedidos, promover/rebaixar membros, banir).
*   Permitir a postagem de conteúdo dentro de grupos (ex: discussões, anúncios).
*   Permitir a edição e exclusão de grupos (por proprietários ou administradores).
*   Integrar-se com sistemas de interação como comentários, votos, favoritos para grupos e para o conteúdo dentro dos grupos.

## Estrutura da Documentação para `deeper_groups`:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas necessárias para armazenar dados de grupos (ex: `deeper_groups_entries`, `deeper_groups_members`, `deeper_groups_categories`, `deeper_groups_invites`).

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir e sua documentação para criar as tabelas do módulo de grupos.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o módulo Elixir (ex: `Deeper.Content.GroupsRepo`) que encapsula as queries SQL para interagir com as tabelas de grupos.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para todas as operações relacionadas a grupos (públicas e para membros).

5.  [**API de Administração (`../../07_studio_admin_api/content_management/groups_admin_api.md`)**](../../07_studio_admin_api/content_management/groups_admin_api.md):
    *   Endpoints específicos para administradores gerenciarem todos os aspectos dos grupos.

## Considerações de Design:

*   **Tipos de Privacidade:** Grupos podem ser públicos, privados (requer aprovação para entrar), ou secretos (não listados, apenas por convite).
*   **Papéis de Membros:** Diferentes papéis dentro de um grupo (ex: administrador do grupo, moderador, membro).
*   **Conteúdo do Grupo:** Como o conteúdo específico do grupo (posts, discussões, arquivos) será modelado e acessado via API. Pode ser que o grupo sirva como um \"contexto\" para outros módulos de conteúdo (ex: um feed de atividades filtrado para o grupo).
*   **Notificações:** Notificações para novos posts no grupo, pedidos de adesão, etc.

Este módulo é central para funcionalidades de comunidade e engajamento.