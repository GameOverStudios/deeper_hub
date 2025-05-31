# Documentação Deeper: Módulos de Conteúdo da API

Este diretório detalha a implementação da API \"Deeper\" para os diversos módulos de conteúdo do sistema UNA. Cada submódulo aqui (ex: `bx_persons`, `bx_posts`, `bx_events`) representa um tipo específico de conteúdo que os usuários podem criar, visualizar e interagir.

**Objetivo Principal:** Fornecer endpoints RESTful para operações CRUD (Criar, Ler, Atualizar, Deletar) em cada tipo de conteúdo, bem como para funcionalidades específicas do módulo (ex: listar amigos de um perfil `bx_persons`, buscar posts por tag).

## Abordagem Geral para Módulos de Conteúdo:

Para cada módulo de conteúdo do UNA que será suportado pela API \"Deeper\":

1.  [**Visão Geral do Módulo (`bx_module_name/README.md`)**](./bx_module_name/README.md):
    *   Descreve o propósito do módulo no sistema UNA.
    *   Lista as principais funcionalidades que a API \"Deeper\" para este módulo irá cobrir.

2.  [**Modelo de Dados e Esquema SQLite (`bx_module_name/database_schema.md`)**](./bx_module_name/database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite de todas as tabelas primárias e de suporte do módulo (ex: `bx_persons_data`, `bx_persons_pictures`, `bx_persons_cmts` para o módulo de Pessoas).

3.  [**Migrações Elixir (`bx_module_name/migrations/`)**](./bx_module_name/migrations/README.md):
    *   Documentação e código Elixir para as migrações que criam as tabelas do módulo.

4.  [**Módulos de Acesso a Dados (Repositórios) (`bx_module_name/data_access_module.md`)**](./bx_module_name/data_access_module.md):
    *   Descreve os módulos Elixir (ex: `Deeper.Content.PersonsRepo`) que encapsulam as queries SQL para interagir com as tabelas do módulo.
    *   Detalha funções para CRUD, listagens com filtros/ordenação/paginação, e queries específicas do módulo.
    *   [**Queries SQL Otimizadas (`bx_module_name/data_access_module/sql_queries.md`)**](./bx_module_name/data_access_module/sql_queries.md): Documentação específica para SQLs complexos e estratégias de otimização.

5.  [**Endpoints da API (`bx_module_name/api_endpoints/`)**](./bx_module_name/api_endpoints/README.md):
    *   Especifica os endpoints RESTful para todas as operações do módulo.
    *   Detalha os métodos HTTP, parâmetros, corpos de requisição/resposta, e exemplos.

6.  [**Mapeamento da Lógica de \"Serviço\" PHP (`bx_module_name/service_logic_mapping.md`)**](./bx_module_name/service_logic_mapping.md):
    *   Crucial para módulos que fornecem blocos de página do tipo `service`.
    *   Descreve como as funções de serviço PHP do módulo UNA (ex: `BxPersonsModule::service_entity_friends()`) serão traduzidas em lógica Elixir e/ou como a API de Páginas (`GET /api/v1/pages`) fornecerá os dados para esses blocos.

7.  [**Objetos Associados (Comentários, Votos, etc.) (`bx_module_name/associated_objects/`)**](./bx_module_name/associated_objects/README.md):
    *   Detalha como os sistemas genéricos de interação (comentários, votos, favoritos, denúncias) se aplicam e são acessados no contexto deste módulo de conteúdo.
    *   Pode referenciar as APIs genéricas definidas em `04_interaction_systems/`, mas especificar os `object_id`s e contextos.

## Lista de Módulos de Conteúdo (Exemplos a serem documentados):

*   [**Pessoas (`bx_persons/`)**](./bx_persons/README.md): Gerenciamento de perfis de usuário do tipo \"pessoa\". *(Nosso foco inicial)*
*   **Posts/Artigos (`bx_posts/`)**: Criação e visualização de posts de blog ou artigos.
*   **Eventos (`bx_events/`)**: Gerenciamento de eventos com data, local, participantes.
*   **Grupos (`bx_groups/`)**: Criação e gerenciamento de grupos de usuários.
*   **Fotos/Álbuns (`bx_photos/`)**: Upload e organização de fotos.
*   **Vídeos (`bx_videos/`)**: Upload e visualização de vídeos.
*   ... e outros módulos de conteúdo do UNA.

A implementação de cada módulo de conteúdo envolverá a criação das tabelas no SQLite, o desenvolvimento dos repositórios Elixir para acesso aos dados (com foco na otimização de queries SQL) e a exposição das funcionalidades através de endpoints RESTful bem definidos.