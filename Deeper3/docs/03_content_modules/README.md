# Documentação Deeper: APIs para Módulos de Conteúdo

Esta seção da documentação \"Deeper\" detalha as APIs RESTful para interagir com os dados específicos dos vários módulos de conteúdo do sistema UNA. Cada submódulo aqui representará um módulo de conteúdo do UNA (ex: Pessoas, Eventos, Grupos, Posts).

O objetivo é fornecer endpoints para operações CRUD (Criar, Ler, Atualizar, Deletar) sobre os itens de conteúdo, bem como para listar coleções de conteúdo com filtros, paginação e ordenação. Além disso, serão abordadas interações comuns associadas a esses conteúdos, como comentários, votos, visualizações, etc., embora os sistemas genéricos para essas interações sejam definidos em `04_interaction_systems/`.

## Abordagem Geral para Módulos de Conteúdo:

Para cada módulo de conteúdo do UNA (ex: `bx_persons`):

1.  **Definição do Esquema de Dados:** As tabelas principais do módulo (ex: `bx_persons_data`, `bx_persons_pictures`) e suas tabelas de \"tracking\" (ex: `bx_persons_views_track`, `bx_persons_cmts`) serão definidas para SQLite.
2.  **Migrações Elixir:** Serão criadas migrações para essas tabelas.
3.  **Módulo de Acesso a Dados (Repo do Módulo):** Um Repo específico do módulo (ex: `Deeper.Content.PersonsRepo`) encapsulará as queries SQL para todas as operações de dados.
4.  **Endpoints da API:** Serão definidos endpoints RESTful para:
    *   Listar itens de conteúdo (com paginação, filtros, ordenação).
    *   Criar novos itens de conteúdo.
    *   Ler os detalhes de um item de conteúdo específico (por ID ou URI/slug).
    *   Atualizar um item de conteúdo existente.
    *   Deletar um item de conteúdo.
    *   Endpoints para funcionalidades específicas do módulo (ex: upload de fotos para um perfil de pessoa, listagem de comentários de um post).
5.  **Mapeamento de Lógica de \"Serviço\" (Blocos de Página):** Se o módulo PHP original expunha \"service calls\" usadas em blocos de página (`sys_pages_blocks`), esta seção documentará como esses serviços são mapeados para dados retornados pela API \"Deeper\" ou para endpoints de dados específicos.
6.  **Interações Associadas:** Como os sistemas genéricos de comentários, votos, favoritos, etc. (definidos em `04_interaction_systems/`) se aplicam e são acessados no contexto deste módulo de conteúdo.

## Estrutura de Submódulos:

*   [**`bx_persons/`**](./bx_persons/README.md): API para o módulo \"Pessoas\".
*   *(Outros módulos como `bx_posts/`, `bx_events/`, `bx_groups/` serão adicionados aqui conforme o desenvolvimento avança).*

O desenvolvimento de cada API de módulo de conteúdo seguirá um padrão similar, adaptado às especificidades de cada tipo de conteúdo.