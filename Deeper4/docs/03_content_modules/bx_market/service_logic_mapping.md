# Documentação Deeper: Mapeamento da Lógica de Serviço para Marketplace (`bx_market`)

Este documento descreve como as funcionalidades e \"service calls\" (métodos de serviço) do módulo `bx_market` original do UNA PHP serão mapeadas para a lógica no backend Elixir \"Deeper\" e expostas através da API RESTful.

O UNA frequentemente usa métodos de serviço em suas classes de módulo PHP (ex: `BxMarketModule::serviceListEntries`, `BxMarketModule::serviceViewEntry`) para encapsular lógica de busca, formatação de dados, e verificações de permissão antes de renderizar HTML. No nosso backend Elixir, essa lógica será distribuída entre:

*   **Módulos de Acesso a Dados (Repositórios):** Ex: `Deeper.Content.MarketRepo`, que lida com a interação direta com o banco de dados e a construção de queries SQL.
*   **Módulos de Serviço/Contexto Elixir (Opcional):** Para lógica de negócios mais complexa que não se encaixa diretamente no Repo ou no Controller.
*   **Controllers da API Phoenix:** Que orquestram as chamadas, validam entradas, e formatam as respostas JSON.
*   **Lógica no Cliente Remoto:** Parte da lógica de apresentação e algumas lógicas de interação serão responsabilidade do cliente que consome a API.

## Mapeamento de Funcionalidades Chave:

### 1. Listagem de Produtos/Serviços (`serviceListEntries` no UNA)

*   **Funcionalidade UNA Original:**
    *   Recebe parâmetros de filtro (categoria, autor, termo de busca, status, etc.), ordenação e paginação.
    *   Constrói uma query SQL complexa.
    *   Busca as entradas no banco.
    *   Formata cada entrada para exibição (incluindo imagem principal, informações do autor, preço formatado, snippets de descrição).
    *   Renderiza o HTML da lista de produtos, incluindo controles de paginação.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/market/entries`
    *   **Controller Elixir:**
        1.  Recebe query parameters para filtros, ordenação e paginação.
        2.  Valida os parâmetros.
        3.  Chama `Deeper.Content.MarketRepo.list_entries(filters, pagination_opts)`.
    *   **`Deeper.Content.MarketRepo.list_entries/2`:**
        1.  Constrói dinamicamente a query SQL `SELECT` principal para `bx_market_entries` com base nos filtros e ordenação.
        2.  Executa uma query `COUNT(*)` separada com os mesmos filtros para obter o `total_items` para a paginação.
        3.  Executa a query `SELECT` principal com `LIMIT` e `OFFSET`.
        4.  Para cada entrada retornada, se a opção `preload` (nos query params da API) solicitar dados associados (fotos, categoria, autor):
            *   **Fotos:** Chama `MarketRepo.list_photos_for_entry/1` (ou uma função otimizada para buscar fotos para múltiplas entradas de uma vez, como `MarketRepo.list_main_photos_for_entries(entry_ids)`).
            *   **Categoria:** Se não foi feito JOIN na query principal, chama `MarketRepo.get_category/1`.
            *   **Autor:** Chama `Deeper.SystemCore.ProfilesRepo.get_profile_summary/1` (ou uma função otimizada para múltiplos autores).
        5.  Mapeia os resultados para as structs `Deeper.Content.Market.Entry` (ou mapas), incluindo os dados pré-carregados.
        6.  Retorna a lista de entradas e os metadados de paginação.
    *   **Cliente Remoto:**
        1.  Recebe o JSON com a lista de entradas e os dados de paginação.
        2.  Renderiza a lista de produtos e os controles de paginação.

### 2. Visualização de um Produto/Serviço (`serviceViewEntry` no UNA)

*   **Funcionalidade UNA Original:**
    *   Recebe o ID ou nome (slug) da entrada.
    *   Busca a entrada no banco.
    *   Incrementa o contador de visualizações.
    *   Busca dados associados (todas as fotos, categoria, detalhes do autor, comentários, votos).
    *   Verifica permissões de visualização.
    *   Formata todos os dados para exibição.
    *   Renderiza o HTML da página de detalhes do produto.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/market/entries/{id_or_name}`
    *   **Controller Elixir:**
        1.  Recebe `id_or_name` e o query param `preload`.
        2.  Chama `Deeper.Content.MarketRepo.get_entry(id_or_name, preload_opts)`.
        3.  (Opcional, pode ser um endpoint separado) Chama `Deeper.Content.MarketRepo.increment_view_count(entry.id)`.
    *   **`Deeper.Content.MarketRepo.get_entry/2`:**
        1.  Busca a entrada principal em `bx_market_entries`.
        2.  Se encontrada, e com base nas `preload_opts`:
            *   Busca todas as fotos (`MarketRepo.list_photos_for_entry/1`).
            *   Busca a categoria (`MarketRepo.get_category/1`).
            *   Busca o perfil do autor (`ProfilesRepo.get_profile_details/1`).
            *   (Para comentários, votos, etc., a API pode retornar contagens e links para os endpoints específicos desses sistemas de interação, ou os primeiros N itens).
        3.  Mapeia para a struct `Deeper.Content.Market.Entry`.
        4.  Retorna a entrada.
    *   **Cliente Remoto:**
        1.  Recebe o JSON com os detalhes da entrada.
        2.  Renderiza a página de detalhes do produto.
        3.  Se necessário, faz chamadas subsequentes para buscar todos os comentários, etc., usando os links/endpoints fornecidos.

