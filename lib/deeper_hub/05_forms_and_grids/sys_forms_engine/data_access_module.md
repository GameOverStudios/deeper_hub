# Documentação Deeper: Módulo de Acesso a Dados para Formulários (`FormsRepo`)

Este documento descreve o módulo Elixir `Deeper.Forms.FormsRepo` (ou similar), responsável por encapsular a lógica de consulta e manipulação de dados para o sistema de formulários dinâmicos do UNA.

Ele interage com `sys_objects_form` (para definições de formulário), `sys_form_inputs` (para campos), `sys_form_displays` e `sys_form_display_inputs` (para controlar a exibição dos campos), e `sys_form_pre_lists` com `sys_form_pre_values` (para listas de seleção).

**Localização do Código:** `lib/deeper/forms/forms_repo.ex`

## Funções Principais (Exemplos):

### 1. Obter Definição de um Formulário

*   **`get_form_definition(form_object_name :: String.t(), display_name :: String.t() | nil, user_level_id :: integer() | nil, context_params :: map() | nil) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca a definição completa de um formulário, incluindo seus campos, atributos e valores de listas pré-definidas.
    *   **Argumentos:**
        *   `form_object_name`: Nome do objeto de formulário (de `sys_objects_form.object`).
        *   `display_name`: (Opcional) Nome da exibição do formulário (de `sys_form_displays.display_name`). Se `nil`, usa uma exibição padrão ou todos os campos.
        *   `user_level_id`: (Opcional) Para filtrar campos por `sys_form_display_inputs.visible_for_levels`.
        *   `context_params`: (Opcional) Para preencher valores iniciais do formulário (ex: dados de uma entidade para um formulário de edição).
    *   **Retorno:** `{:ok, form_data_map}`. Exemplo da estrutura:

```sql
        SELECT \"Value\", LKey -- (e LKey2, Data se necessário)
        FROM sys_form_pre_values
        WHERE \"Key\" = ?
        ORDER BY \"Order\";
