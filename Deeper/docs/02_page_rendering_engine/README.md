# Documentação Deeper: Motor de Renderização de Páginas da API

Este diretório detalha como a API \"Deeper\" fornecerá os dados e a estrutura necessários para que um cliente remoto possa reconstruir e renderizar as páginas dinâmicas do sistema UNA. O objetivo não é que a API renderize HTML, mas sim que forneça uma descrição JSON da página, seus layouts, blocos e o conteúdo ou definições de serviço para esses blocos.

## Componentes Principais (do UNA e como a API os expõe):

1.  [**Objetos de Página (`sys_objects_page/`)**](./sys_objects_page/README.md):
    *   Cada página no UNA é definida como um \"objeto de página\". A API fornecerá os metadados desses objetos (URI, título, layout, submenu associado, configurações de cache, etc.) e a lista de blocos que compõem a página.

2.  [**Layouts de Página (`sys_pages_layouts/`)**](./sys_pages_layouts/README.md):
    *   O UNA define diferentes estruturas de layout (ex: uma coluna, duas colunas, coluna esquerda estreita, etc.). A API indicará qual layout uma página usa, permitindo ao cliente aplicar a estrutura correta.

3.  [**Blocos de Página (`sys_pages_blocks/`)**](./sys_pages_blocks/README.md):
    *   As páginas são compostas por blocos. A API descreverá cada bloco: seu título, tipo (HTML, serviço, menu, etc.), em qual célula do layout ele se encontra, e seu conteúdo ou a definição do serviço que o gera.

4.  [**Motor de Menus (`sys_menu_engine/`)**](./sys_menu_engine/README.md):
    *   Muitas páginas e blocos podem referenciar menus. A API para menus (definida aqui ou referenciada de `01_system_core`) fornecerá os itens de menu para que o cliente possa renderizá-los.

## Fluxo Geral de Renderização de Página pelo Cliente:

1.  **Requisição do Cliente:** O cliente (baseado na URL atual, possivelmente após resolver um permalink) determina qual \"objeto de página UNA\" precisa ser renderizado.
2.  **Chamada à API de Página:** O cliente faz uma requisição à API \"Deeper\" (ex: `GET /api/v1/pages?uri={page_uri}&param_key=value`).
3.  **Resposta da API:** A API retorna uma estrutura JSON contendo:
    *   Metadados do objeto de página (título, ID do layout, nome do submenu, etc.).
    *   Uma lista de definições de blocos, incluindo:
        *   ID do bloco, título, célula do layout.
        *   Tipo do bloco (`html`, `service`, `menu`, `rss`, etc.).
        *   Se tipo `html`: o conteúdo HTML bruto.
        *   Se tipo `service`: a definição do serviço (módulo, método, parâmetros) e, idealmente, os *dados* que esse serviço produziria (em vez do HTML renderizado pelo PHP).
        *   Se tipo `menu`: o nome do objeto de menu a ser renderizado.
4.  **Processamento pelo Cliente:**
    *   O cliente usa o ID do layout para aplicar a estrutura de colunas apropriada.
    *   Para cada bloco na resposta da API:
        *   Renderiza o bloco na célula correta do layout.
        *   Se o tipo for `html`, renderiza o HTML diretamente (com sanitização se necessário).
        *   Se o tipo for `service`, o cliente usa a definição do serviço e os dados fornecidos para renderizar o bloco usando seus próprios templates/componentes. Se a API não fornecer os dados diretamente, o cliente pode precisar fazer uma chamada API adicional para um endpoint específico do \"serviço\" daquele módulo para obter os dados.
        *   Se o tipo for `menu`, o cliente chama a API de menus (ou usa dados já carregados) para obter os itens e renderizar o menu.
    *   O cliente também renderiza o submenu da página, se especificado.

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.PageEngine.PagesRepo`: Para buscar dados de `sys_objects_page`, `sys_pages_blocks`, `sys_pages_layouts`.
*   `Deeper.SystemCore.MenusRepo`: Para buscar dados de menus (se um bloco for do tipo `menu` ou a página tiver um submenu).
*   Repositórios de Módulos de Conteúdo (ex: `Deeper.Content.PersonsRepo`): Serão chamados se um bloco for do tipo `service` e a API \"Deeper\" optar por pré-buscar os dados desse serviço em vez de apenas passar a definição do serviço para o cliente.

Esta abordagem visa dar ao cliente a informação estrutural e de conteúdo necessária para construir a página dinamicamente, mantendo a flexibilidade e o desacoplamento.