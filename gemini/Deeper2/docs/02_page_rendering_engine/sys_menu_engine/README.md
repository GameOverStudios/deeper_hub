# Documentação Deeper: Motor de Menus (`sys_menu_engine`)

Esta seção da API \"Deeper\" detalha como o cliente remoto pode obter a estrutura e os itens dos menus definidos no sistema UNA. O UNA utiliza um sistema flexível para criar e gerenciar diferentes menus que são usados em várias partes do site (navegação principal, submenus de página, menus de ação de perfil, etc.).

## Tabelas Relevantes do UNA:

*   **`sys_objects_menu`**: Define cada \"objeto de menu\" (uma instância de um menu), associando-o a um `set_name` e um `template_id`.
*   **`sys_menu_sets`**: Define \"conjuntos de menus\" (grupos lógicos de itens de menu). Um objeto de menu usa um conjunto específico.
*   **`sys_menu_items`**: Contém os itens individuais de cada menu (título, link, ícone, visibilidade, ordem, submenu associado, etc.), pertencentes a um `set_name`.
*   **`sys_menu_templates`**: Define os templates HTML usados para renderizar diferentes tipos de menus no UNA PHP. (Para a API \"Deeper\", essa informação de template é menos relevante, pois o cliente renderizará os itens do menu com sua própria lógica de UI).

## Responsabilidades da API:

*   Fornecer um endpoint para buscar a estrutura completa de um menu (seus itens e subitens) pelo nome do seu \"objeto de menu\".
*   A API deve retornar os itens de menu ativos e visíveis para o usuário autenticado (se houver), considerando `visible_for_levels` e `hidden_on` dos itens.

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas `sys_objects_menu`, `sys_menu_sets`, `sys_menu_items`, e `sys_menu_templates`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar essas tabelas.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.PageEngine.MenusRepo` e suas funções para buscar dados de menus e seus itens.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica o endpoint principal (ex: `GET /menus/{menu_object_name}`) para buscar a estrutura de um menu.

## Considerações Importantes:

*   **Itens de Menu Dinâmicos/Submenus:** Alguns itens de menu no UNA podem ter um `submenu_object` que aponta para outro objeto de menu. A API precisará de uma estratégia para lidar com isso:
    *   **Opção 1 (Recursão no Cliente):** A API retorna o `submenu_object` e o cliente faz uma nova chamada para buscar esse submenu se necessário.
    *   **Opção 2 (Inclusão Limitada no Servidor):** A API pode tentar incluir um ou dois níveis de submenus diretamente na resposta (pode tornar a resposta grande e complexa).
    *   **Opção 3 (Itens Marcados):** A API marca itens que têm submenus e o cliente decide quando carregá-los.
    A Opção 1 ou 3 são geralmente mais gerenciáveis para uma API REST.
*   **Visibilidade de Itens:** A filtragem de itens de menu com base em `visible_for_levels` e `hidden_on` (e possivelmente `visibility_custom`) é crucial. O `IDLevel` do usuário autenticado (se houver) deve ser usado.
*   **Links e Ações:** Os campos `link` e `onclick` dos itens de menu precisam ser interpretados pelo cliente. Links podem ser URLs relativas ou absolutas. `onclick` pode ser JavaScript que o cliente precisará mapear para ações na sua aplicação.
*   **Caching:** Estruturas de menu (especialmente para menus estáticos) são boas candidatas para caching.