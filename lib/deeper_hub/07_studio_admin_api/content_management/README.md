# API de Administração: Gerenciamento de Conteúdo

Esta seção da API de Administração \"Deeper\" foca em fornecer endpoints para que administradores e moderadores gerenciem os diversos tipos de conteúdo gerados pelos usuários na plataforma.

Isso inclui tarefas como:

*   Listar e visualizar conteúdos de diferentes módulos.
*   Moderar conteúdo (aprovar, rejeitar, ocultar, destacar).
*   Editar detalhes do conteúdo.
*   Excluir conteúdo.
*   Gerenciar categorias e outros metadados associados ao conteúdo.

**Autenticação:** Requerida (nível de administrador ou moderador com permissões específicas para o tipo de conteúdo).

## Estrutura por Módulo de Conteúdo:

Para cada módulo de conteúdo principal da plataforma (ex: Artigos, Marketplace, Eventos, Organizações), haverá um arquivo `.md` dedicado nesta seção que detalha os endpoints administrativos específicos para aquele tipo de conteúdo.

**Exemplos de Arquivos Planejados:**

*   [**Administração de Artigos (`articles_admin_api.md`)**](./articles_admin_api.md)
*   [**Administração do Marketplace (`market_admin_api.md`)**](./market_admin_api.md)
*   [**Administração de Eventos (`events_admin_api.md`)**](./events_admin_api.md)
*   [**Administração de Grupos (`groups_admin_api.md`)**](./groups_admin_api.md)
*   [**Administração de Organizações (`organizations_admin_api.md`)**](./organizations_admin_api.md)
*   *(E assim por diante para outros módulos de conteúdo)*

## Princípios Gerais para APIs de Gerenciamento de Conteúdo:

*   **Listagem com Filtros Avançados:** Os endpoints `GET` para listar conteúdos devem suportar filtros específicos de administração (ex: por `status_admin`, por data de criação, por autor, por denúncias).
*   **Ações de Moderação:** Endpoints `PUT` ou `POST /action` para mudar o status de moderação (`status_admin` das tabelas de conteúdo), destacar (`featured_until`), etc.
*   **Edição Completa:** Endpoints `PUT` que permitem aos administradores modificar qualquer campo de uma entrada de conteúdo (respeitando validações).
*   **Exclusão (Hard Delete):** Endpoints `DELETE` para remoção definitiva de conteúdo, se necessário.
*   **Gerenciamento de Metadados:** Se o módulo de conteúdo usar categorias, tags, ou outros metadados, a API de admin deve permitir o gerenciamento dessas taxonomias (ex: criar/editar/deletar categorias do marketplace).

Esta API é crucial para manter a qualidade e a ordem do conteúdo na plataforma \"Deeper\".