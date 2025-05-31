# Documentação Deeper: Motor de Renderização de Páginas

Este diretório detalha como a API \"Deeper\" fornecerá os dados necessários para que um cliente remoto possa reconstruir a estrutura e o conteúdo das páginas dinâmicas do sistema UNA. O foco é em fornecer a definição da página, seus layouts, blocos de conteúdo e os menus associados.

A API de **administração** para criar e configurar estas páginas, blocos e menus será detalhada na seção `07_studio_admin_api/page_builder_admin_api.md` e `.../menu_admin_api.md`.

## Responsabilidades Principais da API do Motor de Páginas:

*   Fornecer a definição de um objeto de página (`sys_objects_page`) com base em um identificador (geralmente o nome do objeto da página, ex: `bx_persons_home`).
*   Listar os blocos de conteúdo (`sys_pages_blocks`) associados a uma página, incluindo seu tipo, conteúdo (ou definição de serviço) e design.
*   Fornecer informações sobre layouts de página (`sys_pages_layouts`) e tipos de design de blocos (`sys_pages_design_boxes`).
*   Fornecer a estrutura e os itens de menus (`sys_objects_menu`, `sys_menu_items`) para serem renderizados pelo cliente.

## Componentes do Banco de Dados UNA para Renderização de Páginas:

*   **`sys_objects_page`**: Define cada página única no sistema, seu URI, título, layout, módulo associado, configurações de cache, meta tags, etc.
*   **`sys_pages_layouts`**: Define os diferentes templates de layout de página disponíveis (ex: uma coluna, duas colunas, etc.).
*   **`sys_pages_cells` (Implícito/Parte do Layout):** Embora não haja uma tabela `sys_pages_cells` explícita no esquema original, os layouts têm um número definido de células (`cells_number` em `sys_pages_layouts`), e os blocos são atribuídos a essas células (`cell_id` em `sys_pages_blocks`).
*   **`sys_pages_blocks`**: Define cada bloco de conteúdo em uma página, incluindo seu título, tipo (HTML, serviço, menu, RSS, etc.), conteúdo (ou chamada de serviço), design box, visibilidade, etc.
*   **`sys_pages_design_boxes`**: Define os diferentes estilos/templates visuais para os blocos de conteúdo.
*   **`sys_pages_types`**: Define os tipos gerais de página (influencia o template base da página).
*   **`sys_menu_sets`**: Define conjuntos de menus.
*   **`sys_objects_menu`**: Define instâncias específicas de menus, ligando um `set_name` a um template de menu.
*   **`sys_menu_items`**: Define os itens individuais dentro de cada menu, seus links, títulos, ícones, submenus, etc.
*   **`sys_menu_templates`**: Define os templates visuais para renderização de menus.

## Estrutura dos Submódulos:

1.  [**Objetos de Página, Blocos e Layouts (`sys_objects_page/`)**](./sys_objects_page/README.md):
    *   API para obter a definição completa de uma página, incluindo seus blocos, informações de layout e design.
    *   Como os blocos do tipo \"serviço\" serão tratados pela API (retornando a definição do serviço e/ou os dados que o serviço produziria).

2.  [**Motor de Menus (`sys_menu_engine/`)**](./sys_menu_engine/README.md):
    *   API para obter a estrutura de um menu específico, incluindo todos os seus itens e sub-itens.

## Abordagem da API \"Deeper\":

A API \"Deeper\" não renderizará HTML. Em vez disso, fornecerá ao cliente:

*   **Metadados da Página:** Informações do `sys_objects_page` (título, layout ID, etc.).
*   **Estrutura de Layout:** Informações sobre o layout a ser usado (ex: nome do template do layout, número de células).
*   **Lista de Blocos:** Para cada célula do layout, uma lista ordenada de blocos, cada um com:
    *   ID do bloco, título, ID do design box.
    *   **Tipo de Bloco:** (`html`, `service`, `menu`, `rss`, `image`, etc.).
    *   **Conteúdo do Bloco:**
        *   Para tipo `html` ou `text`: o conteúdo HTML/texto bruto.
        *   Para tipo `service`: a **definição do serviço** (módulo, método, parâmetros) e, idealmente, os **dados JSON** que este serviço normalmente geraria. O cliente então usaria esses dados para renderizar o bloco com seus próprios templates/componentes.
        *   Para tipo `menu`: o nome do objeto de menu (`sys_objects_menu.object`) que o cliente deve solicitar separadamente via API de menu.
        *   Para outros tipos (`rss`, `image`): dados estruturados relevantes.
    *   Configurações de visibilidade, cache, etc.
*   **Dados de Menu:** Para um objeto de menu solicitado, a API retornará uma estrutura hierárquica de itens de menu.

O cliente remoto será responsável por interpretar esses dados JSON e renderizar a página e seus componentes usando seus próprios templates e lógica de UI.