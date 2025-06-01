# Documentação Deeper: Motores de Formulários e Grades Dinâmicas

Este diretório detalha como a API \"Deeper\" fornecerá as definições e, em alguns casos, os dados necessários para que um cliente remoto possa construir e renderizar formulários dinâmicos e grades de dados, baseando-se nos sistemas `sys_objects_form`, `sys_form_inputs`, `sys_objects_grid`, etc., do UNA.

O objetivo não é que a API \"Deeper\" renderize HTML para formulários ou grades, mas sim que forneça a **estrutura e metadados** em JSON para que o cliente possa usar seus próprios componentes de UI para construí-los.

A API de **administração** para criar e configurar estes objetos de formulário e grid será detalhada na seção `07_studio_admin_api/forms_grids_admin_api.md` (a ser criada, ou como parte do `page_builder_admin_api.md`).

## Abordagem Geral:

1.  **Objetos de Definição no UNA:** O UNA usa `sys_objects_form` para definir cada formulário (campos, atributos, ação de submissão) e `sys_objects_grid` para definir cada grade (fonte de dados, colunas, ações, filtros).
2.  **API \"Deeper\":**
    *   Fornecerá endpoints para buscar a definição de um formulário específico ou de uma grade específica pelo nome de seu objeto.
    *   Para formulários, isso incluirá a lista de campos de entrada com seus tipos, legendas, validações, valores pré-definidos, etc.
    *   Para grades, isso incluirá a definição das colunas, informações sobre filtros, ordenação e, crucialmente, um endpoint separado para buscar os dados paginados da grade.

## Estrutura dos Submódulos:

1.  [**Motor de Formulários Dinâmicos (`sys_forms_engine/`)**](./sys_forms_engine/README.md):
    *   API para obter a definição de um formulário (estrutura e campos).
    *   Como a submissão de formulários pela API será tratada.

2.  [**Motor de Grades de Dados Dinâmicas (`sys_grids_engine/`)**](./sys_grids_engine/README.md):
    *   API para obter a definição de uma grade (colunas, filtros, ações).
    *   API para buscar os dados paginados e filtrados para uma grade.

## Integração com Módulos de Conteúdo e Blocos de Página:

*   Muitos módulos de conteúdo (ex: `deeper_articles`) usarão formulários definidos (ex: `deeper_articles_form_add`, `deeper_articles_form_edit`) para suas operações de CRUD. A API de artigos pode referenciar esses objetos de formulário.
*   Blocos de página do tipo \"serviço\" no UNA frequentemente renderizam formulários ou grades. A API de páginas (de `02_page_rendering_engine`) para tais blocos pode indicar o nome do objeto de formulário/grade que o cliente deve buscar e renderizar.
    *   **Exemplo:** Um bloco de serviço para \"Adicionar Artigo\" na resposta da API de página pode ter:

```json
        \"processed_content\": {
          \"type\": \"form_definition_object\",
          \"form_object_name\": \"deeper_articles_form_add\"
        }
```

        O cliente então faria `GET /api/v1/forms/deeper_articles_form_add` para obter a definição do formulário.

O cliente remoto será responsável por usar as definições JSON da API para renderizar os formulários e grades com seus próprios componentes de UI.