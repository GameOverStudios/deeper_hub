# Documentação Deeper: Mapeamento da Lógica de \"Serviço\" PHP para `bx_persons`

No sistema UNA, muitos blocos de página dinâmicos são gerados por \"funções de serviço\" dentro dos módulos PHP (ex: `BxPersonsModule::service_entity_friends()`). A API \"Deeper\" não executará código PHP. Em vez disso, ela precisa fornecer os *dados* que esses serviços gerariam, ou fornecer endpoints específicos que o cliente possa chamar para obter esses dados.

Este documento descreve como as principais funções de serviço do módulo `bx_persons` do UNA serão mapeadas para lógica Elixir e/ou como a API de Páginas (`GET /api/v1/pages`) da \"Deeper\" fornecerá os dados para os blocos correspondentes.

## Abordagem Geral:

Quando a API de Páginas (`GET /api/v1/pages?uri=...`) encontra um bloco do tipo `service` pertencente ao módulo `bx_persons`:

1.  **Parse da Definição do Serviço:** A API parseia o `content` do bloco (`sys_pages_blocks.content`) para extrair o nome do módulo (`bx_persons`), o nome do método de serviço (ex: `service_entity_friends`), e quaisquer parâmetros definidos no bloco.
2.  **Execução da Lógica Equivalente em Elixir:**
    *   O `Deeper.PageEngine.PagesRepo` (ou um serviço que ele chama) invocará uma função correspondente no `Deeper.Content.PersonsRepo` (ou em um repositório de conexões, etc.).
    *   Esta função Elixir buscará os dados necessários do banco de dados usando SQL otimizado.
    *   Os parâmetros da definição do serviço do bloco e os parâmetros da página atual (passados na query da API de Páginas) serão usados pela função Elixir.
3.  **Inclusão dos Dados na Resposta da API de Páginas:**
    *   A resposta da API de Páginas para o bloco incluirá:
        *   `\"type\": \"service\"`
        *   `\"service_definition\": { \"module\": \"bx_persons\", \"method\": \"nome_do_servico_original\", \"original_params\": {...} }`
        *   `\"service_data\": { ...dados_buscados_pelo_elixir... }`
4.  **Renderização pelo Cliente:** O cliente usará `service_definition.method` para identificar o tipo de bloco e `service_data` para renderizar o conteúdo usando seus próprios templates/componentes.

## Mapeamento de Serviços Comuns de `bx_persons`:

Abaixo estão exemplos de serviços comuns do módulo `bx_persons` do UNA e como a API \"Deeper\" lidaria com eles. O `{person_id}` aqui geralmente se refere ao `id` de `bx_persons_data` que está no contexto da página atual (ex: visualizando o perfil de alguém).

---
### 1. `service_entity_breadcrumb` (ou similar para cabeçalho/título do perfil)

*   **Função no UNA PHP:** Gera o breadcrumb ou o título principal da página de perfil, geralmente contendo o nome completo da pessoa.
*   **Lógica \"Deeper\":**
    *   **Dados Necessários:** `bx_persons_data.fullname` para o `{person_id}` do contexto.
    *   **Implementação no `PersonsRepo`:** Uma função como `get_person_basic_info(person_id)` que retorna `%{fullname: \"...\"}`.
    *   **`service_data` na API de Páginas:**

```json
        \"service_data\": {
          \"fullname\": \"John Doe\",
          \"profile_url\": \"/profile/john-doe\" // URL amigável do perfil (pode vir do contexto ou ser construída)
        }
```

```json
        \"service_data\": {
          \"cover_image_url\": \"/path/to/cover_image.jpg\",
          \"cover_data\": { /* JSON de bx_persons_data.cover_data para posicionamento, se houver */ }
        }
```

```json
        \"service_data\": {
          \"avatar_url\": \"/path/to/avatar.jpg\", // URL para uma versão apropriada do avatar
          \"fullname\": \"John Doe\" // Para o atributo 'alt' da imagem
        }
```

```json
        {
          \"type\": \"menu\",
          \"menu_object_name\": \"bx_persons_profile_actions_menu\"
          // Opcional: \"menu_items\": [...] se a API de Páginas pré-buscar os itens
        }
```

