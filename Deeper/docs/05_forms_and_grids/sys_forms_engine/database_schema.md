# Documentação Deeper: Esquema do BD para Motor de Formulários (SQLite)

Define `CREATE TABLE` para as tabelas do motor de formulários do UNA.

## Tabela: `sys_objects_form`

```sql
CREATE TABLE IF NOT EXISTS sys_objects_form (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL UNIQUE, -- Nome do objeto de formulário (ex: 'bx_persons_add')
  module TEXT NOT NULL,
  title TEXT NOT NULL, -- Chave de tradução para o título do formulário
  action TEXT NOT NULL, -- URL de submissão no UNA PHP. Para Deeper, pode ser informativo ou mapeado para uma rota API.
  form_attrs TEXT, -- Atributos HTML para a tag <form> (JSON ou string serializada)
  submit_name TEXT NOT NULL, -- Nome do botão de submit
  table_name TEXT NOT NULL, -- Tabela do DB onde os dados são salvos (informativo para Deeper)
  key_column TEXT NOT NULL, -- Coluna chave na table_name (informativo)
  uri_column TEXT, -- Coluna para o URI/slug (informativo)
  uri_title_column TEXT, -- Coluna para o título usado no URI (informativo)
  params TEXT, -- Parâmetros adicionais de configuração (JSON ou serializado)
  deletable INTEGER NOT NULL DEFAULT 1,
  active INTEGER NOT NULL DEFAULT 1, -- No UNA era 0 por default, mas 1 faz mais sentido
  parent_form TEXT, -- Se este formulário herda de outro
  override_class_name TEXT,
  override_class_file TEXT
);
CREATE INDEX IF NOT EXISTS idx_sof_module ON sys_objects_form(module);
```

```sql
CREATE TABLE IF NOT EXISTS sys_form_inputs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL, -- FK (lógica) para sys_objects_form.object
  module TEXT NOT NULL,
  name TEXT NOT NULL, -- Nome do campo (ex: 'fullname', 'email')
  value TEXT NOT NULL DEFAULT '', -- Valor padrão (pode ser string vazia)
  values_list TEXT, -- Chave para sys_form_pre_lists OU lista de valores (ex: #!Value1\\nValue2)
  checked INTEGER NOT NULL DEFAULT 0, -- Para checkboxes/radios, se está checado por padrão
  type TEXT NOT NULL CHECK(type IN ( -- Lista expandida de tipos comuns
    'text', 'textarea', 'password', 'number', 'range', 'date', 'datetime_local', 'time', 'email', 'url', 'tel',
    'checkbox', 'radio', 'select', 'select_multiple', 'file', 'hidden', 'submit', 'button', 'reset',
    'block_header', 'block_end', 'fieldset_start', 'fieldset_end', 'div_start', 'div_end',
    'input_set', 'custom', 'captcha', 'value', 'slider', 'doublerange', -- Tipos UNA
    'button_group', 'location', 'recurring', 'checkbox_set'
  )),
  caption_system TEXT, -- Chave de tradução para legenda interna
  caption TEXT, -- Chave de tradução para legenda exibida
  info TEXT, -- Chave de tradução para texto de ajuda/dica
  help TEXT, -- Chave de tradução para texto de ajuda mais longo
  icon TEXT,
  required INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
  unique_input INTEGER NOT NULL DEFAULT 0, -- SQLite não gosta de 'unique'
  collapsed INTEGER NOT NULL DEFAULT 0,
  html INTEGER NOT NULL DEFAULT 0, -- 0: texto puro, 1: HTML básico, 2: HTML completo (para 'custom')
  privacy INTEGER NOT NULL DEFAULT 0, -- ID de um objeto sys_objects_privacy para este campo
  rateable TEXT, -- Se o campo pode ser avaliado (objeto de votação)
  attrs TEXT, -- Atributos HTML adicionais para o input (JSON ou string)
  attrs_tr TEXT, -- Atributos para a <tr> da linha do campo (JSON ou string)
  attrs_wrapper TEXT, -- Atributos para o wrapper do campo (JSON ou string)
  checker_func TEXT, -- Nome da função de validação no UNA PHP
  checker_params TEXT, -- Parâmetros para checker_func (JSON ou string)
  checker_error TEXT, -- Chave de tradução para mensagem de erro de validação
  db_pass TEXT, -- Como o valor é passado para o DB (ex: Xss, Int, Date)
  db_params TEXT, -- Parâmetros para db_pass
  editable INTEGER NOT NULL DEFAULT 1,
  deletable INTEGER NOT NULL DEFAULT 1
  -- Não há FK direta para 'object' aqui para simplificar, mas a aplicação garante a relação.
);
CREATE INDEX IF NOT EXISTS idx_sfi_object_name ON sys_form_inputs(object, name);
CREATE INDEX IF NOT EXISTS idx_sfi_module ON sys_form_inputs(module);
```

