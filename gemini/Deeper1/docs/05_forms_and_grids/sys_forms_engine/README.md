# Documentação Deeper: Motor de Formulários da API (`sys_forms_*`)

Este documento descreve como a API \"Deeper\" fornecerá as definições de formulários do UNA e processará suas submissões. O objetivo é permitir que um cliente remoto construa formulários dinamicamente e interaja com a lógica de negócios do backend.

## Tabelas Principais do UNA para Formulários:

1.  **`sys_objects_form`**:
    *   Define cada formulário no sistema.
    *   Campos chave: `object` (nome único do formulário, ex: `bx_persons_add`, `sys_login`), `module`, `title`, `action` (URL de submissão no UNA PHP), `form_attrs`, `submit_name`, `table` (tabela DB onde os dados são salvos), `key` (coluna PK da tabela), `uri` (para redirecionamento no UNA).

2.  **`sys_form_inputs`**:
    *   Define cada campo de entrada dentro de um formulário.
    *   Campos chave: `object` (FK para `sys_objects_form.object`), `module`, `name` (nome do campo), `value` (valor padrão), `values` (para selects, radios, checkboxes - pode ser chave para `sys_form_pre_lists`), `type` (text, textarea, select, checkbox, password, hidden, file, etc.), `caption_system`, `caption` (chave de tradução), `info`, `required`, `unique`, `checker_func` (validação PHP), `checker_params`, `checker_error` (chave de tradução), `db_pass` (como o valor é processado para DB, ex: Xss, DateUtc), `editable`, `deletable`.

3.  **`sys_form_display_inputs`**:
    *   Controla quais campos (`input_name`) de um formulário (`sys_form_inputs.object`) são visíveis em uma \"exibição\" (`display_name`) específica do formulário, e para quais níveis de ACL (`visible_for_levels`). As exibições são definidas em `sys_form_displays`.
    *   Ex: um formulário `bx_persons_add` pode ter uma exibição `bx_persons_add_profile` (para adicionar) e `bx_persons_edit_profile` (para editar), mostrando campos ligeiramente diferentes.

4.  **`sys_form_pre_lists` e `sys_form_pre_values`**:
    *   Listas pré-definidas de valores para campos do tipo `select`, `radio`, `checkboxes_set` (ex: lista de países, categorias). `sys_form_inputs.values` pode referenciar uma `sys_form_pre_lists.key`.

## Estratégia da API \"Deeper\" para Formulários:

### 1. Obtenção da Definição do Formulário:

A API fornecerá um endpoint para buscar a definição completa de um formulário, incluindo seus campos, atributos e valores pré-definidos, filtrados pela visibilidade do usuário.

**Módulo de Acesso a Dados (`Deeper.Forms.FormsRepo`):**

*   **`get_form_definition(form_object_name :: String.t(), form_display_name :: String.t() | nil, user_acl_level_id :: integer(), context_params :: map()) :: {:ok, form_def :: map()} | {:error, :not_found | any()}`**
    1.  Busca a definição do formulário de `sys_objects_form` usando `form_object_name`.
    2.  Busca todos os campos (`sys_form_inputs`) para este `form_object_name`.
    3.  Se `form_display_name` fornecido, filtra os campos com base em `sys_form_display_inputs` e `visible_for_levels` do usuário. Se não, assume uma exibição padrão ou todos os campos (com checagem de `visible_for_levels` nos próprios campos, se `sys_form_inputs` tiver tal coluna, o que não parece ser o caso diretamente, então `sys_form_display_inputs` é crucial).
    4.  Para cada campo:
        *   Traduz `caption` e `info` (usando `LocalizationRepo`).
        *   Se o tipo for `select`, `radio`, `checkboxes_set` e `values` for uma chave para `sys_form_pre_lists`, busca os `sys_form_pre_values` correspondentes e os traduz.
        *   Mapeia `checker_func`, `checker_params`, `required` para regras de validação que o cliente possa entender (ex: `required: true`, `minLength: 5`, `pattern: \"/regex/\"`).
        *   Substitui placeholders no `value` padrão usando `context_params` (ex: se editando um perfil, o valor padrão de um campo pode ser o valor atual do perfil).
    5.  Retorna uma estrutura JSON descrevendo o formulário e seus campos.

**Endpoint da API:**

*   **Endpoint:** `GET /api/v1/forms/{form_object_name}`
    *   Alternativa: `GET /api/v1/forms/{form_object_name}/display/{form_display_name}` (se as exibições forem chaveadas explicitamente).