### 3. Criação/Edição de Listagens (`Formulários do UNA`)

*   **Funcionalidade UNA Original:**
    *   Apresenta um formulário (definido em `sys_objects_form`, `sys_form_inputs`) para criar ou editar uma listagem.
    *   Valida os dados submetidos.
    *   Salva/atualiza os dados na tabela `bx_market_entries`.
    *   Lida com o upload e associação de imagens.
    *   Redireciona para a página da listagem.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoints:**
        *   `POST /api/v1/market/entries` (Criar)
        *   `PUT /api/v1/market/entries/{id}` (Atualizar)
    *   **Controller Elixir:**
        1.  Recebe os dados da listagem no corpo da requisição JSON.
        2.  Valida os dados (tipos, campos obrigatórios, formatos).
        3.  Para criação, o `author_id` é obtido do JWT.
        4.  Chama `MarketRepo.create_entry(params)` ou `MarketRepo.update_entry(id, params)`.
        5.  Retorna a listagem criada/atualizada.
    *   **`Deeper.Content.MarketRepo.create_entry/1` e `update_entry/2`:**
        1.  Executam as queries `INSERT` ou `UPDATE` em `bx_market_entries`.
        2.  Lidam com a formatação de dados para o banco (ex: timestamps).
    *   **Gerenciamento de Fotos:**
        *   O upload de arquivos de imagem é tratado por endpoints separados do `06_file_management` (ex: `POST /api/v1/files`), que retornam um `file_id`.
        *   Após criar/atualizar a listagem, o cliente faz chamadas para `POST /api/v1/market/entries/{entry_id}/photos` para associar os `file_id`s à listagem.
        *   Ou, a API de criação/atualização de listagem poderia aceitar uma lista de `file_id`s para associar de uma vez.
    *   **Cliente Remoto:**
        1.  Apresenta um formulário para o usuário.
        2.  Faz o upload das imagens para a API de arquivos.
        3.  Submete os dados da listagem (incluindo os `file_id`s das imagens) para a API do marketplace.

### 4. Gerenciamento de Categorias (`Studio do UNA`)

