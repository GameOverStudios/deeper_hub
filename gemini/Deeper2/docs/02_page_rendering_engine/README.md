# Documentação Deeper: Motor de Renderização de Páginas (API)

Esta seção da API \"Deeper\" descreve como o cliente remoto pode obter os dados necessários para construir e renderizar as páginas dinâmicas que são definidas no sistema UNA. O UNA utiliza um sistema flexível de \"Page Objects\", \"Layouts\", \"Blocos de Conteúdo\" e \"Menus\" para montar suas páginas.

O objetivo da API \"Deeper\" é expor essa estrutura e o conteúdo dos blocos de uma forma que o cliente possa interpretar e renderizar usando suas próprias tecnologias de UI. A API não fornecerá HTML pré-renderizado (exceto, talvez, para blocos do tipo HTML puro), mas sim os dados e metadados da página.

## Componentes Principais do UNA (e como a API os abordará):

1.  **Objetos de Página (`sys_objects_page`):**
    *   Cada página no UNA é definida como um \"objeto de página\". Esta tabela armazena o URI da página, título, layout a ser usado, submenu associado, configurações de cache, metadados SEO, etc.
    *   **API:** Um endpoint principal permitirá buscar a definição de uma página pelo seu URI ou nome de objeto.

2.  **Layouts de Página (`sys_pages_layouts`):**
    *   Define a estrutura de colunas/células de uma página (ex: uma coluna, duas colunas, três colunas com diferentes larguras).
    *   **API:** A informação do layout (ID ou nome) será parte da resposta do objeto de página. O cliente usará isso para organizar os blocos. Um endpoint opcional pode listar os layouts disponíveis.

3.  **Blocos de Página (`sys_pages_blocks`):**
    *   São os contêineres de conteúdo dentro das células de um layout. Cada bloco tem um tipo (HTML, serviço, menu, RSS, etc.), título, conteúdo (que pode ser HTML direto ou uma definição de serviço a ser chamado), e configurações de visibilidade.
    *   **API:** A resposta do objeto de página incluirá uma lista de todos os blocos ativos para aquela página, com seus metadados e conteúdo (ou definição de serviço).

4.  **Menus (`sys_objects_menu`, `sys_menu_items`, `sys_menu_sets`):**
    *   Define os sistemas de navegação. Páginas e blocos podem ter menus associados.
    *   **API:** Endpoints dedicados permitirão buscar a estrutura de um menu específico pelo nome do seu objeto.

## Estrutura da Documentação Nesta Seção:

*   [**`sys_objects_page/`**](./sys_objects_page/README.md): Detalha a API para obter definições de páginas e seus blocos.
*   [**`sys_pages_layouts/`**](./sys_pages_layouts/README.md): Descreve como as informações de layout são fornecidas e (opcionalmente) uma API para listar layouts.
*   [**`sys_menu_engine/`**](./sys_menu_engine/README.md): Detalha a API para obter a estrutura dos menus.

## Fluxo Típico para o Cliente:

1.  O cliente determina qual página carregar com base na navegação do usuário (ex: URI `/m/persons/home`).
2.  O cliente chama `GET /api/v1/pages?uri=/m/persons/home` (ou usa o endpoint `POST /resolve-path` para obter o nome do objeto de página e depois busca por ele).
3.  A API \"Deeper\" retorna um objeto JSON contendo:
    *   Metadados da página (`sys_objects_page`).
    *   ID ou nome do layout (`sys_pages_layouts`).
    *   Uma lista de blocos (`sys_pages_blocks`) para aquela página, cada um com:
        *   ID da célula do layout onde deve ser renderizado.
        *   Título, tipo de design box.
        *   Tipo de conteúdo do bloco (`html`, `service`, `menu`, etc.).
        *   O conteúdo em si (se HTML) ou a definição do serviço (módulo, método, parâmetros) ou o nome do objeto de menu.
    *   Nome do objeto de submenu associado à página (se houver).
4.  O cliente usa o ID/nome do layout para preparar a estrutura da UI.
5.  Para cada bloco:
    *   Se o tipo for `html`, renderiza o HTML diretamente.
    *   Se o tipo for `service`, o cliente pode precisar fazer uma chamada adicional à API \"Deeper\" para obter os dados específicos que esse serviço forneceria (ex: `GET /api/v1/data-service?module=bx_persons&method=get_latest_profiles&count=5`). A API para esses \"data-services\" será definida conforme os módulos de conteúdo são desenvolvidos.
    *   Se o tipo for `menu`, o cliente chama `GET /api/v1/menus/{menu_object_name}` para obter os itens do menu e renderizá-los.
6.  Se houver um submenu para a página, o cliente também o busca e renderiza.

Esta abordagem desacopla a lógica de negócios e dados (no backend \"Deeper\") da apresentação (no cliente).