# Documentação Deeper: Módulos de Conteúdo

Este diretório detalha a implementação da API para os diversos módulos de conteúdo que o sistema \"Deeper\" suportará, baseados nas funcionalidades do UNA. Cada submódulo aqui representa um tipo distinto de conteúdo que os usuários podem criar, compartilhar e interagir.

## Módulos de Conteúdo Documentados:

*   [**Artigos/Posts (`deeper_articles/`)**](./deeper_articles/README.md): Para conteúdo textual, blogs, notícias.
*   [**Eventos (`deeper_events/`)**](./deeper_events/README.md): Para gerenciamento de eventos com data, local, participantes.
*   [**Grupos/Comunidades (`deeper_groups/`)**](./deeper_groups/README.md): Para criação de espaços de discussão e colaboração temáticos.
*   [**Álbuns de Fotos (`deeper_photo_albums/`)**](./deeper_photo_albums/README.md): Para organização e compartilhamento de coleções de imagens.
*   [**Enquetes (`deeper_polls/`)**](./deeper_polls/README.md): Para criação de enquetes com opções de voto.
*   [**Fóruns de Discussão (`deeper_forums/`)**](./deeper_forums/README.md): Para discussões estruturadas em tópicos e posts.
*   [**Marketplace/Classificados (`bx_market/`)**](./bx_market/README.md): Para listagem de produtos ou serviços para venda/troca. <!-- NOVA ADIÇÃO -->

## Abordagem de Implementação para cada Módulo de Conteúdo:

Para cada módulo:

1.  **`README.md` do Módulo:** Visão geral da funcionalidade do módulo e como ele se traduz para a API \"Deeper\".
2.  **`database_schema.md`:** Definição dos `CREATE TABLE` statements (SQLite) para as tabelas específicas do módulo, baseadas no esquema original do UNA.
3.  **`migrations/README.md` e `migrations/*.elixir.md`:** Documentação e código Elixir para as migrações que criam essas tabelas.
4.  **`data_access_modules.md`:** Descrição dos módulos Elixir (Repositórios) que encapsulam o SQL direto para interagir com as tabelas do módulo, incluindo exemplos de SQL para CRUD e queries customizadas.
5.  **`api_endpoints.md`:** Especificação detalhada dos endpoints RESTful da API para o módulo, incluindo exemplos de requisição e resposta.
6.  **`service_logic_mapping.md` (quando aplicável):** Análise de como as \"service calls\" ou lógicas de negócios complexas do módulo PHP original serão mapeadas para a API Elixir e seus módulos de acesso a dados.
7.  **`associated_objects.md` (quando aplicável):** Detalhamento de como sistemas de interação genéricos (comentários, votos, etc.) se aplicam a este tipo de conteúdo.

O objetivo é fornecer dados estruturados via API JSON, permitindo que o cliente remoto renderize a interface e implemente a lógica de interação.