*   **Funcionalidade UNA Original:**
    *   Interface no painel de administração (Studio) para CRUD de categorias.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoints:** `POST, GET, PUT, DELETE /api/v1/market/categories` (conforme definido em `api_endpoints.md`).
    *   **Controller Elixir e `MarketRepo`:** Implementam a lógica CRUD para categorias.
    *   **Cliente Remoto (Admin):** Uma interface de administração consumirá esses endpoints.

### 5. Verificações de Permissão

*   **Funcionalidade UNA Original:**
    *   Usa `BxDolAcl` para verificar se o usuário pode criar, editar, deletar, visualizar listagens com base em seu nível de membresia e, possivelmente, propriedade da listagem.
*   **Mapeamento para API \"Deeper\":**
    *   **Autenticação:** O JWT identifica o usuário e seu nível de ACL.
    *   **Autorização nos Controllers:**
        *   Antes de chamar as funções do `MarketRepo` para escrita (criar, editar, deletar), o controller da API verificará:
            1.  A permissão da ação geral (ex: \"pode criar listagem no marketplace?\") com base no nível do usuário (consultando a lógica ACL portada do UNA).
            2.  Para edição/deleção, se o usuário é o `author_id` da listagem ou se tem um papel de administrador/moderador com permissão para modificar qualquer listagem.
    *   A lógica de consulta ao ACL será centralizada (conforme `docs/01_system_core/sys_acl/`).

### 6. Lógica de Destaque (`Featured`) e Expiração

*   **Funcionalidade UNA Original:**
    *   Mecanismos para administradores destacarem listagens.
    *   Listagens podem ter uma data de expiração.
*   **Mapeamento para API \"Deeper\":**
    *   **`MarketRepo`:**
        *   `update_entry/2` pode aceitar um campo `featured_until` (timestamp Unix) para definir o destaque.
        *   `update_entry/2` pode aceitar um campo `expiration_date` (timestamp Unix).
    *   **`list_entries/2`:**
        *   Pode ter um filtro `featured_only: true` que adiciona `WHERE featured_until IS NOT NULL AND featured_until > UNIXEPOCH()` à query.
        *   Pode ter um filtro para não mostrar listagens expiradas (`WHERE expiration_date IS NULL OR expiration_date > UNIXEPOCH()`).
    *   **API de Admin (`07_studio_admin_api`):** Terá endpoints para administradores gerenciarem o `featured_until` e `status_admin` das listagens.
    *   **Tarefas Agendadas (Opcional, Backend):** Uma tarefa de background no Elixir poderia periodicamente verificar listagens expiradas e mudar seu status para `expired`.

### 7. Contadores (Views, Favorites, Comments, Votes)

*   **Funcionalidade UNA Original:**
    *   Contadores são atualizados nas tabelas principais (ex: `bx_market_entries.views`) ou em tabelas de resumo. Isso pode ser feito por triggers no DB ou na lógica da aplicação PHP.
*   **Mapeamento para API \"Deeper\":**
    *   **Incremento Direto:**
        *   `MarketRepo.increment_view_count/1` atualiza `bx_market_entries.views`.
        *   Quando um comentário é adicionado/removido via API de Comentários, o `CommentsRepo` (ou um serviço) poderia chamar `MarketRepo.update_entry_comment_count(entry_id, new_count)`. O mesmo para votos, favoritos.
    *   **Cálculo em Tempo Real (para `list_entries`):** Menos performático para listagens, mas possível para visualização de um item.
    *   **Abordagem Híbrida (Recomendada):**
        *   A API de interação (comentários, votos, favoritos) atualiza o contador na tabela `bx_market_entries` quando uma interação ocorre.
        *   Isso mantém os contadores atualizados para listagens sem a necessidade de `COUNT(*)`s complexos a cada vez.

Este mapeamento fornece um guia sobre como a lógica existente no módulo PHP `bx_market` pode ser reestruturada para uma arquitetura de API RESTful com backend Elixir, mantendo as funcionalidades essenciais e aproveitando as capacidades do Elixir para concorrência e da API para desacoplamento.