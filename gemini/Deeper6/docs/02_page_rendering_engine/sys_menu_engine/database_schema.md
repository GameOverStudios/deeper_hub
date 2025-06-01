# Documentação Deeper: Esquema do Banco de Dados para Motor de Menus (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas que compõem o motor de menus do UNA, adaptadas para o projeto \"Deeper\": `sys_menu_sets`, `sys_menu_templates`, `sys_objects_menu`, e `sys_menu_items`.

## Tabela: `sys_menu_sets`

Armazena a definição de conjuntos de menus. Um \"objeto de menu\" (`sys_objects_menu`) geralmente aponta para um `set_name` aqui.

```sql
CREATE TABLE IF NOT EXISTS sys_menu_sets (
  set_name TEXT PRIMARY KEY, -- Nome único do conjunto de menus
  module TEXT NOT NULL, -- Módulo que registrou este conjunto
  title TEXT NOT NULL, -- Título descritivo do conjunto (pode ser uma chave de tradução)
  deletable INTEGER NOT NULL DEFAULT 1 -- 0 para não deletável, 1 para deletável
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_menu_templates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  template TEXT NOT NULL UNIQUE, -- Caminho ou identificador do arquivo de template
  title TEXT NOT NULL, -- Título descritivo do template
  visible INTEGER NOT NULL DEFAULT 1 -- Se o template está disponível para uso
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_objects_menu (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL UNIQUE, -- Nome único do objeto de menu (ex: sys_site_main_menu)
  title TEXT NOT NULL, -- Título do objeto de menu (pode ser uma chave de tradução)
  set_name TEXT NOT NULL, -- FK para sys_menu_sets.set_name
  module TEXT NOT NULL, -- Módulo que registrou este objeto
  template_id INTEGER NOT NULL, -- FK para sys_menu_templates.id
  -- persistent INTEGER NOT NULL DEFAULT 0, -- Se o cache do menu é persistente
  deletable INTEGER NOT NULL DEFAULT 1,
  active INTEGER NOT NULL DEFAULT 1, -- Se o objeto de menu está ativo
  -- override_class_name TEXT, -- Para customização no PHP UNA
  -- override_class_file TEXT,
  FOREIGN KEY (set_name) REFERENCES sys_menu_sets(set_name) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (template_id) REFERENCES sys_menu_templates(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_sys_objects_menu_set_name ON sys_objects_menu(set_name);
CREATE INDEX IF NOT EXISTS idx_sys_objects_menu_module ON sys_objects_menu(module);
```

```sql
CREATE TABLE IF NOT EXISTS sys_menu_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  parent_id INTEGER NOT NULL DEFAULT 0, -- Para submenus, referencia o sys_menu_items.id do item pai
  set_name TEXT NOT NULL, -- FK para sys_menu_sets.set_name, indica a qual conjunto este item pertence
  module TEXT NOT NULL, -- Módulo que adicionou este item
  name TEXT NOT NULL, -- Nome programático do item (único dentro do set_name)
  title_system TEXT, -- Chave de linguagem para o título (usado pelo sistema)
  title TEXT NOT NULL, -- Título a ser exibido (pode ser a chave de linguagem ou o texto direto)
  link TEXT NOT NULL, -- URL ou caminho para onde o item aponta
  onclick TEXT, -- Código JavaScript para o evento onclick
  target TEXT, -- Atributo target do link (ex: _blank)
  icon TEXT, -- Classe CSS do ícone ou caminho da imagem
  addon TEXT, -- Conteúdo adicional (ex: contador de notificações), pode ser JSON ou HTML
  -- addon_cache INTEGER NOT NULL DEFAULT 0,
  -- markers TEXT, -- Para marcadores visuais no item
  submenu_object TEXT, -- Se este item abre um submenu, nome do sys_objects_menu do submenu
  submenu_popup INTEGER NOT NULL DEFAULT 0, -- Se o submenu é um popup
  visible_for_levels INTEGER NOT NULL DEFAULT 2147483647, -- Bitmask de níveis ACL que podem ver este item
  -- visibility_custom TEXT, -- Lógica customizada de visibilidade no PHP UNA
  hidden_on TEXT, -- Condições de ocultação baseadas em dispositivo/resolução (ex: \"xs,sm\")
  -- hidden_on_cxt TEXT,
  -- hidden_on_pt INTEGER,
  -- hidden_on_col INTEGER,
  -- primary INTEGER NOT NULL DEFAULT 0, -- Se é um item primário/destacado
  -- collapsed INTEGER NOT NULL DEFAULT 0,
  active INTEGER NOT NULL DEFAULT 1, -- Se o item está ativo
  -- active_api INTEGER NOT NULL DEFAULT 0, -- Se está ativo para API no UNA
  -- copyable INTEGER NOT NULL DEFAULT 1,
  -- editable INTEGER NOT NULL DEFAULT 1,
  \"order\" INTEGER NOT NULL, -- Ordem de exibição do item dentro do seu nível/pai
  FOREIGN KEY (set_name) REFERENCES sys_menu_sets(set_name) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sys_menu_items_set_name_parent_id ON sys_menu_items(set_name, parent_id);
CREATE INDEX IF NOT EXISTS idx_sys_menu_items_set_name_active_order ON sys_menu_items(set_name, active, \"order\");
CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_menu_items_set_name_name ON sys_menu_items(set_name, name);
```

