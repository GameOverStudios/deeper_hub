# Documentação Deeper: API para Motor de Menus (`sys_menu_*`)

Este documento descreve como a API \"Deeper\" fornecerá os dados para que o cliente remoto possa renderizar os menus definidos no sistema UNA. Menus são usados para navegação principal, submenus de página, menus de ação em blocos, etc.

## Tabelas Principais do UNA:

1.  **`sys_menu_sets`**:
    *   Define um \"conjunto\" ou grupo de menus, geralmente associado a um módulo.
    *   Campos: `set_name` (nome único do conjunto), `module`, `title`, `deletable`.

2.  **`sys_objects_menu`**:
    *   Define um \"objeto de menu\" específico que pode ser renderizado. Cada objeto pertence a um `set_name`.
    *   Campos: `id`, `object` (nome único do menu), `title`, `set_name`, `module`, `template_id` (para o template de renderização no UNA PHP), `override_class_name`, `override_class_file`.

3.  **`sys_menu_items`**:
    *   Define os itens individuais dentro de um objeto de menu.
    *   Campos: `id`, `parent_id` (para submenus), `set_name`, `module`, `name` (nome do item), `title_system` (chave de tradução admin), `title` (chave de tradução público), `link`, `onclick`, `target`, `icon`, `addon` (para badges/contadores), `visible_for_levels`, `hidden_on`, `order`.

## Estratégia da API \"Deeper\" para Menus:

A API \"Deeper\" fornecerá um endpoint para buscar os itens de um objeto de menu específico, já processados para o cliente (ex: com links resolvidos, visibilidade verificada).

### Módulo de Acesso a Dados (`Deeper.PageEngine.MenusRepo` ou `Deeper.SystemCore.MenusRepo`):

**Funções Principais e SQLs Esperados:**

*   **`get_menu_items(menu_object_name :: String.t(), user_acl_level_id :: integer(), current_path_params :: map()) :: {:ok, list(menu_item_map :: map())} | {:error, :not_found | any()}`**
    *   Busca todos os itens ativos e visíveis para um determinado `menu_object_name` e para o `user_acl_level_id` fornecido.
    *   `current_path_params`: Um mapa de parâmetros da URL atual ou do contexto da página, que pode ser usado para substituir placeholders nos links dos itens de menu (ex: `{profile_id}`).
    *   **Passo 1: Buscar o `set_name` do objeto de menu.**
        *   SQL: `SELECT set_name FROM sys_objects_menu WHERE object = ? LIMIT 1;`
        *   Se não encontrado, retorna `{:error, :not_found}`.
    *   **Passo 2: Buscar os itens do menu para o `set_name` e `module` (se aplicável).**
        *   SQL:

```json
        {
          \"data\": {
            \"menu_object_name\": \"bx_persons_profile_actions\",
            \"items\": [
              {
                \"id\": 1,
                \"name\": \"add_friend\",
                \"title\": \"Adicionar Amigo\", // Traduzido
                \"link\": \"/api/v1/connections/friend_request/123\", // Link processado
                \"icon\": \"fas user-plus\",
                \"target\": \"_self\",
                \"addon_value\": null, // Ou um contador, ex: 5
                \"children\": [] // Para sub-itens
              },
              {
                \"id\": 2,
                \"name\": \"send_message\",
                \"title\": \"Enviar Mensagem\",
                \"link\": \"/messages/compose/123\", // Pode ser um link do cliente
                \"icon\": \"fas envelope\",
                \"target\": \"_blank\",
                \"addon_value\": null,
                \"children\": [
                  {
                    \"id\": 3,
                    \"name\": \"report_profile\",
                    \"title\": \"Denunciar Perfil\",
                    \"link\": \"/report/profile/123\",
                    \"icon\": \"fas flag\",
                    \"target\": \"_self\",
                    \"addon_value\": null,
                    \"children\": []
                  }
                ]
              }
              // ... outros itens ...
            ]
          }
        }
```

```sql
            SELECT id, parent_id, name, title, link, onclick, target, icon, addon, visible_for_levels, hidden_on, \"order\"
            FROM sys_menu_items
            WHERE set_name = ? AND active = 1 -- E possivelmente `module` se os itens forem específicos do módulo do objeto de menu
            ORDER BY parent_id, \"order\";
```

