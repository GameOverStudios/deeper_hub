# Documentação Deeper: API para Objetos de Página (`sys_objects_page`) e Blocos

Esta seção detalha como a API \"Deeper\" expõe as definições de \"Objetos de Página\" (`sys_objects_page`) e os \"Blocos de Conteúdo\" (`sys_pages_blocks`) associados a elas. Esta é a funcionalidade central para permitir que um cliente reconstrua a estrutura e o conteúdo de uma página do UNA.

## Tabelas Relevantes do UNA:

*   **`sys_objects_page`**: Define cada página, seu URI, título, layout, submenu, configurações de cache, metadados SEO, etc.
*   **`sys_pages_blocks`**: Define os blocos de conteúdo para cada objeto de página, incluindo seu tipo, conteúdo (HTML ou definição de serviço), célula do layout, design box, etc.
*   **`sys_pages_layouts`**: (Referenciada por `sys_objects_page`) Define a estrutura de células da página.
*   **`sys_pages_design_boxes`**: (Referenciada por `sys_pages_blocks`) Define o estilo visual dos blocos.
*   **`sys_pages_blocks_data`**: (Opcional, menos comum) Armazena dados adicionais ou overrides para instâncias específicas de blocos em contextos de conteúdo. Pode não ser prioridade inicial.

## Responsabilidades da API:

*   Fornecer um endpoint para buscar a definição completa de uma página (metadados de `sys_objects_page` e a lista de seus blocos de `sys_pages_blocks`) por seu URI ou nome de objeto.
*   Para blocos do tipo \"serviço\", a API deve retornar a *definição* do serviço (módulo, método, parâmetros) para que o cliente possa, se necessário, fazer uma chamada subsequente para obter os dados desse serviço.

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas `sys_objects_page`, `sys_pages_blocks`, `sys_pages_layouts`, `sys_pages_design_boxes` (e `sys_pages_blocks_data` se incluída).

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar essas tabelas.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.PageEngine.PagesRepo` e suas funções para buscar dados de páginas e blocos.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica o endpoint principal (ex: `GET /pages`) para buscar definições de página.

## Considerações Importantes:

*   **Blocos de Serviço:** A forma como o cliente lidará com blocos do tipo \"serviço\" é crucial. A API \"Deeper\" não executará o código PHP desses serviços. Em vez disso, ela exporá a *descrição* do serviço. O cliente então:
    *   Ou terá componentes UI pré-construídos que sabem como buscar dados para serviços conhecidos (ex: um componente \"últimos perfis\" que chama `GET /api/v1/persons?sort=latest&limit=5`).
    *   Ou a API \"Deeper\" precisará de uma camada de \"data-service\" que possa executar uma lógica equivalente aos serviços PHP e retornar JSON (ex: `GET /api/v1/service-data?module=bx_persons&method=get_block_latest_profiles&params={\"count\":5}`).
*   **Visibilidade de Blocos:** A API deve respeitar `visible_for_levels` e `hidden_on` dos blocos, filtrando os blocos retornados com base no nível de ACL do usuário autenticado (se houver) e no contexto da página.
*   **Caching:** Definições de página e blocos podem ser cacheadas, mas o conteúdo dinâmico de blocos de serviço exigirá uma estratégia de cache separada ou não será cacheado na API de definição de página.