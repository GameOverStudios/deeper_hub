# Documentação Deeper: Conceitos Fundamentais da API

Este diretório contém a documentação dos conceitos centrais, convenções e estratégias que guiarão o desenvolvimento do backend Elixir \"Deeper\" para o sistema UNA.

## Seções:

1.  [**Visão Geral do Banco de Dados (SQLite)** (`database_schema_sqlite.md`)](./database_schema_sqlite.md):
    *   Descreve a abordagem para portar o esquema do UNA MySQL para SQLite.
    *   Apresenta os `CREATE TABLE` statements para todas as tabelas do UNA, adaptados para SQLite.
    *   Discute considerações sobre tipos de dados, chaves primárias/estrangeiras, índices e collations.

2.  [**Autenticação e Autorização (ACL)** (`authentication_authorization.md`)](./authentication_authorization.md):
    *   Detalha o fluxo de autenticação da API (provavelmente JWT).
    *   Explica como a lógica de ACL (Access Control Levels) do UNA será implementada e verificada nos endpoints da API para proteger recursos.

3.  [**Convenções de Design da API** (`api_design_conventions.md`)](./api_design_conventions.md):
    *   Padrões para nomenclatura de endpoints.
    *   Formato de respostas JSON (sucesso e erro).
    *   Versionamento da API.
    *   Uso de métodos HTTP.
    *   Paginação, filtragem e ordenação em endpoints de listagem.

4.  [**Notas sobre Otimização de SQL** (`sql_optimization_notes.md`)](./sql_optimization_notes.md):
    *   Estratégias e boas práticas para escrever SQL otimizado manualmente.
    *   Uso de `JOIN`s, `EXPLAIN QUERY PLAN` (SQLite), e considerações sobre índices.

## Objetivo do Projeto \"Deeper\"

Criar um backend Elixir RESTful que sirva como uma nova camada de acesso aos dados e lógica do sistema UNA, utilizando inicialmente um banco de dados SQLite (com o esquema portado do UNA). Este backend permitirá que um cliente remoto (web, mobile, etc.) construa a interface e interaja com as funcionalidades do sistema de forma moderna e desacoplada.

## Tecnologias Chave

*   **Elixir:** Linguagem de programação funcional e concorrente.
*   **Phoenix Framework:** Framework web para construção da API RESTful (embora o foco inicial seja na lógica de dados e API, Phoenix será o provável framework para a camada web).
*   **`DBConnection` (ou camada similar `Deeper.Core.Data.Repo`):** Para gerenciamento de pool de conexões e execução direta de queries SQL.
*   **SQLite:** Banco de dados relacional leve para a fase inicial de desenvolvimento e portabilidade do esquema.
*   **JSON:** Formato padrão para troca de dados na API.

## Processo de Desenvolvimento

1.  **Documentação Primeiro:** Criação detalhada de arquivos README.md para cada módulo e funcionalidade, definindo schemas, migrações, SQLs de acesso a dados e endpoints da API.
2.  **Implementação de Migrações:** Escrita de módulos Elixir para criar a estrutura do banco de dados SQLite.
3.  **Implementação de Módulos de Acesso a Dados:** Criação de \"Repositórios\" ou \"Contextos\" Elixir com funções que executam SQL direto para operações CRUD e queries customizadas.
4.  **Implementação de Controllers da API:** Desenvolvimento dos controllers Phoenix que utilizam os módulos de acesso a dados para expor a funcionalidade via REST.
5.  **Desenvolvimento Incremental:** Começando pelos módulos core do sistema e expandindo gradualmente.