*   **`set_name`**: Identificador único do conjunto de menus (ex: `sys_header_profile`, `bx_persons_view_submenu`).
*   **`module`**: Nome do módulo UNA que é \"dono\" deste conjunto.
*   **`title`**: Título legível do conjunto, frequentemente uma chave de linguagem para internacionalização.
*   **`deletable`**: Flag indicando se o conjunto pode ser removido (geralmente para conjuntos customizados).

## Tabela: `sys_menu_templates`

Define os diferentes templates visuais que podem ser aplicados a um menu. No contexto da API \"Deeper\", esta tabela pode ser menos relevante se o cliente for totalmente responsável pela renderização, mas é incluída para completude do esquema UNA.

*   **`id`**: Chave primária.
*   **`template`**: Identificador do template (ex: `menu_vertical.html`, `menu_buttons.html`).
*   **`title`**: Título legível do template.
*   **`visible`**: Se o template está ativo/disponível para seleção.

## Tabela: `sys_objects_menu`

Define os \"objetos de menu\" concretos que são usados nas páginas e blocos. Cada objeto de menu especifica qual conjunto de itens de menu (`set_name`) e qual template (`template_id`) usar.

*   **`id`**: Chave primária.
*   **`object`**: Nome único e programático do objeto de menu (ex: `sys_main_menu`, `bx_persons_profile_actions`).
*   **`title`**: Título legível do objeto, frequentemente uma chave de linguagem.
*   **`set_name`**: Referencia `sys_menu_sets` para determinar qual conjunto de itens (`sys_menu_items`) este objeto utilizará.
*   **`module`**: Módulo que registrou/gerencia este objeto de menu.
*   **`template_id`**: Referencia `sys_menu_templates` para o template visual (relevância reduzida para a API \"Deeper\" se o cliente renderiza).
*   **`deletable`, `active`**: Flags de status.

## Tabela: `sys_menu_items`

Contém os itens individuais de cada menu, associados a um `set_name`.

*   **`id`**: Chave primária.
*   **`parent_id`**: Para construir hierarquias de menu (submenus). `0` para itens de nível superior.
*   **`set_name`**: Identifica a qual conjunto de menus (definido em `sys_menu_sets`) este item pertence.
*   **`module`**: Módulo que contribuiu com este item.
*   **`name`**: Identificador único do item dentro do seu `set_name`.
*   **`title_system`, `title`**: Chave de linguagem para o título e/ou o título literal. A API precisará resolver isso para o idioma do usuário.
*   **`link`**: O URL de destino do item.
*   **`onclick`, `target`, `icon`, `addon`**: Atributos para a renderização do item. O `addon` pode precisar ser processado pela API se for dinâmico (ex: contagem de mensagens).
*   **`submenu_object`**: Se este item tem um submenu, este campo armazena o nome do `sys_objects_menu` que define esse submenu.
*   **`visible_for_levels`**: Uma bitmask que representa os níveis de ACL (`sys_acl_levels`) que têm permissão para ver este item. A API precisará filtrar itens com base no nível do usuário autenticado.
*   **`hidden_on`**: Indica em quais tamanhos de tela/dispositivos o item deve ser ocultado (lógica para o cliente).
*   **`active`**: Se o item de menu está ativo e deve ser exibido.
*   **`order`**: Define a ordem de classificação dos itens dentro do mesmo `parent_id` e `set_name`.

### Chaves Estrangeiras e Integridade:

*   As chaves estrangeiras definidas ajudam a manter a integridade referencial.
*   `ON DELETE CASCADE` para `sys_menu_items.set_name` significa que se um conjunto de menu for deletado, todos os seus itens também serão.
*   `ON DELETE RESTRICT` para `sys_objects_menu` significa que um `set_name` ou `template_id` não pode ser deletado se estiver sendo usado por um objeto de menu.

**Próximo Passo:** Definir os módulos de migração Elixir para criar estas quatro tabelas.