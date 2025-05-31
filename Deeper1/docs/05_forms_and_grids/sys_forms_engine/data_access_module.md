# Documentação Deeper: Módulo de Acesso a Dados para Motor de Formulários (`Deeper.Forms.FormsRepo`)

Este documento descreve o módulo Elixir `Deeper.Forms.FormsRepo`. Ele é responsável por interagir com as tabelas do banco de dados relacionadas ao sistema de formulários do UNA (`sys_objects_form`, `sys_form_inputs`, `sys_form_displays`, `sys_form_display_inputs`, `sys_form_pre_lists`, `sys_form_pre_values`).

O `FormsRepo` fornecerá as funções necessárias para buscar definições completas de formulários, incluindo seus campos, opções de select/radio, e aplicar filtros de visibilidade baseados no nível de ACL do usuário.

## Responsabilidades Principais:

*   Buscar a definição de um `sys_objects_form` específico.
*   Buscar todos os `sys_form_inputs` associados a um formulário.
*   Filtrar e ordenar campos com base em uma `sys_form_displays` e `sys_form_display_inputs`, respeitando `visible_for_levels`.
*   Buscar valores de `sys_form_pre_values` para campos que usam listas pré-definidas.
*   Auxiliar na validação de dados submetidos (embora a lógica de validação principal possa residir em um serviço ou no controller).

## Funções Auxiliares Chave (Internas):

*   **`map_row_to_form_field(input_row :: map(), prelist_values :: map() | nil, lang_code :: String.t()) :: map()`**
    *   Converte uma linha de `sys_form_inputs` (e opcionalmente `prelist_values`) para a estrutura de campo da API.
    *   Traduz `caption`, `info`, `help`, `checker_error` usando `LocalizationRepo.get_string/3`.
    *   Se `input_row[\"values\"]` for uma chave para `prelist_values`, formata as opções.
    *   Mapeia `checker_func`, `checker_params`, `required` para regras de validação da API.
    *   Converte `db_pass` para um identificador que o cliente/backend entenda.

*   **`fetch_prelist_values(prelist_key :: String.t(), lang_code :: String.t()) :: {:ok, list(map())} | {:error, any()}`**
    *   Busca e traduz valores de `sys_form_pre_values` para uma dada `prelist_key`.
    *   SQL: `SELECT Value, LKey, Data FROM sys_form_pre_values WHERE \"Key\" = ? ORDER BY \"Order\";`
    *   Traduz `LKey` para a legenda.

## Funções Públicas Principais e Lógica SQL:

*   **`get_form_definition(form_object_name :: String.t(), display_name :: String.t() | nil, user_acl_level_id :: integer(), lang_code :: String.t(), context_data :: map() \\\\ %{}) :: {:ok, form_definition :: map()} | {:error, :not_found | :forbidden | any()}`**
    *   `context_data`: Usado para pré-preencher valores (ex: ao editar um registro, `%{ \"fieldname\": \"current_value\" }`).
    1.  **Busca Definição do Formulário (`sys_objects_form`):**
        *   SQL: `SELECT object, module, title, action, form_attrs, submit_name, \"table\" AS target_table, \"key\" AS target_key, params FROM sys_objects_form WHERE object = ? AND active = 1 LIMIT 1;`
        *   Se não encontrado, `{:error, :not_found}`.
        *   `form_config = resultado`. Traduz `form_config[\"title\"]`.
    2.  **Busca Campos do Formulário (`sys_form_inputs`):**
        *   SQL: `SELECT * FROM sys_form_inputs WHERE object = ? ORDER BY id;` (A ordem pode ser controlada por `sys_form_display_inputs.\"order\"` posteriormente).
        *   `all_form_inputs = lista_de_mapas_de_inputs`.
    3.  **Determina Campos para a Exibição e Filtra por ACL:**
        *   `fields_to_render = []`.
        *   Se `display_name` fornecido:
            *   Busca `sys_form_displays`: `SELECT * FROM sys_form_displays WHERE object = ? AND display_name = ? LIMIT 1;`
            *   Se não encontrado, pode usar uma exibição padrão ou erro.
            *   Busca `sys_form_display_inputs`: `SELECT input_name, visible_for_levels, \"order\" FROM sys_form_display_inputs WHERE display_name = ? AND active = 1 ORDER BY \"order\";` (usando o `display_name` da tabela `sys_form_displays` que está atrelado ao `form_object_name`).
            *   Para cada `display_input` na ordem:
                *   Verifica `display_input[\"visible_for_levels\"]` contra `user_acl_level_id`. Se não visível, pula.
                *   Encontra o `input_config` correspondente em `all_form_inputs` usando `display_input[\"input_name\"]`.
                *   Adiciona à `fields_to_render`.
        *   Else (`display_name` não fornecido - lógica de exibição padrão ou todos os campos):
            *   Itera sobre `all_form_inputs`. Assume-se que `sys_form_inputs` por si só não tem `visible_for_levels`. Se uma exibição é sempre necessária para aplicar ACL em campos, este caso pode precisar sempre de um `display_name` padrão. (O UNA geralmente usa `sys_form_display_inputs` para visibilidade).
            *   *Alternativa:* Se a intenção é obter *todos* os campos definidos para um formulário, independente de uma \"exibição\" e ACL (ex: para um admin construindo a exibição), então a filtragem de ACL é pulada. Para a API do cliente, a filtragem ACL é essencial.
    4.  **Processa cada Campo em `fields_to_render`:**
        *   Para cada `input_config` em `fields_to_render`:
            *   `field_data = %{}`
            *   `field_data = Map.put(field_data, :name, input_config[\"name\"])`
            *   `field_data = Map.put(field_data, :type, input_config[\"type\"])`
            *   `field_data = Map.put(field_data, :label, LocalizationRepo.get_string(lang_code, input_config[\"caption\"]))`
            *   `field_data = Map.put(field_data, :info, LocalizationRepo.get_string(lang_code, input_config[\"info\"]))` (se houver)
            *   `field_data = Map.put(field_data, :required, input_config[\"required\"] == 1)`
            *   `field_data = Map.put(field_data, :db_pass, input_config[\"db_pass\"])`
            *   **Valor Padrão/Contextual:**
                *   `default_value = Map.get(context_data, input_config[\"name\"], input_config[\"value\"])`
                *   `field_data = Map.put(field_data, :value, default_value)`
            *   **Opções para Selects/Radios/Checkboxes:**
                *   Se `input_config[\"type\"]` é `select`, `radio`, `checkboxes_set`:
                    *   Se `input_config[\"values\"]` começa com `#`, é uma chave para `sys_form_pre_lists`.
                        *   `{:ok, options_list} = fetch_prelist_values(String.trim_leading(input_config[\"values\"], \"#\"), lang_code)`
                        *   `field_data = Map.put(field_data, :options, options_list)` (onde `options_list` é `[%{value: \"v\", label: \"TraduzidoL\"}, ...]`)
                    *   Else (se `input_config[\"values\"]` for um array JSON ou CSV, parsear diretamente).
            *   **Regras de Validação:**
                *   `validation_rules = []`
                *   Se `input_config[\"required\"] == 1`, adiciona `%{type: \"required\", message: LocalizationRepo.get_string(lang_code, \"_sys_form_txt_required_field\")}`.
                *   Mapeia `input_config[\"checker_func\"]` e `input_config[\"checker_params\"]` para regras conhecidas (ex: `MinLength`, `MaxLength`, `Email`, `PasswordPolicy`). O `checker_error` traduzido seria a mensagem.
                    *   Ex: Se `checker_func == \"Length\"`, `checker_params = \"3,255\"`, adiciona regras de min/max length.
                *   `field_data = Map.put(field_data, :validation_rules, validation_rules)`
            *   Adiciona `field_data` à lista final de campos.
    5.  Constrói a resposta final:

