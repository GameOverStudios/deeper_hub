# Documentação Deeper: Módulos de Conteúdo

Este diretório detalha a implementação da API para os diversos módulos de conteúdo do sistema \"Deeper\". Cada submódulo aqui representa um tipo específico de conteúdo que os usuários podem criar e interagir (ex: perfis, posts/artigos, eventos, grupos, etc.).

A implementação de cada módulo de conteúdo geralmente envolverá:

*   **Definição do Esquema SQLite:** `CREATE TABLE` statements para as tabelas de dados principais do módulo e quaisquer tabelas de metadados associadas.
*   **Migrações Elixir:** Módulos para aplicar esses esquemas.
*   **Módulos de Acesso a Dados (Repositórios):** Funções Elixir com SQL direto para CRUD e queries customizadas.
*   **Endpoints da API:** Rotas e controllers Phoenix para expor as funcionalidades do módulo via REST.
*   **Mapeamento da Lógica de Serviço:** Como as funcionalidades dos \"serviços\" do módulo PHP original do UNA são traduzidas para a API Elixir.
*   **Integração com Sistemas Associados:** Como o módulo interage com comentários, votos, favoritos, arquivos, etc.

## Módulos de Conteúdo Documentados:

*   [**Perfis de Usuário (`bx_persons/`)**](./bx_persons/README.md) - (JÁ COBERTO)
*   [**Artigos/Posts (`deeper_articles/`)**](./deeper_articles/README.md) - (A SER DETALHADO ABAIXO)
*   *(Outros módulos de conteúdo como `bx_events`, `bx_groups`, etc., serão adicionados aqui)*