# Documentação Deeper: Motores de Formulários e Grades

Este diretório detalha a implementação da API \"Deeper\" para os motores de Formulários Dinâmicos e Grades de Dados, que são componentes cruciais para a interação do usuário e a apresentação de dados no sistema UNA.

## Objetivos:

*   **Motor de Formulários:** Fornecer as definições (campos, tipos, validações, valores pré-definidos) para que um cliente possa renderizar formulários dinamicamente e submeter dados.
*   **Motor de Grades:** Fornecer as definições (colunas, fontes de dados, ações) e os próprios dados para que um cliente possa renderizar tabelas/grades de dados com funcionalidades como paginação, filtragem e ordenação.

## Estrutura dos Submódulos:

1.  [**Motor de Formulários Dinâmicos (`sys_forms_engine/`)**](./sys_forms_engine/README.md):
    *   API para obter a estrutura de um formulário (`sys_objects_form`, `sys_form_inputs`, `sys_form_displays`, etc.).
    *   API para lidar com a submissão de formulários (validação e processamento dos dados).

2.  [**Motor de Grades de Dados Dinâmicas (`sys_grids_engine/`)**](./sys_grids_engine/README.md):
    *   API para obter a definição de uma grade (`sys_objects_grid`, `sys_grid_fields`, `sys_grid_actions`).
    *   API para buscar os dados a serem exibidos na grade, suportando paginação, filtragem e ordenação.

## Abordagem Geral:

*   **Definições via API:** A API \"Deeper\" fornecerá a estrutura (metadados) dos formulários e grades em formato JSON.
*   **Renderização no Cliente:** O cliente remoto será responsável por renderizar a interface do formulário/grade com base nessas definições.
*   **Interação de Dados:**
    *   Para formulários, o cliente submeterá os dados preenchidos para um endpoint da API que realizará a validação e o processamento.
    *   Para grades, o cliente solicitará os dados à API, possivelmente com parâmetros de paginação, filtro e ordenação. A API executará as queries SQL correspondentes (idealmente otimizadas) para buscar os dados.

A modularidade desses motores no UNA permite que diferentes partes do sistema definam seus próprios formulários e grades sem duplicar lógica. A API \"Deeper\" buscará manter essa flexibilidade.