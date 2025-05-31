# Documentação Deeper: APIs para Definição e Dados de Formulários e Grids

Esta seção da documentação \"Deeper\" detalha as APIs RESTful para interagir com os sistemas de Formulários (`sys_forms_engine/`) e Grids de Dados (`sys_grids_engine/`) do UNA.

O objetivo é permitir que um cliente remoto obtenha as definições estruturais desses componentes (campos de formulário, colunas de grid, ações) e, no caso dos grids, os dados a serem exibidos. O cliente será responsável por renderizar a UI do formulário ou do grid com base nessas definições.

## Abordagem Geral:

1.  **Definições de Objetos:**
    *   O UNA usa tabelas como `sys_objects_form` e `sys_objects_grid` para definir instâncias específicas de formulários e grids.
    *   Tabelas associadas como `sys_form_inputs`, `sys_form_displays`, `sys_grid_fields`, `sys_grid_actions` detalham a estrutura desses objetos.
    *   **API \"Deeper\":** Fornecerá endpoints para buscar a definição completa de um objeto de formulário ou grid pelo seu nome.
2.  **Dados para Grids:**
    *   Para grids, a API também precisará de um endpoint para buscar os dados que preenchem o grid, com suporte a paginação, filtros e ordenação, conforme definido no objeto de grid.
3.  **Submissão de Formulários:**
    *   A API \"Deeper\" precisará de endpoints para receber submissões de formulários. O backend será responsável por:
        *   Validar os dados de entrada (baseado nas `checker_func` e `db_pass` do UNA, que precisarão ser reimplementados ou mapeados em Elixir).
        *   Executar a ação principal do formulário (ex: inserir/atualizar dados na tabela de destino especificada em `sys_objects_form.table`).
4.  **Valores Pré-definidos (Listas):**
    *   Formulários frequentemente usam listas de valores pré-definidos (`sys_form_pre_lists`, `sys_form_pre_values`) para campos como `select`, `radio`, `checkbox_set`. A API precisará expor essas listas.

## Estrutura dos Submódulos:

*   [**Motor de Formulários (`sys_forms_engine/`)**](./sys_forms_engine/README.md)
*   [**Motor de Grids (`sys_grids_engine/`)**](./sys_grids_engine/README.md)

Esta abordagem visa fornecer ao cliente toda a informação estrutural e de dados necessária para que ele possa renderizar e interagir com formulários e grids de forma dinâmica.