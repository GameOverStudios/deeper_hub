# Documentação Deeper: Módulo Marketplace/Classificados (`bx_market`)

Este módulo da API \"Deeper\" é responsável por fornecer funcionalidades de um marketplace ou sistema de classificados, permitindo que usuários listem produtos ou serviços para venda, troca ou visualização. A implementação será baseada nas tabelas e conceitos do módulo `bx_market` do UNA.

## Responsabilidades Principais da API:

*   Permitir a criação, leitura, atualização e exclusão (CRUD) de listagens de produtos/serviços.
*   Listar produtos com filtros (categoria, preço, localização, etc.) e paginação.
*   Exibir detalhes de um produto específico, incluindo imagens, descrição, preço, informações do vendedor.
*   Gerenciar categorias de produtos.
*   (Escopo v1) Foco na listagem e visualização. Interações de compra/transação direta não serão o foco inicial da API, mas a estrutura de dados deve permitir futuras expansões.

## Estrutura da Documentação do Módulo `bx_market`:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas do `bx_market` (ex: `bx_market_entries`, `bx_market_categories`, `bx_market_files`, `bx_market_prices`, etc.).

2.  [**Migrações Elixir (`migrations/README.md`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir e sua documentação para criar as tabelas do marketplace.

3.  [**Módulos de Acesso a Dados (`data_access_modules.md`)**](./data_access_modules.md):
    *   Descreve os módulos Elixir (ex: `Deeper.Content.MarketRepo`) que encapsulam as queries SQL para interagir com as tabelas do marketplace.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para todas as operações relacionadas ao marketplace.

5.  [**Mapeamento da Lógica de Serviço (`service_logic_mapping.md`)**](./service_logic_mapping.md):
    *   Analisa como as funcionalidades e \"service calls\" do módulo `bx_market` original do UNA serão traduzidas para a lógica da API Elixir.

6.  [**Objetos Associados (`associated_objects.md`)**](./associated_objects.md):
    *   Detalha como sistemas de interação (comentários, votos, favoritos, denúncias) se aplicam às listagens do marketplace.

## Tabelas Principais do UNA (Referência para Adaptação):

*   `bx_market_entries`: Tabela principal para as listagens de produtos/serviços.
*   `bx_market_categories`: Categorias para os produtos.
*   `bx_market_files`: Associação de arquivos (imagens) às listagens.
*   `bx_market_prices`: Preços dos produtos (pode suportar múltiplas moedas ou tipos de preço).
*   `bx_market_licenses` (se aplicável): Para licenças de software ou produtos digitais.
*   Tabelas de rastreamento para visualizações, comentários, votos, etc., específicas do módulo (ex: `bx_market_views_track`, `bx_market_cmts`).

## Considerações para a API `bx_market`:

*   **Imagens:** O upload e associação de múltiplas imagens por produto são cruciais. Isso se integrará com o `06_file_management/`.
*   **Categorias:** A API deve permitir listar produtos por categoria e gerenciar as categorias (via API de Admin).
*   **Preços:** A representação de preços precisa ser flexível (valor, moeda).
*   **Vendedor:** Cada listagem estará associada a um perfil de vendedor (um `profile_id` de `sys_profiles`).
*   **Busca e Filtragem:** Funcionalidades robustas de busca e filtragem serão essenciais.

Esta documentação guiará a implementação da API para o módulo `bx_market`, focando em fornecer uma base sólida para funcionalidades de classificados ou marketplace dentro do ecossistema \"Deeper\".