```json
        \"service_data\": {
          \"friends\": [
            {\"profile_id\": 201, \"person_id\": 801, \"fullname\": \"Jane Smith\", \"avatar_url\": \"...\", \"profile_link\": \"/profile/jane-smith\"},
            {\"profile_id\": 202, \"person_id\": 802, \"fullname\": \"Peter Jones\", \"avatar_url\": \"...\", \"profile_link\": \"/profile/peter-jones\"}
          ],
          \"total_friends\": 27,
          \"view_all_link\": \"/profile/john-doe/friends\" // Link para a página completa de amigos
        }
```

```json
        \"service_data\": {
          \"fullname\": \"John Doe\",
          \"gender\": \"Masculino\", // Pode ser a string traduzida
          \"age\": 33, // Calculado a partir de bx_persons_data.birthday
          \"location\": \"New City\",
          \"member_since\": \"2023-01-15\" // Formatado a partir de sys_accounts.added
          // Outros campos conforme definido pelo bloco no UNA
        }
```

```json
        \"service_data\": {
          \"profiles\": [
            {\"profile_id\": 301, \"person_id\": 901, \"fullname\": \"Alice Wonderland\", \"avatar_url\": \"...\", \"profile_link\": \"/profile/alice\"},
            {\"profile_id\": 302, \"person_id\": 902, \"fullname\": \"Bob The Builder\", \"avatar_url\": \"...\", \"profile_link\": \"/profile/bob\"}
          ],
          \"list_title_key\": \"_bx_persons_block_latest_profiles\" // Chave de tradução para o título do bloco
        }
```

```json
        \"service_data\": {
          \"comments\": [
            { \"id\": 1, \"author_name\": \"Jane\", \"text\": \"Ótimo perfil!\", \"timestamp\": \"...\", \"avatar_url\": \"...\", \"replies_count\": 2 },
            { \"id\": 2, \"author_name\": \"Peter\", \"text\": \"Concordo!\", \"timestamp\": \"...\", \"avatar_url\": \"...\", \"replies_count\": 0 }
          ],
          \"pagination\": { /* para comentários */ },
          \"can_comment\": true, // Se o usuário atual pode comentar
          \"add_comment_form_definition_endpoint\": \"/api/v1/forms/bx_persons_add_comment\" // Opcional: endpoint para a definição do formulário
        }
```

    *   **Cliente:** Usa `fullname` para exibir o título/breadcrumb.

---
### 2. `service_entity_cover` (Capa do Perfil)

*   **Função no UNA PHP:** Exibe a imagem de capa do perfil.
*   **Lógica \"Deeper\":**
    *   **Dados Necessários:** O ID ou URL da imagem de capa (de `bx_persons_data.cover`, que referencia um arquivo).
    *   **Implementação no `PersonsRepo`:** A função `get_person_data_by_id(person_id)` já buscaria `cover`. Uma função adicional no `FilesRepo` (a ser definido) seria usada para obter a URL da imagem a partir do ID do arquivo.
    *   **`service_data` na API de Páginas:**

    *   **Cliente:** Renderiza a imagem de capa.

---
### 3. `service_entity_avatar` (Avatar do Perfil)

*   **Função no UNA PHP:** Exibe o avatar (foto principal) do perfil.
*   **Lógica \"Deeper\":**
    *   **Dados Necessários:** O ID ou URL do avatar (de `bx_persons_data.picture`).
    *   **Implementação:** Similar ao `service_entity_cover`.
    *   **`service_data` na API de Páginas:**

---
### 4. `service_entity_actions_menu` (Menu de Ações do Perfil)

*   **Função no UNA PHP:** Exibe um menu de ações contextuais para o perfil (ex: Adicionar Amigo, Enviar Mensagem, Bloquear).
*   **Lógica \"Deeper\":**
    *   Este bloco no UNA é do tipo `menu`. O `content` do bloco em `sys_pages_blocks` já conteria o nome do objeto de menu (ex: `bx_persons_profile_actions_menu`).
    *   A API de Páginas já lida com isso:

    *   O cliente usaria `menu_object_name` para chamar `GET /api/v1/menus/bx_persons_profile_actions_menu` (passando `context_param_person_id={person_id}`) para obter os itens de menu filtrados e processados.

---
### 5. `service_entity_friends_list` / `service_entity_connections_list` (Lista de Amigos/Conexões)

