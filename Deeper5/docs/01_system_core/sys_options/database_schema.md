# Documentação Deeper: Esquema do Banco de Dados para Configurações (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas do sistema de configurações do UNA: `sys_options_types`, `sys_options_categories`, e `sys_options`. As tabelas de \"mixes\" (`sys_options_mixes`, `sys_options_mixes2options`) são omitidas nesta fase inicial de API de leitura.

## Tabela: `sys_options_types`

```sql
CREATE TABLE IF NOT EXISTS sys_options_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  \"group\" TEXT NOT NULL, -- Agrupamento lógico, ex: 'general', 'modules'
  name TEXT NOT NULL UNIQUE, -- Nome programático do tipo, ex: 'system_general', 'bx_persons_settings'
  caption TEXT NOT NULL, -- Chave de tradução para o título do tipo
  icon TEXT, -- Nome/classe do ícone
  \"order\" INTEGER DEFAULT 0
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_options_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type_id INTEGER NOT NULL, -- FK para sys_options_types.id
  name TEXT NOT NULL UNIQUE, -- Nome programático da categoria, ex: 'site_info', 'performance'
  caption TEXT NOT NULL, -- Chave de tradução para o título da categoria
  hidden INTEGER NOT NULL DEFAULT 0, -- 0 para visível, 1 para oculta
  \"order\" INTEGER DEFAULT 0,
  FOREIGN KEY (type_id) REFERENCES sys_options_types(id) ON DELETE CASCADE ON UPDATE CASCADE
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_options (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER NOT NULL, -- FK para sys_options_categories.id
  name TEXT NOT NULL UNIQUE, -- Nome programático da opção, ex: 'site_title', 'bx_persons_per_page'
  caption TEXT NOT NULL, -- Chave de tradução para o título da opção
  info TEXT, -- Chave de tradução para informação/dica adicional
  value TEXT NOT NULL, -- O valor da configuração, armazenado como texto
  type TEXT NOT NULL DEFAULT 'digit' CHECK(type IN (
    'value', 'digit', 'text', 'code', 'checkbox', 'select',
    'combobox', 'file', 'image', 'list', 'rlist', 'rgb', 'rgba', 'datetime'
  )), -- Tipo de controle/dado
  extra TEXT, -- Valores para 'select', 'list', 'rlist' (ex: LKey1=Value1\\nLKey2=Value2)
  \"check\" TEXT, -- Nome de uma função de validação (lógica portada/interpretada)
  check_params TEXT, -- Parâmetros para a função de validação
  check_error TEXT, -- Chave de tradução para a mensagem de erro de validação
  \"order\" INTEGER DEFAULT 0,
  FOREIGN KEY (category_id) REFERENCES sys_options_categories(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sys_options_category_id ON sys_options(category_id);
```

*   Define os grandes agrupamentos de configurações.

## Tabela: `sys_options_categories`

*   Define subcategorias dentro de um `sys_options_types`.

## Tabela: `sys_options`

*   A tabela principal contendo cada configuração individual.
*   **`value`**: É armazenado como `TEXT`. A lógica da API/backend precisará converter para o tipo apropriado (inteiro para 'digit', booleano para 'checkbox' onde 'on' é true, etc.).
*   **`type`**: Indica como o valor deve ser interpretado e, no UNA Studio, qual tipo de controle de formulário usar.
*   **`extra`**: Para tipos como `select` ou `list`, armazena as opções disponíveis, geralmente em um formato de string delimitada.
*   **`check`, `check_params`, `check_error`**: Relacionados à validação no UNA Studio. Para a API de leitura, são informativos, mas para a API de administração, a lógica de validação precisaria ser portada/replicada.