# Documentação Deeper: Motor de Menus (`sys_menu_engine`)

Este documento detalha como a API \"Deeper\" fornecerá os dados necessários para que um cliente remoto possa construir e renderizar os menus dinâmicos do sistema UNA. O foco é em fornecer a estrutura hierárquica de um menu específico, seus itens, sub-itens, links e atributos.

A API de **administração** para criar e configurar conjuntos de menus, objetos de menu e itens de menu será detalhada em `07_studio_admin_api/menu_admin_api.md` (a ser criada ou como parte do `page_builder_admin_api.md`).

## Responsabilidades Principais da API do Motor de Menus:

*   Dado um identificador de objeto de menu (ex: `bx_persons_main_menu`), retornar:
    *   Informações sobre o objeto de menu (título, template visual associado).
    *   Uma lista hierárquica de itens de menu, cada um com:
        *   Título (traduzido ou chave de tradução).
        *   Link (URL).
        *   Comportamento de clique (`onclick`).
        *   Alvo (`target`).
        *   Ícone.
        *   Addon de texto/HTML.
        *   Marcadores (para badges, etc.).
        *   Submenu associado (se houver, referenciando outro objeto de menu).
        *   Visibilidade baseada em níveis de ACL.

## Componentes do Banco de Dados UNA para Menus:

*   **`sys_menu_sets`**: Agrupa menus por um \"nome de conjunto\" (ex: `sys_account_notifications`, `bx_persons`).
    *   Campos importantes: `set_name`, `module`, `title`.
*   **`sys_menu_templates`**: Define os diferentes templates visuais para a renderização de menus.
    *   Campos importantes: `id`, `template` (nome do arquivo), `title`.
*   **`sys_objects_menu`**: Define cada instância de menu no sistema. É o \"objeto\" que será requisitado pela API.
    *   Campos importantes: `id`, `object` (nome único do menu, ex: `bx_persons_main_menu`), `title`, `set_name` (FK para `sys_menu_sets.set_name`), `module`, `template_id` (FK para `sys_menu_templates.id`), `active`.
*   **`sys_menu_items`**: Define cada item individual dentro de um menu (identificado por `set_name`).
    *   Campos importantes: `id`, `parent_id` (para hierarquia), `set_name`, `module`, `name` (nome do item), `title_system`, `title` (chave de tradução), `link`, `onclick`, `target`, `icon`, `addon`, `addon_cache`, `markers`, `submenu_object` (referencia outro `sys_objects_menu.object`), `visible_for_levels`, `active`.

## Esquema do Banco de Dados (SQLite - Tabelas de Menu)

As definições `CREATE TABLE` para `sys_menu_sets`, `sys_menu_templates`, `sys_objects_menu`, e `sys_menu_items` serão detalhadas no arquivo `database_schema.md` dentro desta pasta.

## Módulos de Acesso a Dados (`data_access_modules.md`)

Descreverá o `Deeper.PageEngine.MenuRepo` (ou similar) que encapsula as queries SQL.
*   Funções para buscar um objeto de menu e todos os seus itens ativos e visíveis para o usuário atual.
*   Lógica para construir a estrutura hierárquica dos itens de menu.

## Endpoints da API (`api_endpoints.md`)

Especificará o endpoint principal (ex: `GET /api/v1/menus/{menu_object_name}`) para obter a definição completa do menu.

## Abordagem da API \"Deeper\":

A API retornará uma estrutura JSON hierárquica representando o menu. O cliente será responsável por:
1.  Interpretar esta estrutura.
2.  Renderizar o menu e seus itens (incluindo submenus) usando seus próprios componentes de UI e estilos.
3.  Aplicar a lógica de `onclick` e `target` aos links.
4.  Resolver e exibir ícones e addons.
5.  Potencialmente buscar dados para `markers` (badges) se eles indicarem contagens dinâmicas (ex: número de novas mensagens).

A API \"Deeper\" aplicará as verificações de `visible_for_levels` e `active` no lado do servidor, retornando apenas os itens de menu que o usuário atual tem permissão para ver.