*   **Função no UNA PHP:** Exibe uma lista de amigos ou conexões do perfil.
*   **Lógica \"Deeper\":**
    *   **Dados Necessários:** Lista de perfis de amigos/conexões, incluindo nome, avatar, link do perfil.
    *   **Implementação no `ConnectionsRepo` (a ser definido) ou `PersonsRepo`:** Uma função como `get_friends_for_person(person_id, limit, offset, user_making_request_profile_id)` que:
        1.  Consulta `sys_profiles_conn_friends` para encontrar IDs de amigos.
        2.  Faz `JOIN` com `sys_profiles` e `bx_persons_data` para obter detalhes dos amigos.
        3.  Aplica filtros de privacidade para cada perfil de amigo em relação ao `user_making_request_profile_id`.
        4.  Implementa paginação.
    *   **`service_data` na API de Páginas:**

    *   **Cliente:** Renderiza a lista de amigos.

---
### 6. `service_entity_info` (Bloco de Informações do Perfil)

*   **Função no UNA PHP:** Exibe vários campos de dados do perfil (ex: gênero, idade, localização, data de registro).
*   **Lógica \"Deeper\":**
    *   **Dados Necessários:** Campos selecionados de `bx_persons_data` e possivelmente `sys_accounts`.
    *   **Implementação no `PersonsRepo`:** A função `get_person_data_by_id(person_id)` já retornaria a maioria desses dados.
    *   **`service_data` na API de Páginas:**

    *   **Cliente:** Exibe as informações formatadas.

---
### 7. `service_latest_profiles` / `service_top_rated_profiles` / `service_featured_profiles` (Listagens de Perfis)

*   **Função no UNA PHP:** Exibe listas de perfis baseadas em diferentes critérios (mais recentes, mais bem avaliados, em destaque).
*   **Lógica \"Deeper\":**
    *   **Dados Necessários:** Lista de perfis resumidos.
    *   **Implementação no `PersonsRepo`:** Funções específicas como:
        *   `get_latest_persons(count, user_making_request_profile_id)`: Ordena por `bx_persons_data.added DESC`.
        *   `get_top_rated_persons(count, user_making_request_profile_id)`: Ordena por `bx_persons_data.rate DESC`.
        *   `get_featured_persons(count, user_making_request_profile_id)`: Filtra por `bx_persons_data.featured = 1`.
        *   Todas estas funções devem aplicar filtros de privacidade e retornar dados resumidos (nome, avatar, link).
    *   **`service_data` na API de Páginas:**

    *   **Cliente:** Renderiza a lista de perfis.

---
### 8. `service_profile_comments` (Comentários do Perfil)

*   **Função no UNA PHP:** Exibe a seção de comentários do perfil.
*   **Lógica \"Deeper\":**
    *   **Dados Necessários:** Lista de comentários (`bx_persons_cmts`), informações dos autores dos comentários, formulário para novo comentário (se o usuário tiver permissão).
    *   **Implementação:**
        *   `PersonsRepo.get_profile_comments(person_id, opts)` para buscar comentários.
        *   A API de Páginas pode pré-buscar a primeira página de comentários.
        *   O formulário de comentário seria uma definição que o cliente usa para construir o formulário (ver API de Formulários - `05_forms_and_grids/`).
    *   **`service_data` na API de Páginas:**

    *   **Cliente:** Renderiza os comentários, a paginação e o formulário de novo comentário.

## Considerações Gerais:

*   **Eficiência:** A API de Páginas pode se tornar \"pesada\" se pré-buscar dados para muitos blocos de serviço complexos. Estratégias como:
    *   Limitar a quantidade de dados pré-buscados para visualizações iniciais (ex: apenas os 5 primeiros amigos).
    *   Fornecer links para endpoints API mais específicos que o cliente pode chamar para carregar mais dados sob demanda (ex: \"Ver todos os amigos\" leva a uma página/componente que chama `GET /api/v1/persons/{person_id}/friends`).
*   **Parâmetros:** As funções Elixir nos Repos correspondentes aos serviços PHP precisarão aceitar os parâmetros relevantes que eram passados para as funções PHP (sejam eles do `block_content` ou do contexto da página).
*   **ACL e Privacidade:** Toda busca de dados para serviços deve respeitar as permissões do usuário solicitante e as configurações de privacidade do conteúdo sendo acessado.
*   **Traduções:** Chaves de tradução para títulos de blocos ou textos fixos dentro dos dados do serviço devem ser resolvidas pela API \"Deeper\" (usando `LocalizationRepo`) ou fornecidas como chaves para o cliente traduzir.

Este mapeamento é essencial para garantir que a API \"Deeper\" possa suportar a renderização dinâmica de páginas de forma semelhante ao UNA, mas de uma maneira desacoplada e baseada em dados.