```

```elixir
        %{
          object: \"bx_persons_add_profile\",
          title: \"Adicionar Novo Perfil\",
          action_intent: \"/api/v1/persons\", // Mapeado da sys_objects_form.action para uma rota API
          method: \"POST\", // Inferido ou configurado
          table_target: \"bx_persons_data\", // sys_objects_form.\"table\"
          key_column: \"id\", // sys_objects_form.\"key\"
          form_attrs: %{\"class\" => \"my-form\"}, // Parseado de sys_objects_form.form_attrs
          submit_label: \"Criar Perfil\", // Traduzido de sys_objects_form.submit_name
          fields: [
            %{
              name: \"fullname\",
              type: \"text\", // sys_form_inputs.type
              label: \"Nome Completo\", // Traduzido de caption_system ou caption
              value: \"Valor Padrão ou de Contexto\", // sys_form_inputs.value ou de context_params
              required: true,
              info: \"Seu nome como aparecerá no perfil.\",
              attrs: %{\"placeholder\" => \"Digite seu nome completo\"},
              validation_rules: %{required: true, min_length: 3}, // Derivado de checker_func/params
              error_message_key: \"_bx_persons_err_fullname_required\" // De checker_error
            },
            %{
              name: \"gender\",
              type: \"select\",
              label: \"Gênero\",
              options: [
                %{value: \"male\", label: \"Masculino\"},
                %{value: \"female\", label: \"Feminino\"}
              ], // De sys_form_pre_values para a lista associada em sys_form_inputs.\"values\"
              required: false
            }
            // ... outros campos
          ]
        }
```

    *   **Lógica Interna Detalhada:**
        1.  **Buscar `sys_objects_form`:**
            *   SQL: `SELECT * FROM sys_objects_form WHERE object = ? AND active = 1 LIMIT 1;`
            *   Se não encontrado, `{:error, :not_found}`.
        2.  **Buscar Campos (`sys_form_inputs`):**
            *   SQL: `SELECT * FROM sys_form_inputs WHERE object = ? ORDER BY id;` (a ordem final virá de `sys_form_display_inputs`).
        3.  **Filtrar e Ordenar Campos por Exibição (se `display_name` fornecido):**
            *   Buscar `sys_form_display_inputs` para o `display_name` (e o `form_object_name` implícito).
            *   SQL: `SELECT input_name, visible_for_levels, active, \"order\" FROM sys_form_display_inputs WHERE display_name = ? ORDER BY \"order\";`
            *   Filtrar os campos obtidos no passo 2 com base nos `input_name` de `sys_form_display_inputs`, aplicar `visible_for_levels` (vs `user_level_id`) e `active` status da exibição. Reordenar.
            *   Se `display_name` não fornecido, usar todos os campos de `sys_form_inputs`, aplicando `visible_for_levels` diretamente da tabela `sys_form_inputs` (se ela tiver essa coluna, o dump original não tem, mas `sys_form_display_inputs` tem).
        4.  **Para cada campo selecionado:**
            a.  **Traduzir `caption`, `info`, `help`, `checker_error`** usando `LocalizationRepo` se forem chaves de linguagem.
            b.  **Preencher `value`:** Usar `input.value` (padrão) ou sobrescrever com valor de `context_params` se o nome do campo corresponder.
            c.  **Processar `input.\"values\"` (para `select`, `radio_set`, `checkbox_set`):**
                *   Se `input.\"values\"` for uma chave de `sys_form_pre_lists` (ex: `@Country`):
                    *   Chamar `get_predefined_list_values(list_key, language_code)` (função abaixo) para obter as opções.
                *   Se `input.\"values\"` for uma string JSON/serializada, parseá-la.
            d.  **Interpretar `checker_func` e `checker_params`** para `validation_rules` (ex: se `checker_func == \"Length\"`, `checker_params` pode ser `{\"min\":3, \"max\":100\"}`).
            e.  Parsear `attrs`, `attrs_tr`, `attrs_wrapper` (se forem JSON/serializados).
        5.  Montar o mapa final do formulário.

### 2. Obter Valores de uma Lista Pré-definida

*   **`get_predefined_list_values(list_key :: String.t(), language_code :: String.t() | nil) :: {:ok, list(map())} | {:error, :list_not_found | any()}`**
    *   Busca os valores para uma lista de `sys_form_pre_lists`.
    *   **Argumentos:**
        *   `list_key`: A chave da lista (de `sys_form_pre_lists.\"key\"`).
        *   `language_code`: (Opcional) Para tradução das legendas dos itens.
    *   **Retorno:** `{:ok, [%{value: \"US\", label: \"Estados Unidos\"}, %{value: \"BR\", label: \"Brasil\"}, ...]}`
    *   **SQL:**

    *   **Lógica:** Buscar os valores e, para cada um, usar `LocalizationRepo` para traduzir `LKey` (e `LKey2`) para obter o `label`.

### 3. Processar Submissão de Formulário

*   **`submit_form_data(form_object_name :: String.t(), submitted_data :: map(), user_profile_id :: integer() | nil) :: {:ok, %{record_id: any(), message: String.t()}} | {:error, %{field_errors: map(), global_errors: list(String.t())} | any()}`**
    *   Valida e salva os dados submetidos de um formulário.
    *   **Argumentos:**
        *   `submitted_data`: Mapa com `{field_name => value}`.
    *   **Retorno:**
        *   Sucesso: `{:ok, %{record_id: new_or_updated_id, message: \"Dados salvos.\"}}`.
        *   Erro de validação: `{:error, %{field_errors: %{\"fieldname\" => \"Erro aqui\"}, global_errors: [\"Erro geral\"]}}`.
    *   **Lógica Interna Detalhada:**
        1.  Chamar `get_form_definition(form_object_name, display_name_if_known, user_level_id)` para obter a estrutura do formulário, incluindo campos, suas tabelas de destino (`form_def.table_target`, `form_def.key_column`), e regras de validação/processamento.
        2.  **Validação:** Para cada campo na definição do formulário:
            a.  Verificar `required`.
            b.  Aplicar validadores derivados de `checker_func` e `checker_params` aos valores em `submitted_data`. (Ex: `validate_length(value, min, max)`, `validate_email(value)`). Esta lógica de validação precisa ser implementada em Elixir.
            c.  Coletar todos os erros de validação em `field_errors`.
            d.  Se houver erros, retornar `{:error, %{field_errors: field_errors}}`.
        3.  **Processamento de Dados (`db_pass`):** Para cada campo validado:
            a.  Aplicar transformações baseadas em `db_pass` (ex: `Xss` para limpar HTML, `DateTime` para converter formato de data/hora para armazenamento, `Tags` para processar tags). Esta lógica precisa ser implementada em Elixir.
            b.  Coletar os dados processados em `data_to_save`.
        4.  **Determinar Operação (INSERT ou UPDATE):**
            *   Se o formulário é de edição (ex: `form_object_name` contém \"edit\" ou `context_params` na chamada de definição incluía um ID), ou se `submitted_data` contém um valor para `form_def.key_column`.
        5.  **Executar Operação no Banco de Dados (em uma transação):**
            a.  Construir a query SQL `INSERT INTO #{form_def.table_target} (...) VALUES (...)` ou `UPDATE #{form_def.table_target} SET ... WHERE #{form_def.key_column} = ?`.
            b.  Executar a query com `data_to_save`.
            c.  Obter o `record_id` (ID do registro inserido/atualizado).
        6.  **(Opcional) Disparar Alertas/Eventos do UNA:** O UNA dispara alertas após certas ações de formulário. A API \"Deeper\" pode precisar de um mecanismo similar se essa funcionalidade for crítica.
        7.  Retornar `{:ok, %{record_id: record_id, ...}}`.

### Considerações:

*   **Validação e Processamento (`checker_func`, `db_pass`):** Reimplementar a lógica exata das funções PHP do UNA em Elixir é um dos maiores desafios. Uma biblioteca de validação Elixir (como `Vex` ou `Norm`) pode ser usada, e as regras do UNA mapeadas para ela. Funções de processamento (`db_pass`) precisarão de equivalentes em Elixir.
*   **Segurança:** Cuidado extremo com a construção de SQL dinâmico, especialmente para `INSERT`/`UPDATE`. Usar placeholders (`?`) com `Repo.query/execute` é fundamental. Nomes de tabelas e colunas vindos da configuração (`sys_objects_form`) devem ser validados contra uma lista permitida ou usados com muita cautela.
*   **Upload de Arquivos:** Campos do tipo `file` exigirão um fluxo de upload separado (provavelmente `multipart/form-data`) que interage com o sistema de arquivos (`06_file_management/`). O `FormsRepo` receberia o ID/referência do arquivo já salvo para associar ao registro.
*   **Campos `input_set` (Campos Repetíveis):** O UNA permite conjuntos de campos que podem ser adicionados dinamicamente pelo usuário. A API precisará de uma forma de receber esses dados (ex: como uma lista de mapas) e o `FormsRepo` de processá-los (geralmente salvando em uma tabela separada ligada ao registro principal).