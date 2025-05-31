# Documentação Deeper: Formulários e Grids da API

Este diretório detalha como a API \"Deeper\" lidará com a definição e submissão de formulários, bem como com a obtenção de dados para grids (tabelas de exibição de dados) do sistema UNA.

**Objetivo Principal:**

*   **Formulários:** Permitir que o cliente remoto obtenha a definição completa de um formulário (campos, tipos, validações, valores pré-definidos) para que possa construí-lo dinamicamente. A API também precisará de endpoints para receber as submissões desses formulários.
*   **Grids:** Permitir que o cliente remoto obtenha os dados e a configuração de uma grid (colunas, filtros, ações) para renderizar tabelas de dados com paginação, ordenação e filtragem.

## Componentes Principais (do UNA e como a API os expõe):

1.  [**Motor de Formulários (`sys_forms_engine/`)**](./sys_forms_engine/README.md):
    *   O UNA possui um sistema robusto para definir formulários (`sys_objects_form`), seus campos de entrada (`sys_form_inputs`), e como eles são exibidos (`sys_form_displays`).
    *   A API \"Deeper\" fornecerá a estrutura do formulário e validará as submissões.

2.  [**Motor de Grids (`sys_grids_engine/`)**](./sys_grids_engine/README.md):
    *   O UNA usa grids (`sys_objects_grid`, `sys_grid_fields`, `sys_grid_actions`) para exibir dados tabulares de forma organizada.
    *   A API \"Deeper\" fornecerá os dados para popular essas grids, respeitando filtros, paginação e ordenação, além de informar sobre as ações disponíveis.

## Fluxo Geral para Formulários:

1.  **Requisição da Definição do Formulário:** Cliente solicita a definição de um formulário específico (ex: formulário de \"adicionar pessoa\").
2.  **Resposta da API (Definição):** A API \"Deeper\" retorna uma estrutura JSON descrevendo o formulário:
    *   Atributos do formulário (ação, método - embora para API seja sempre POST/PUT para um endpoint).
    *   Lista de campos, cada um com: nome, tipo (texto, select, checkbox, textarea, etc.), legenda, valor padrão, regras de validação (requerido, min/max comprimento, padrão regex), opções (para selects/radios), visibilidade baseada em ACL.
3.  **Renderização pelo Cliente:** O cliente constrói o formulário dinamicamente com base na definição.
4.  **Submissão do Formulário:** Usuário preenche e submete o formulário.
5.  **Chamada à API (Submissão):** Cliente envia os dados do formulário (JSON) para um endpoint específico da API.
6.  **Processamento pela API:**
    *   Validação dos dados no backend com base nas regras definidas para o formulário.
    *   Se inválido, retorna erro 422 com detalhes.
    *   Se válido, executa a lógica de negócios (ex: criar/atualizar registro no banco de dados usando o Repositório apropriado).
    *   Retorna resposta de sucesso ou erro.

## Fluxo Geral para Grids:

1.  **Requisição da Configuração e Dados da Grid:** Cliente solicita dados para uma grid específica, possivelmente com parâmetros de paginação, ordenação e filtros.
2.  **Resposta da API:** A API \"Deeper\" retorna:
    *   Definição das colunas da grid (nome, título, largura, se é traduzível).
    *   Lista de ações disponíveis na grid (single, bulk, independent).
    *   Os dados paginados para a grid.
    *   Metadados de paginação.
3.  **Renderização pelo Cliente:** O cliente constrói a tabela/grid, exibe os dados e os controles (paginação, botões de ação, campos de filtro).

A implementação desses motores na API \"Deeper\" é crucial para permitir que o cliente não apenas visualize, mas também crie e modifique conteúdo.