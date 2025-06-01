# Documentação Deeper: Objetos de Página, Blocos e Layouts

Este documento detalha como a API \"Deeper\" fornecerá as informações necessárias para reconstruir a estrutura e o conteúdo de uma página dinâmica do UNA, com base nas tabelas `sys_objects_page`, `sys_pages_layouts`, `sys_pages_blocks`, `sys_pages_design_boxes` e `sys_pages_types`.

## Responsabilidades Principais da API:

*   Dado um identificador de objeto de página (ex: `bx_persons_home`), retornar:
    *   Metadados da página (título, layout, tipo, configurações de capa, meta tags, etc.).
    *   Informações sobre o layout a ser aplicado.
    *   Uma lista de blocos de conteúdo, organizados por célula do layout, com seus respectivos tipos, conteúdos (ou definições de serviço/dados) e design.

## Componentes Detalhados:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas:
        *   `sys_objects_page`
        *   `sys_pages_layouts`
        *   `sys_pages_blocks`
        *   `sys_pages_design_boxes`
        *   `sys_pages_types`
        *   (Opcional) `sys_pages_wiki_blocks` se o conteúdo wiki dos blocos for gerenciado separadamente.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar as tabelas acima.

3.  [**Módulos de Acesso a Dados (`data_access_modules.md`)**](./data_access_modules.md):
    *   Descreve o `Deeper.PageEngine.PageRepo` (ou similar) que encapsula as queries SQL.
    *   Funções para buscar um objeto de página, seus blocos, informações de layout, etc.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica o endpoint principal (ex: `GET /api/v1/pages/{page_object_name}`) para obter a definição completa da página.

## Tratamento de Blocos do Tipo \"Serviço\":

Este é um aspecto crucial:

*   No UNA PHP, um bloco de serviço executa código PHP de um módulo (`$oModule->serviceMethod($params)`), que geralmente retorna HTML.
*   A API \"Deeper\" **não executará o código PHP**. Em vez disso, para um bloco de serviço, a API deve:
    1.  **Identificar a chamada de serviço:** Ler o `module`, `method` (ou `content` que armazena a chamada serializada) e parâmetros de `sys_pages_blocks.content`.
    2.  **Retornar a Definição do Serviço:** Informar ao cliente qual módulo e método seriam chamados e com quais parâmetros.
    3.  **Retornar Dados Estruturados (Ideal):** O backend \"Deeper\" deve tentar executar uma lógica Elixir equivalente à do serviço PHP original.
        *   Isso significa que para cada \"serviço\" popular do UNA que é usado em blocos (ex: listar os últimos perfis, exibir um formulário, mostrar um feed de atividades), o `PageRepo` (ou um módulo de serviço Elixir dedicado) precisará implementar a lógica para buscar os dados relevantes.
        *   A API então retornaria esses dados em JSON.
        *   **Exemplo:** Se um bloco de serviço PHP listaria os 5 últimos artigos, a API \"Deeper\" para esse bloco retornaria um JSON com a lista desses 5 artigos (título, link, autor, etc.).
    4.  **Responsabilidade do Cliente:** O cliente usaria a \"definição do serviço\" e os \"dados estruturados\" para renderizar o bloco usando seus próprios templates/componentes. Por exemplo, se a API diz \"este bloco é para o serviço 'listar_ultimos_artigos' e aqui estão os dados dos artigos\", o cliente tem um componente que sabe como exibir uma lista de artigos.

Se a implementação da lógica Elixir equivalente para cada serviço PHP for muito complexa inicialmente, uma abordagem mínima seria apenas retornar a \"definição do serviço\", e o cliente teria que fazer chamadas subsequentes a outros endpoints da API \"Deeper\" (ex: `GET /api/v1/articles?latest=5`) para obter os dados. No entanto, retornar os dados diretamente na resposta da página é mais eficiente.

## Fluxo de Requisição de Página:

1.  Cliente solicita `GET /api/v1/pages/{page_object_name}`.
2.  Controller da API chama `Deeper.PageEngine.PageRepo.get_page_structure(page_object_name)`.
3.  `PageRepo` executa queries para:
    *   Obter dados de `sys_objects_page`.
    *   Obter dados do layout de `sys_pages_layouts` (usando `layout_id` da página).
    *   Obter todos os blocos de `sys_pages_blocks` para essa página, ordenados por `cell_id` e `order`.
    *   Para cada bloco, obter informações do design box de `sys_pages_design_boxes`.
    *   Para blocos de serviço, processar o campo `content` para extrair a chamada de serviço e, se possível, buscar os dados correspondentes.
4.  `PageRepo` monta uma estrutura JSON abrangente e a retorna.
5.  Controller envia a resposta JSON ao cliente.