*   **Path Parameter:** `form_object_name`.
*   **Query Parameters (Opcionais):**
    *   `display_name`: Qual exibição do formulário usar (se houver múltiplas).
    *   `context_id`: ID do item sendo editado (para pré-preencher valores).
    *   `lang`: Para traduções.
*   **Autenticação:** Requer JWT (para filtrar campos por `visible_for_levels` e para ACL da ação do formulário).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"form_object_name\": \"bx_persons_add_profile\",
        \"title\": \"Adicionar Novo Perfil\", // Traduzido
        \"action_endpoint\": \"/api/v1/data/bx_persons_data\", // Endpoint de submissão (exemplo)
        \"method\": \"POST\", // Ou PUT para edição
        \"fields\": [
          {
            \"name\": \"fullname\",
            \"type\": \"text\", // text, select, textarea, password, checkbox, radio, file, hidden
            \"label\": \"Nome Completo\", // Traduzido
            \"value\": \"\", // Valor padrão ou pré-preenchido
            \"placeholder\": \"Digite o nome completo\", // Pode vir de 'info'
            \"required\": true,
            \"validation_rules\": [ // Regras para o cliente e/ou backend
              {\"type\": \"minLength\", \"value\": 3, \"message\": \"Mínimo 3 caracteres.\"},
              {\"type\": \"maxLength\", \"value\": 255, \"message\": \"Máximo 255 caracteres.\"}
            ],
            \"db_pass\": \"XssHtml\" // Como o backend processará o valor
          },
          {
            \"name\": \"gender\",
            \"type\": \"select\",
            \"label\": \"Gênero\",
            \"value\": \"male\",
            \"options\": [
              {\"value\": \"male\", \"label\": \"Masculino\"},
              {\"value\": \"female\", \"label\": \"Feminino\"},
              {\"value\": \"other\", \"label\": \"Outro\"}
            ],
            \"required\": false
          }
          // ... outros campos ...
        ],
        \"submit_button_label\": \"Salvar Perfil\" // Traduzido
      }
    }