```sql
CREATE TABLE IF NOT EXISTS sys_objects_menu (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL UNIQUE, -- Nome único do menu
  title TEXT NOT NULL, -- Chave de tradução
  set_name TEXT NOT NULL, -- FK (lógica) para sys_menu_sets.set_name
  module TEXT NOT NULL,
  template_id INTEGER NOT NULL, -- Refere-se a sys_menu_templates.id
  -- persistent INTEGER DEFAULT 0,
  deletable INTEGER NOT NULL DEFAULT 1,
  active INTEGER NOT NULL DEFAULT 1,
  override_class_name TEXT,
  override_class_file TEXT
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_menu_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  parent_id INTEGER NOT NULL DEFAULT 0,
  set_name TEXT NOT NULL,
  module TEXT NOT NULL,
  name TEXT NOT NULL,
  title_system TEXT NOT NULL, -- Chave de tradução (admin)
  title TEXT NOT NULL, -- Chave de tradução (público)
  link TEXT NOT NULL,
  onclick TEXT,
  target TEXT,
  icon TEXT,
  addon TEXT, -- Pode ser HTML ou definição de serviço PHP serializada
  -- addon_cache INTEGER DEFAULT 0,
  -- markers TEXT,
  -- submenu_object TEXT, -- Se este item abre outro menu
  -- submenu_popup INTEGER DEFAULT 0,
  visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
  -- visibility_custom TEXT,
  hidden_on TEXT, -- 'xs', 'sm', etc.
  -- hidden_on_cxt TEXT, hidden_on_pt INTEGER, hidden_on_col INTEGER,
  -- primary INTEGER DEFAULT 0, collapsed INTEGER DEFAULT 0,
  active INTEGER NOT NULL DEFAULT 1,
  -- active_api INTEGER DEFAULT 0,
  copyable INTEGER NOT NULL DEFAULT 1,
  editable INTEGER NOT NULL DEFAULT 1,
  \"order\" INTEGER NOT NULL DEFAULT 0
  -- UNIQUE(set_name, module, name) -- Pode ser necessário dependendo da unicidade no UNA
);
CREATE INDEX IF NOT EXISTS idx_sys_menu_items_set_name_active ON sys_menu_items(set_name, active);
CREATE INDEX IF NOT EXISTS idx_sys_menu_items_parent_id ON sys_menu_items(parent_id);
```

            (O `module` aqui pode ser `sys_menu_items.module` ou `sys_objects_menu.module` dependendo da lógica do UNA).
    *   **Passo 3: Processar os itens em Elixir:**
        *   **Filtrar por `visible_for_levels`**: Remover itens que o `user_acl_level_id` não tem permissão para ver. (A coluna `visible_for_levels` é uma máscara de bits; a verificação é `(item_visible_for_levels BAND (1 <<< (user_acl_level_id - 1))) > 0` ou similar, dependendo de como o UNA armazena e calcula isso).
        *   **Filtrar por `hidden_on`**: Lógica para verificar se o item deve ser oculto com base no contexto (ex: 'mobile', 'desktop'). O cliente pode receber essa informação e decidir.
        *   **Resolver `title`**: Se `title` for uma chave de tradução, buscar a string traduzida (requer `LocalizationRepo` e o idioma do usuário).
        *   **Processar `link`**: Substituir placeholders no link (ex: `/profile/{profile_id}/view` -> `/profile/123/view`) usando `current_path_params`.
        *   **Processar `addon`**: Se `addon` for uma chamada de serviço PHP serializada para buscar um contador (comum no UNA), a API \"Deeper\" precisará de lógica para:
            1.  Parsear a definição do serviço.
            2.  Chamar a função correspondente no Repo do módulo relevante para obter o valor do contador.
            3.  Incluir o valor do contador no item de menu.
        *   **Construir Hierarquia (Submenus):** Organizar os itens em uma estrutura aninhada se `parent_id` for usado.
    *   Retorna uma lista de mapas, onde cada mapa representa um item de menu processado e pronto para o cliente.

### Endpoints da API (`/api/v1/menus`):

*   **Obter Itens de um Menu:**
    *   **Endpoint:** `GET /api/v1/menus/{menu_object_name}`
    *   **Path Parameter:** `menu_object_name` (o `object` de `sys_objects_menu`).
    *   **Query Parameters (Opcionais):**
        *   `lang`: Código do idioma para traduções (ex: `en`, `pt-BR`). Se não fornecido, usa um padrão ou o idioma do usuário (se autenticado).
        *   `context_param_[key]`: Parâmetros de contexto para substituição em links (ex: `context_param_profile_id=123`).
    *   **Descrição:** Retorna a lista de itens processados para o objeto de menu especificado.
    *   **Autenticação:** Requer JWT se o menu tiver itens com `visible_for_levels` restritivos ou se os `addon`s exigirem contexto do usuário. Pode ser público para menus gerais.
    *   **Resposta de Sucesso (200 OK):**

    *   **Respostas de Erro:** `404 Not Found` (se `menu_object_name` não existir), `401 Unauthorized`/`403 Forbidden` (se o acesso ao menu ou seus itens for restrito).

## Tabelas de Menu (Esquema SQLite):

Os `CREATE TABLE` statements para `sys_menu_sets`, `sys_objects_menu`, e `sys_menu_items` precisarão ser definidos no `docs/00_core_concepts/database_schema_sqlite.md` e ter suas respectivas migrações Elixir.

**Exemplo `sys_objects_menu` (SQLite):**

**Exemplo `sys_menu_items` (SQLite):**

## Desafios e Considerações:

*   **Processamento de `addon`:** Similar aos serviços de blocos, se `sys_menu_items.addon` contiver uma definição de serviço PHP para buscar um contador (ex: número de mensagens não lidas), a API \"Deeper\" precisará de uma lógica para parsear isso e chamar a função correspondente no Repo do módulo relevante.
*   **Visibilidade e ACL:** A filtragem de itens com base em `visible_for_levels` e `hidden_on` é crucial e deve ser feita no backend para não expor itens indevidos ao cliente.
*   **Links Dinâmicos:** A substituição de placeholders nos links (ex: `{profile_id}`) precisa de um mecanismo robusto, utilizando os parâmetros de contexto fornecidos na requisição da API.
*   **Traduções:** A API deve lidar com a tradução dos `title` dos itens de menu.
*   **Hierarquia:** A construção da estrutura aninhada de menu/submenu precisa ser feita corretamente no backend antes de enviar ao cliente.

Com esta API, o cliente poderá renderizar menus dinâmicos e contextuais, respeitando as permissões e configurações do sistema.