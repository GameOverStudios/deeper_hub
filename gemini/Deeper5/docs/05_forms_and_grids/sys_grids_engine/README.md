# Documentação Deeper: Motor de Grades de Dados Dinâmicas (`sys_grids_engine`)

Este documento detalha a API \"Deeper\" para fornecer as definições e os dados para grades de dados dinâmicas, baseando-se nas tabelas `sys_objects_grid`, `sys_grid_fields`, e `sys_grid_actions` do UNA.

O objetivo é permitir que um cliente remoto:
1.  Obtenha a **definição** de uma grade específica (colunas, filtros disponíveis, ações).
2.  Obtenha os **dados paginados e filtrados** para popular essa grade.

A API de **administração** para criar e configurar estes objetos de grade será detalhada na seção `07_studio_admin_api/grids_admin_api.md` (a ser criada, ou como parte do `page_builder_admin_api.md`).

## Abordagem \"Deeper\" para Grades:

1.  **Definição da Grade:**
    *   A API retornará a estrutura da grade, incluindo:
        *   Lista de colunas (`sys_grid_fields`): nome, título (traduzido), largura, se é traduzível, limite de caracteres, parâmetros de formatação.
        *   Ações disponíveis (`sys_grid_actions`): nome, título, ícone, tipo (single, bulk, independent), se requer confirmação.
        *   Informações sobre filtros disponíveis (derivados de `sys_objects_grid.filter_fields`).
        *   Informações sobre ordenação (derivados de `sys_objects_grid.sorting_fields`).
        *   Configurações de paginação (URL base para dados, itens por página padrão).
2.  **Dados da Grade:**
    *   Um endpoint separado da API será usado para buscar os dados reais da grade. Este endpoint aceitará parâmetros de query para paginação (`page`, `per_page`), filtros e ordenação.
    *   O backend \"Deeper\" construirá e executará a query SQL (definida em `sys_objects_grid.source` se `source_type='Sql'`, ou chamará uma lógica Elixir se for um tipo de fonte diferente) para buscar os dados.

## Responsabilidades Principais da API do Motor de Grades:

*   Dado um nome de objeto de grade (ex: `bx_persons_administration`), retornar sua definição completa (colunas, ações, filtros).
*   Dado um nome de objeto de grade e parâmetros de query (pagina, filtros, ordenação), retornar o conjunto de dados paginado.

## Estrutura da Documentação para Grades:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   `CREATE TABLE` para `sys_objects_grid`, `sys_grid_fields`, `sys_grid_actions`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Módulos de migração.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.GridsEngine.GridRepo`.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints para buscar definições de grades e seus dados.

## Considerações de Design:

*   **Fonte de Dados (`sys_objects_grid.source_type`, `sys_objects_grid.source`):**
    *   Se `source_type='Sql'`, o campo `source` contém uma query SQL. O `GridRepo` precisará parsear esta query base, aplicar os filtros, ordenação e paginação dinamicamente de forma segura. Isso pode ser complexo e propenso a SQL injection se não for feito com extremo cuidado.
        *   **Alternativa Segura:** Em vez de executar SQL arbitrário do DB, o `source` poderia ser um nome de \"query nomeada\" ou um identificador que o `GridRepo` mapeia para uma função Elixir específica que constrói a query Ecto/SQL de forma segura.
    *   Se `source_type='Array'` (ou um tipo customizado Elixir), o `source` indicaria uma função Elixir que provê os dados.
*   **Filtros e Ordenação:** A API deve expor os campos filtráveis e ordenáveis. O cliente os envia como query params. O `GridRepo` os aplica à query SQL.
*   **Ações (`sys_grid_actions`):** A definição da ação incluirá seu nome e tipo. A execução da ação (ex: deletar um item selecionado) será um POST/DELETE para um endpoint da API do recurso correspondente, não um endpoint da API de grades diretamente (a grade apenas *descreve* a ação).
*   **Traduções:** Títulos de colunas, ações, etc., devem ser traduzidos.
*   **Formatação de Células:** `sys_grid_fields.params` pode conter informações sobre como formatar o valor da célula (ex: formatar data, truncar texto). A API deve passar esses parâmetros para o cliente, que aplicará a formatação.