```elixir
        form_api_definition = %{
          form_object_name: form_config[\"object\"],
          title: LocalizationRepo.get_string(lang_code, form_config[\"title\"]),
          # O endpoint de submissão pode ser construído ou vir de uma configuração da API
          action_endpoint: \"/api/v1/forms/#{form_config[\"object\"]}/submit\", # Exemplo
          method: determine_method(form_object_name), # POST para add, PUT para edit
          fields: processed_fields_list,
          submit_button_label: LocalizationRepo.get_string(lang_code, \"_submit\") # Ou de form_config
        }
        {:ok, form_api_definition}
```

*   **`get_prelist_options(prelist_key :: String.t(), lang_code :: String.t()) :: {:ok, list(map())} | {:error, :not_found | any()}`**
    *   Função pública para buscar apenas uma lista pré-definida, se necessário separadamente.
    *   Usa `fetch_prelist_values/2`.

## Lógica de Validação de Submissão (pode ser um módulo separado `Deeper.Forms.FormValidator` ou parte do serviço que lida com a submissão):

*   **`validate_submission(form_object_name :: String.t(), display_name :: String.t() | nil, submitted_data :: map(), user_acl_level_id :: integer(), lang_code :: String.t()) :: {:ok,  processed_data :: map()} | {:error, validation_errors :: map()}`**
    1.  Chama `get_form_definition` para obter a estrutura e regras dos campos visíveis.
    2.  Para cada campo na definição:
        *   Verifica `required` e se o campo está presente em `submitted_data`.
        *   Aplica as validações mapeadas de `checker_func` e `checker_params` ao valor submetido.
        *   Coleta todos os erros de validação, usando `checker_error` (traduzido) como mensagem.
    3.  Se houver erros, retorna `{:error, %{\"field_name\" => [\"Error message 1\"], ...}}`.
    4.  Se tudo OK, processa os valores com base em `db_pass` (ex: sanitizar HTML, converter data/hora) e retorna `{:ok, processed_data_for_db}`.

## Considerações:

*   **Mapeamento de `checker_func` e `db_pass`:** A lógica PHP contida nas `checker_func` e nas transformações `db_pass` do UNA precisará ser replicada ou mapeada para funcionalidades equivalentes em Elixir. Esta é uma parte complexa.
    *   Exemplos de `db_pass`: `Xss`, `XssHtml`, `Date`, `DateTimeUtc`, `Float`, `Int`, `Preg`, ` খালি`.
    *   Exemplos de `checker_func`: `Avail`, `Date`, `Length`, `Preg`, `UniqueUser`, `UniqueProfileName`.
*   **Traduções:** Muitas chaves de tradução (`caption`, `info`, `checker_error`, legendas de `sys_form_pre_values`) precisam ser resolvidas.
*   **Performance:** Buscar a definição de um formulário grande com muitas opções de select pode envolver várias queries. Cachear definições de formulário ou partes delas (como `sys_form_pre_values`) pode ser benéfico.
*   **Upload de Arquivos (`type: \"file\"`):** O `FormsRepo` apenas define o campo. O endpoint da API de submissão e o controller precisarão lidar com `multipart/form-data` e interagir com o `FilesRepo` (`06_file_management/`).

Este `FormsRepo` é fundamental para a interatividade da API \"Deeper\", permitindo que os clientes construam interfaces de entrada de dados dinâmicas e validadas.