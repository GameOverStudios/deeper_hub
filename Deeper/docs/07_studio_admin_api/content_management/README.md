# Documentação Deeper: API de Administração - Gerenciamento de Conteúdo

Este diretório detalha os endpoints da API \"Deeper\" destinados aos administradores para gerenciar o conteúdo gerado pelos usuários e pelo sistema nos diversos módulos de conteúdo (ex: artigos, eventos, grupos, fotos, etc.).

## Objetivos Principais:

*   Fornecer uma interface consistente para administradores realizarem operações CRUD (Criar, Ler, Atualizar, Deletar) em entradas de conteúdo de qualquer módulo.
*   Permitir a moderação de conteúdo (aprovar, rejeitar, marcar como spam).
*   Gerenciar metadados associados ao conteúdo (categorias, tags, destaque, etc.).
*   Visualizar e gerenciar interações relacionadas ao conteúdo (comentários, votos, denúncias).

## Estrutura da Documentação:

Para cada módulo de conteúdo principal (ex: `deeper_articles`, `deeper_events`), haverá um arquivo `.md` específico nesta seção (ex: `articles_admin_api.md`, `events_admin_api.md`) detalhando os endpoints de administração para aquele tipo de conteúdo.

Cada arquivo de API de administração de conteúdo incluirá:

*   Endpoints para listar entradas de conteúdo com filtros avançados (ex: por autor, status, data).
*   Endpoints para visualizar os detalhes completos de uma entrada de conteúdo (visão de admin).
*   Endpoints para criar novas entradas de conteúdo (como administrador).
*   Endpoints para atualizar entradas de conteúdo existentes.
*   Endpoints para alterar o status de entradas de conteúdo (publicado, rascunho, pendente, deletado, etc.).
*   Endpoints para gerenciar metadados (destaque, categorias, tags).
*   Endpoints para visualizar/moderar comentários, votos e denúncias associadas ao conteúdo.

## Convenções Gerais para APIs de Administração de Conteúdo:

*   **Prefixo de Endpoint:** `/api/v1/admin/content/{module_uri}/{resource_uri}`
    *   Ex: `/api/v1/admin/content/articles/entries` para listar artigos.
    *   `{module_uri}` será o identificador do módulo (ex: `articles`, `events`).
*   **Autenticação e Autorização:**
    *   Todas as requisições requerem autenticação de administrador.
    *   Permissões granulares (ACL) podem ser aplicadas para diferentes tipos de ações de administração de conteúdo (ex: um moderador pode editar, mas não deletar permanentemente).
*   **Respostas:** Seguirão as convenções gerais da API \"Deeper\".
*   **Paginação e Filtragem:** Endpoints de listagem suportarão paginação e filtros robustos.

## Exemplo de Submódulos (a serem detalhados):

*   [**Gerenciamento de Artigos (`articles_admin_api.md`)**](./articles_admin_api.md)
*   [**Gerenciamento de Eventos (`events_admin_api.md`)**](./events_admin_api.md)
*   [**Gerenciamento de Grupos (`groups_admin_api.md`)**](./groups_admin_api.md)
*   ... e assim por diante para cada módulo de conteúdo relevante.

A API de gerenciamento de conteúdo é vital para a manutenção e moderação da plataforma \"Deeper\".