```

```sql
CREATE TABLE IF NOT EXISTS sys_objects_form (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL UNIQUE,
  module TEXT NOT NULL,
  title TEXT NOT NULL, -- Chave de tradução
  action TEXT NOT NULL, -- URL de submissão original do UNA PHP (para referência)
  form_attrs TEXT, -- Atributos HTML do form (JSON ou string serializada)
  submit_name TEXT NOT NULL, -- Name do botão submit
  \"table\" TEXT NOT NULL, -- Tabela DB alvo
  \"key\" TEXT NOT NULL, -- Coluna PK na tabela alvo
  uri TEXT, -- URI de redirecionamento no UNA PHP
  uri_title TEXT, -- Chave de tradução para o título do URI
  params TEXT, -- Parâmetros JSON para a classe do formulário PHP
  deletable INTEGER NOT NULL DEFAULT 1,
  active INTEGER NOT NULL DEFAULT 1, -- No schema original é 0
  parent_form TEXT DEFAULT '', -- Se herda de outro formulário
  override_class_name TEXT,
  override_class_file TEXT
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_form_inputs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL, -- FK para sys_objects_form.object
  module TEXT NOT NULL,
  name TEXT NOT NULL,
  value TEXT NOT NULL DEFAULT '', -- Valor padrão
  \"values\" TEXT NOT NULL DEFAULT '', -- Para selects, etc. (pode ser chave de sys_form_pre_lists ou JSON)
  checked INTEGER NOT NULL DEFAULT 0, -- Para checkboxes/radios
  type TEXT NOT NULL,
  caption_system TEXT NOT NULL, -- Chave de tradução (admin)
  caption TEXT NOT NULL, -- Chave de tradução (público)
  info TEXT, -- Chave de tradução para ajuda/info
  help TEXT, -- Chave de tradução para texto de ajuda mais longo
  icon TEXT,
  required INTEGER NOT NULL DEFAULT 0,
  unique_input INTEGER NOT NULL DEFAULT 0, -- Renomeado de 'unique'
  collapsed INTEGER NOT NULL DEFAULT 0,
  html INTEGER NOT NULL DEFAULT 0, -- Nível de HTML permitido
  privacy INTEGER NOT NULL DEFAULT 0, -- Se o campo tem controle de privacidade
  rateable TEXT DEFAULT '', -- Se o campo pode ser avaliado
  attrs TEXT, -- Atributos HTML do campo (JSON)
  attrs_tr TEXT, -- Atributos HTML da linha da tabela (TR) do campo
  attrs_wrapper TEXT, -- Atributos HTML do wrapper do campo
  checker_func TEXT, -- Nome da função de validação PHP
  checker_params TEXT, -- Parâmetros para checker_func (JSON)
  checker_error TEXT, -- Chave de tradução para erro de validação
  db_pass TEXT, -- Como processar o valor para o DB (Xss, DateUtc, etc.)
  db_params TEXT,
  editable INTEGER NOT NULL DEFAULT 1,
  deletable INTEGER NOT NULL DEFAULT 1,
  UNIQUE(object, name)
  -- FOREIGN KEY (object) REFERENCES sys_objects_form(object) ON DELETE CASCADE -- Opcional
);
```

### 2. Submissão de Formulário:

A API precisará de endpoints para receber os dados submetidos. Estes endpoints podem ser genéricos (ex: `POST /api/v1/data/{target_table}`) ou específicos por módulo/ação.

**Lógica no Controller da API e `FormsRepo`:**

1.  Recebe os dados JSON do formulário submetido.
2.  Identifica o `form_object_name` (pode ser parte da rota ou um campo nos dados).
3.  Busca a definição do formulário e seus campos (usando `FormsRepo.get_form_definition` ou uma versão interna).
4.  **Validação no Backend:**
    *   Para cada campo submetido, verifica contra `required`, `checker_func` (a lógica PHP precisaria ser portada/mapeada para Elixir), `checker_params`.
    *   Se houver erros de validação, retorna `422 Unprocessable Entity` com detalhes dos erros por campo.
5.  **Processamento `db_pass`:** Aplica as transformações especificadas em `sys_form_inputs.db_pass` (ex: limpar XSS, converter data para formato UTC).
6.  **Lógica de Negócios:**
    *   Determina a `table` e `key` de `sys_objects_form`.
    *   Chama o Repositório apropriado para o módulo/tabela para executar a operação de banco de dados (INSERT ou UPDATE). Ex: `Deeper.Content.PersonsRepo.create_person_data(processed_data)` ou `update_person_data(context_id, processed_data)`.
    *   A lógica de ACL para a ação de \"criar\" ou \"editar\" o recurso deve ser verificada antes.
7.  Retorna resposta de sucesso (ex: `201 Created` com o novo recurso, ou `200 OK` com o recurso atualizado).

**Endpoint de Submissão Genérico (Exemplo):**

*   **Endpoint:** `POST /api/v1/forms/{form_object_name}/submit`
    *   Ou `POST /api/v1/module/{module_name}/resource` (mais RESTful se mapeado para recursos)
*   **Corpo da Requisição (JSON):** Os dados do formulário `{ \"campo1\": \"valor1\", \"campo2\": \"valor2\" }`.
*   **Autenticação:** Requer JWT.
*   **Autorização:** Verifica ACL para a ação de criar/editar o recurso.

## Tabelas de Formulários (Esquema SQLite):

Os `CREATE TABLE` statements para `sys_objects_form`, `sys_form_inputs`, `sys_form_displays`, `sys_form_display_inputs`, `sys_form_pre_lists`, `sys_form_pre_values` precisarão ser definidos no `docs/00_core_concepts/database_schema_sqlite.md` e ter suas respectivas migrações.

**Exemplo `sys_objects_form` (SQLite):**

**Exemplo `sys_form_inputs` (SQLite):**

## Considerações:

*   **Validação:** A lógica das `checker_func` do UNA PHP precisará ser portada ou mapeada para validadores Elixir (ex: usando `Vex` ou validações customizadas). A API deve retornar mensagens de erro claras e traduzidas.
*   **Pré-preenchimento (Edição):** Ao buscar a definição de um formulário para edição (`context_id` fornecido), o `FormsRepo` precisará buscar os dados existentes do `context_id` na `table` e usá-los como `value` padrão para os campos.
*   **Upload de Arquivos:** Campos do tipo `file` exigirão tratamento especial (multipart/form-data) e integração com o sistema de gerenciamento de arquivos (`06_file_management/`).
*   **Campos Condicionais/Dinâmicos:** Se o UNA suporta campos que aparecem/mudam com base em outros campos, essa lógica precisará ser replicada no cliente ou simplificada.

Este sistema de formulários permitirá uma grande flexibilidade na entrada de dados pelo cliente, espelhando a capacidade dinâmica do UNA.