# Documentação Deeper: Motor de Formulários Dinâmicos (`sys_forms_engine`)

Este documento detalha a API \"Deeper\" para fornecer as definições de formulários dinâmicos, baseando-se nas tabelas `sys_objects_form`, `sys_form_inputs`, `sys_form_displays`, `sys_form_pre_lists`, `sys_form_pre_values` do UNA.

O objetivo é permitir que um cliente remoto obtenha a estrutura completa de um formulário e seus campos para poder renderizá-lo e submetê-lo.

## Abordagem \"Deeper\" para Formulários:

1.  **Definição do Formulário:** A API retornará a estrutura do formulário, incluindo:
    *   Atributos do formulário (ex: método, ação – que será um endpoint da API \"Deeper\").
    *   Lista de campos (`sys_form_inputs`), cada um com:
        *   Nome, tipo (text, select, checkbox, textarea, file, etc.).
        *   Legenda (traduzida ou chave de tradução).
        *   Valor padrão.
        *   Opções para selects/radios (de `sys_form_pre_values` ou do campo `values`).
        *   Regras de validação (requerido, min/max length, pattern – a API as descreverá, o cliente as implementará).
        *   Visibilidade (baseada em ACL).
        *   Privacidade do campo.
2.  **Submissão do Formulário:**
    *   O cliente construirá o formulário e o submeterá para um endpoint da API \"Deeper\" (geralmente o endpoint de criação ou atualização do recurso correspondente, ex: `POST /articles`).
    *   O backend \"Deeper\" receberá os dados do formulário em JSON, validará e processará a ação. A lógica de validação do UNA (`checker_func`, `db_pass`) precisará ser portada ou reimplementada em Elixir.

## Responsabilidades Principais da API do Motor de Formulários:

*   Dado um nome de objeto de formulário (ex: `bx_persons_add`), retornar sua definição completa.
*   (Indiretamente) Definir como as submissões de formulários serão tratadas pelos endpoints de recursos.

## Estrutura da Documentação para Formulários:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   `CREATE TABLE` para `sys_objects_form`, `sys_form_inputs`, `sys_form_displays`, `sys_form_display_inputs`, `sys_form_pre_lists`, `sys_form_pre_values`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Módulos de migração.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.FormsEngine.FormRepo`.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica o endpoint para buscar definições de formulários (ex: `GET /forms/{form_object_name}`).

## Considerações de Design:

*   **Validação:** O UNA tem um sistema de validação (`checker_func`, `checker_params`, `checker_error`). A API \"Deeper\" deve descrever essas regras para que o cliente possa implementar validação no frontend. A validação final e autoritativa sempre ocorrerá no backend Elixir ao receber a submissão.
*   **Tipos de Campo:** A API deve mapear os tipos de campo do UNA (`sys_form_inputs.type`) para tipos que o cliente possa entender e renderizar (ex: \"text\", \"select\", \"checkbox\", \"date\", \"file\", \"textarea\", \"password\", \"number\", \"hidden\", \"custom_html_block\").
*   **Valores Pré-definidos (`sys_form_pre_lists`, `sys_form_pre_values`):** Para campos `select`, `radio`, `checkbox_set`, a API deve buscar e incluir as opções de `sys_form_pre_values` associadas à lista (key) especificada no campo.
*   **Visibilidade de Campo (`sys_form_display_inputs.visible_for_levels`):** O `FormRepo` aplicará essa lógica e só retornará campos visíveis para o nível do usuário atual.
*   **Privacidade de Campo (`sys_form_inputs_privacy`):** Se um campo tem configurações de privacidade para quem pode vê-lo ou editá-lo, isso precisa ser considerado, embora seja mais complexo para a API de *definição* do formulário.
*   **Upload de Arquivos:** Campos do tipo \"file\" exigirão um tratamento especial. A API de definição do formulário indicará o campo. O cliente fará o upload para um endpoint de arquivos separado (de `06_file_management`), que retornará um ID/referência do arquivo. Esse ID será então incluído na submissão principal do formulário.