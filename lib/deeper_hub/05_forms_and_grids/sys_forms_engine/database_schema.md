# Documentação Deeper: Esquema do BD para Motor de Formulários (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas do UNA que compõem o sistema de formulários dinâmicos.

## Tabela: `sys_objects_form` (Definição de Formulários)

```sql
CREATE TABLE IF NOT EXISTS sys_objects_form (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  object TEXT NOT NULL UNIQUE, -- Nome único do objeto de formulário, ex: 'bx_persons_add'
  module TEXT NOT NULL,
  title TEXT NOT NULL, -- Título do formulário
  action TEXT NOT NULL, -- URL de submissão no UNA PHP (para API Deeper, indica a intenção)
  form_attrs TEXT, -- Atributos HTML para a tag <form> (JSON ou string serializada)
  submit_name TEXT NOT NULL, -- Nome do botão de submit (pode ser chave de linguagem)
  \"table\" TEXT NOT NULL, -- Tabela do BD onde os dados são salvos
  \"key\" TEXT NOT NULL, -- Coluna da chave primária na 'table'
  uri TEXT, -- Coluna para URI/slug na 'table' (se houver)
  uri_title TEXT, -- Coluna para o título usado para gerar o URI (se houver)
  params TEXT, -- Parâmetros adicionais de configuração (JSON ou string serializada)
  deletable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
  active INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
  parent_form TEXT, -- Nome de um objeto de formulário pai (para formulários aninhados/multi-etapas)
  override_class_name TEXT,
  override_class_file TEXT
  -- FK para module (sys_modules.name)
);
CREATE INDEX IF NOT EXISTS idx_sys_objects_form_object ON sys_objects_form(object);
CREATE INDEX IF NOT EXISTS idx_sys_objects_form_module ON sys_objects_form(module);
```

```sql
CREATE TABLE IF NOT EXISTS sys_form_inputs (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  object TEXT NOT NULL, -- FK para sys_objects_form.object (a qual formulário este campo pertence)
  module TEXT NOT NULL,
  name TEXT NOT NULL, -- Nome do campo (usado como nome do input HTML e coluna da DB se não houver db_pass)
  value TEXT, -- Valor padrão do campo. No UNA é VARCHAR(255)
  \"values\" TEXT, -- Valores para campos de múltipla escolha (checkbox, radio, select) - pode ser chave de sys_form_pre_lists ou JSON. No UNA é TEXT
  checked INTEGER NOT NULL DEFAULT 0, -- 0 ou 1 (para checkboxes/radios)
  type TEXT NOT NULL CHECK(type IN ( -- Alguns tipos comuns do UNA
    'text', 'textarea', 'password', 'select', 'select_multiple', 'checkbox', 'radio_set',
    'checkbox_set', 'hidden', 'file', 'button', 'reset', 'submit', 'image', 'button_group',
    'datepicker', 'datetime', 'number', 'email', 'url', 'slider', 'doublerange',
    'location', 'input_set', 'textarea_html', 'captcha', 'value', 'block_header', 'fieldset_start', 'fieldset_end', 'alert'
    -- ... e outros tipos customizados ou específicos de módulos
  )),
  caption_system TEXT, -- Chave de linguagem para a legenda do campo
  caption TEXT, -- Legenda do campo (pode ser o valor traduzido)
  info TEXT, -- Texto informativo/dica exibido abaixo do campo
  help TEXT, -- Texto de ajuda mais detalhado (ex: tooltip)
  icon TEXT, -- Ícone para o campo
  required INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
  \"unique\" INTEGER NOT NULL DEFAULT 0, -- 0 ou 1 (se o valor deve ser único na tabela de destino)
  collapsed INTEGER NOT NULL DEFAULT 0, -- 0 ou 1 (se o campo/fieldset está colapsado por padrão)
  html INTEGER NOT NULL DEFAULT 0, -- Nível de HTML permitido (para campos como textarea_html)
  privacy INTEGER NOT NULL DEFAULT 0, -- ID do grupo de privacidade para este campo (se campos individuais tiverem privacidade)
  rateable TEXT, -- Se o campo pode ser avaliado (nome do objeto de voto/score)
  attrs TEXT, -- Atributos HTML adicionais para o input (JSON ou string serializada)
  attrs_tr TEXT, -- Atributos para a linha da tabela (<tr>) que envolve o campo
  attrs_wrapper TEXT, -- Atributos para o wrapper do campo
  checker_func TEXT, -- Nome da função de validação no UNA PHP
  checker_params TEXT, -- Parâmetros para a checker_func (JSON ou string serializada)
  checker_error TEXT, -- Chave de linguagem para a mensagem de erro de validação
  db_pass TEXT, -- Nome da função de processamento antes de salvar no DB (ex: Xss, DateTime)
  db_params TEXT, -- Parâmetros para a db_pass
  editable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
  deletable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
  FOREIGN KEY (object) REFERENCES sys_objects_form(object) ON DELETE CASCADE ON UPDATE CASCADE
  -- FK para module (sys_modules.name)
);
CREATE INDEX IF NOT EXISTS idx_sys_form_inputs_object_name ON sys_form_inputs(object, name);
CREATE INDEX IF NOT EXISTS idx_sys_form_inputs_module ON sys_form_inputs(module);
-- Um índice UNIQUE(object, name) seria mais apropriado se 'name' é único por formulário.
CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_form_inputs_object_name_unique ON sys_form_inputs(object, name);
```