```sql
CREATE TABLE IF NOT EXISTS sys_form_displays (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  display_name TEXT NOT NULL, -- Nome único do display (ex: 'bx_persons_add', 'bx_persons_edit_profile')
  module TEXT NOT NULL,
  object TEXT NOT NULL, -- FK (lógica) para sys_objects_form.object
  title TEXT NOT NULL, -- Chave de tradução para o título do display (pode ser o mesmo do form)
  view_mode INTEGER NOT NULL DEFAULT 0 -- 0 para formulário completo, 1 para apenas visualização
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_sfd_object_display ON sys_form_displays(object, display_name);
```

```sql
CREATE TABLE IF NOT EXISTS sys_form_display_inputs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  display_name TEXT NOT NULL, -- FK (lógica) para sys_form_displays.display_name
  input_name TEXT NOT NULL, -- FK (lógica) para sys_form_inputs.name (dentro do mesmo form.object)
  visible_for_levels INTEGER NOT NULL DEFAULT 2147483647, -- Bitmask ACL
  active INTEGER NOT NULL DEFAULT 1, -- No UNA era 0, mas 1 faz mais sentido se está na tabela
  \"order\" INTEGER NOT NULL DEFAULT 0
  -- Não há FKs diretas para simplificar, mas a aplicação garante as relações
  -- display_name + object_do_form (de sys_form_displays) + input_name formam uma chave lógica.
);
CREATE INDEX IF NOT EXISTS idx_sfdi_display_input ON sys_form_display_inputs(display_name, input_name);
-- Um índice UNIQUE seria (display_name, input_name) assumindo que display_name é globalmente único,
-- ou (object_do_form, display_name, input_name) se display_name for único por formulário.
-- O original UNA é (display_name, input_name).
```

```sql
CREATE TABLE IF NOT EXISTS sys_form_pre_lists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  module TEXT NOT NULL DEFAULT '',
  key_name TEXT NOT NULL UNIQUE, -- Chave da lista (ex: '_sys_countries', 'my_custom_list') (no UNA é `key`)
  title TEXT NOT NULL, -- Chave de tradução para o título da lista
  use_for_sets INTEGER NOT NULL DEFAULT 1, -- Se pode ser usado para tipo 'checkbox_set' ou 'input_set'
  extendable INTEGER NOT NULL DEFAULT 1 -- Se usuários podem adicionar valores (lógica de app)
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_form_pre_values (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  list_key_name TEXT NOT NULL, -- FK (lógica) para sys_form_pre_lists.key_name (no UNA é `Key`)
  value TEXT NOT NULL, -- O valor real a ser salvo no DB
  \"order\" INTEGER NOT NULL DEFAULT 0,
  lkey TEXT NOT NULL, -- Chave de tradução para o label exibido ao usuário
  lkey2 TEXT, -- Chave de tradução secundária (ex: para descrição)
  data TEXT -- Dados adicionais (JSON ou string)
  -- FOREIGN KEY (list_key_name) REFERENCES sys_form_pre_lists(key_name) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_sfpv_list_key_order ON sys_form_pre_values(list_key_name, \"order\");
```

## Tabela: `sys_form_inputs`

## Tabela: `sys_form_displays`

*   Um formulário (`sys_objects_form`) pode ter múltiplos \"displays\", cada um mostrando um subconjunto ou ordenação diferente dos campos.

## Tabela: `sys_form_display_inputs`

## Tabela: `sys_form_pre_lists` (Listas de Valores Pré-definidos)

## Tabela: `sys_form_pre_values` (Valores para Listas Pré-definidas)

*   **Relação `sys_form_inputs.values_list` com `sys_form_pre_lists.key_name`**: Se `sys_form_inputs.values_list` não começar com `#`, assume-se que é uma chave para `sys_form_pre_lists`. Se começar com `#` (ex: `#!Val1\\nVal2`), os valores são parseados diretamente da string.