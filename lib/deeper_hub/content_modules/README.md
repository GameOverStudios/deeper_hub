# Documentação Deeper: Módulos de Conteúdo

Este diretório detalha como a API \"Deeper\" fornecerá acesso aos dados de diferentes módulos de conteúdo originários do sistema UNA. Cada submódulo aqui representa um tipo específico de conteúdo (ex: artigos, eventos, grupos, fotos) e descreve os endpoints da API para criar, ler, atualizar e deletar (CRUD) essas entidades, bem como interações associadas (comentários, votos, etc., que podem usar os sistemas genéricos de `04_interaction_systems`).

A API de **administração** para gerenciar os tipos de conteúdo, categorias, e as próprias entradas de conteúdo será detalhada na seção `07_studio_admin_api/content_management/`.

## Abordagem Geral para Módulos de Conteúdo:

Para cada módulo de conteúdo portado ou implementado no \"Deeper\":

1.  **Definição do Esquema SQLite:** As tabelas do banco de dados UNA para o módulo de conteúdo serão adaptadas para SQLite. Isso inclui a tabela principal de dados e quaisquer tabelas auxiliares (ex: metadados, categorias específicas do módulo, arquivos anexos).
2.  **Migrações Elixir:** Módulos de migração Elixir serão criados para estabelecer esses esquemas no banco de dados.
3.  **Módulo de Acesso a Dados (Repositório):** Um módulo Elixir (ex: `Deeper.Content.ArticlesRepo`) será desenvolvido para encapsular todas as queries SQL diretas para as tabelas do módulo, fornecendo uma API funcional para a lógica de negócios e os controllers. Este repo lidará com:
    *   Operações CRUD.
    *   Buscas com filtros, ordenação e paginação.
    *   JOINs com tabelas relacionadas (ex: autor do perfil, contagem de comentários/votos).
4.  **Endpoints da API RESTful:** Serão definidos endpoints claros e consistentes para interagir com os recursos do módulo de conteúdo.
    *   Listagem de itens (com paginação, filtros, ordenação).
    *   Criação de um novo item.
    *   Leitura de um item específico.
    *   Atualização de um item existente.
    *   Deleção de um item.
    *   Endpoints para interações associadas (ex: `POST /articles/{id}/comments`).
5.  **Lógica de \"Serviço\" e Interações:**
    *   Se o módulo UNA original tinha \"serviços\" PHP usados em blocos de página (ex: `service_latest_articles`), o `PageRepo` (de `02_page_rendering_engine`) ou um módulo de serviço Elixir dedicado chamará as funções apropriadas do repositório de conteúdo para buscar os dados necessários.
    *   Interações como comentários, votos, favoritos usarão os sistemas genéricos definidos em `04_interaction_systems`, mas os endpoints podem ser aninhados sob o recurso de conteúdo (ex: `/articles/{id}/vote`).
6.  **Permissões (ACL):** Todos os endpoints e operações respeitarão as permissões de ACL definidas no sistema UNA (ex: quem pode criar artigos, quem pode ver artigos de rascunho, quem pode editar/deletar). O `ACLValidator` será usado.
7.  **Privacidade:** Configurações de privacidade por item (ex: `allow_view_to` em uma tabela de artigos) serão aplicadas ao retornar dados.

## Estrutura dos Submódulos de Conteúdo:

Cada tipo de conteúdo terá seu próprio subdiretório, contendo:
*   `README.md`: Visão geral do módulo de conteúdo e sua API.
*   `database_schema.md`: Definições `CREATE TABLE` para SQLite.
*   `migrations/README.md` e `migrations/*.elixir.md`: Documentação e código das migrações.
*   `data_access_module.md`: Definição do Repositório Elixir e suas funções SQL.
*   `api_endpoints.md`: Especificação dos endpoints da API RESTful.
*   (Opcional) `service_logic_mapping.md`: Se houver serviços PHP complexos a serem mapeados.
*   (Opcional) `associated_objects.md`: Se houver interações específicas além das genéricas.

## Módulos de Conteúdo Planejados/Exemplos:

*   [**Artigos/Posts (`deeper_articles/`)**](./deeper_articles/README.md) - (Exemplo a ser detalhado a seguir)
*   [**Eventos (`deeper_events/`)**](./deeper_events/README.md)
*   [**Grupos/Comunidades (`deeper_groups/`)**](./deeper_groups/README.md)
*   [**Álbuns de Fotos e Fotos (`deeper_photo_albums/`)**](./deeper_photo_albums/README.md)
*   [**Enquetes (`deeper_polls/`)**](./deeper_polls/README.md)
*   [**Fóruns de Discussão (`deeper_forums/`)**](./deeper_forums/README.md) (Pode ser mais complexo, envolvendo tópicos e posts)
*   [**Marketplace/Classificados (`bx_market/`)**](./bx_market/README.md)
*   [**Perfis de Organizações (`bx_organizations/`)**](./bx_organizations/README.md) (Similar a `bx_persons`, mas para um tipo diferente)
*   ... (outros da sua lista de status) ...

A implementação de cada módulo de conteúdo seguirá um padrão similar, adaptando-se às especificidades de suas tabelas e funcionalidades.