```sql
CREATE TABLE IF NOT EXISTS sys_form_displays (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  display_name TEXT NOT NULL, -- Nome da exibição, ex: 'bx_persons_add', 'bx_persons_edit'
  module TEXT NOT NULL,
  object TEXT NOT NULL, -- FK para sys_objects_form.object
  title TEXT NOT NULL, -- Título da exibição (pode ser chave de linguagem)
  view_mode INTEGER NOT NULL DEFAULT 0, -- 0 para HTML, 1 para JSON (no UNA)
  FOREIGN KEY (object) REFERENCES sys_objects_form(object) ON DELETE CASCADE ON UPDATE CASCADE
  -- FK para module (sys_modules.name)
);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_form_displays_object_display_name ON sys_form_displays(object, display_name);
CREATE INDEX IF NOT EXISTS idx_sys_form_displays_module ON sys_form_displays(module);
```

```sql
CREATE TABLE IF NOT EXISTS sys_form_display_inputs (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  display_name TEXT NOT NULL, -- FK (conceitual) para sys_form_displays.display_name (ligado com object de sys_form_inputs)
  input_name TEXT NOT NULL, -- FK (conceitual) para sys_form_inputs.name
  visible_for_levels INTEGER NOT NULL DEFAULT 2147483647, -- Bitmask ACL
  active INTEGER NOT NULL DEFAULT 0, -- 0 ou 1 (se o campo está ativo nesta exibição)
  \"order\" INTEGER NOT NULL
  -- Para FKs reais aqui, precisaríamos de IDs de sys_form_displays e sys_form_inputs
  -- ou usar uma chave composta (object_form, display_name, input_name)
  -- FOREIGN KEY (display_name) REFERENCES sys_form_displays(display_name), -- Não é PK única
  -- FOREIGN KEY (input_name) REFERENCES sys_form_inputs(name) -- Não é PK única
  -- Uma forma de ligar seria (object_form_de_inputs, display_name, input_name) com object_form sendo parte da FK
);
-- Um índice para buscar inputs de um display (considerando o form_object implícito)
CREATE INDEX IF NOT EXISTS idx_sys_form_display_inputs_display_order ON sys_form_display_inputs(display_name, \"order\");
-- Para garantir unicidade do input em um display:
CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_form_display_inputs_display_input ON sys_form_display_inputs(display_name, input_name);
```

```sql
CREATE TABLE IF NOT EXISTS sys_form_pre_lists (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  module TEXT NOT NULL,
  \"key\" TEXT NOT NULL UNIQUE, -- Chave única da lista, ex: 'bx_persons_genders', 'Country'
  title TEXT NOT NULL, -- Título da lista (pode ser chave de linguagem)
  use_for_sets INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se pode ser usado em campos checkbox_set/radio_set)
  extendable INTEGER NOT NULL DEFAULT 1 -- 0 ou 1 (se usuários podem adicionar valores - mais para admin)
  -- FK para module (sys_modules.name)
);
CREATE INDEX IF NOT EXISTS idx_sys_form_pre_lists_key ON sys_form_pre_lists(\"key\");
CREATE INDEX IF NOT EXISTS idx_sys_form_pre_lists_module ON sys_form_pre_lists(module);
```

```sql
CREATE TABLE IF NOT EXISTS sys_form_pre_values (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  \"Key\" TEXT NOT NULL, -- Chave da lista (FK para sys_form_pre_lists.\"key\")
  \"Value\" TEXT NOT NULL, -- Valor real do item da lista
  \"Order\" INTEGER NOT NULL DEFAULT 0,
  LKey TEXT NOT NULL, -- Chave de linguagem para a exibição do item
  LKey2 TEXT, -- Segunda chave de linguagem (opcional)
  Data TEXT, -- Dados adicionais (JSON ou string serializada)
  FOREIGN KEY (\"Key\") REFERENCES sys_form_pre_lists(\"key\") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_sys_form_pre_values_key_order ON sys_form_pre_values(\"Key\", \"Order\");
```

*   Define cada instância de formulário.
*   `\"table\"` e `\"key\"` são cruciais para saber onde salvar os dados.

## Tabela: `sys_form_inputs` (Definição de Campos de Formulário)

*   Define cada campo de um formulário.
*   `\"values\"` e `\"unique\"` estão entre aspas.

## Tabela: `sys_form_displays` (Definição de Exibições de Formulário)

*   Define diferentes \"versões\" ou contextos de um formulário.

## Tabela: `sys_form_display_inputs` (Campos por Exibição)

*   Controla quais campos de `sys_form_inputs` aparecem em qual `sys_form_displays` e em que ordem.
*   A ligação com `sys_form_displays` e `sys_form_inputs` no UNA é feita pelos nomes (`display_name`, `input_name`) dentro do contexto do `object` (formulário).

## Tabela: `sys_form_pre_lists` (Listas de Valores Pré-Definidos)

*   Define nomes de listas de valores (ex: para selects, radios).

## Tabela: `sys_form_pre_values` (Valores das Listas Pré-Definidas)

*   Contém os pares chave/valor e legendas para cada item de uma lista pré-definida.
*   Colunas `Key`, `Value`, `Order` estão entre aspas.

### Chaves Estrangeiras e Integridade:
*   Definidas onde aplicável. A relação entre `sys_form_display_inputs` e as outras tabelas é mais complexa devido ao uso de nomes como chaves.
*   Lembre-se de `PRAGMA foreign_keys = ON;` para SQLite.