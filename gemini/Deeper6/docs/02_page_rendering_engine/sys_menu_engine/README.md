# Documentação Deeper: Motor de Menus

Este componente da API \"Deeper\" é responsável por fornecer os dados necessários para que o cliente possa renderizar menus de navegação dinâmicos, baseados nas configurações do sistema UNA.

Ele lida com a definição de conjuntos de menus, templates de menu (embora a renderização do template em si seja responsabilidade do cliente), objetos de menu específicos e os itens que compõem cada menu.

## Responsabilidades Principais:

*   Fornecer a lista de menus disponíveis (objetos de menu).
*   Para um menu específico, fornecer a lista de seus itens, incluindo:
    *   Título (com suporte à internacionalização).
    *   Link de destino.
    *   Ícone.
    *   Submenus associados (se houver, recursivamente).
    *   Condições de visibilidade (baseadas em nível de usuário, contexto, etc., que serão avaliadas pelo cliente ou pré-filtradas pela API com base no usuário autenticado).
    *   Outros atributos como `target`, `onclick`, `addon`.

## Componentes Detalhados:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas `sys_menu_sets`, `sys_menu_templates`, `sys_objects_menu`, e `sys_menu_items`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir e sua documentação para criar as tabelas do motor de menus.
    *   Links para:
        *   [Criar Tabela `sys_menu_sets` (`create_sys_menu_sets_table.elixir.md`)](./migrations/create_sys_menu_sets_table.elixir.md)
        *   [Criar Tabela `sys_menu_templates` (`create_sys_menu_templates_table.elixir.md`)](./migrations/create_sys_menu_templates_table.elixir.md)
        *   [Criar Tabela `sys_objects_menu` (`create_sys_objects_menu_table.elixir.md`)](./migrations/create_sys_objects_menu_table.elixir.md)
        *   [Criar Tabela `sys_menu_items` (`create_sys_menu_items_table.elixir.md`)](./migrations/create_sys_menu_items_table.elixir.md)

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o módulo Elixir (ex: `Deeper.PageEngine.MenuRepo`) que encapsula as queries SQL para interagir com as tabelas de menus.
    *   Detalha as funções para buscar definições de menu e seus itens, aplicando filtros de visibilidade quando possível.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para obter dados de menus.
    *   Exemplo: `GET /api/v1/menus/{menu_object_name}`.

## Fluxo de Obtenção de Menu:

1.  Cliente (ex: ao renderizar um cabeçalho ou uma barra lateral) solicita os dados de um menu específico à API (ex: `GET /api/v1/menus/sys_site_main_menu`).
2.  API, através do `MenuRepo`:
    *   Verifica a existência do objeto de menu em `sys_objects_menu`.
    *   Busca os itens de menu (`sys_menu_items`) associados a esse objeto de menu e ao `set_name` correspondente.
    *   Para cada item, resolve o título (considerando o idioma do usuário, via `sys_localization_strings` se o título for uma chave de tradução).
    *   Filtra os itens com base nas permissões de visibilidade do usuário autenticado (`visible_for_levels`).
    *   Estrutura os itens hierarquicamente (se houver submenus).
3.  API retorna a estrutura do menu (lista de itens) em JSON.
4.  Cliente renderiza o menu com base nos dados recebidos.