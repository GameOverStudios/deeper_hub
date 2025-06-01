# Documentação Deeper: Mapeamento da Lógica de \"Serviço\" para API (Módulo `deeper_groups`)

O módulo de grupos no UNA PHP, assim como outros módulos de conteúdo, utilizaria \"serviços\" para renderizar blocos de UI e fornecer dados agregados. A API RESTful \"Deeper\" traduzirá essas funcionalidades para endpoints que fornecem dados JSON, com o cliente sendo responsável pela apresentação.

## 1. Serviço: \"Listar Meus Grupos\" (Grupos que o usuário é membro)

*   **Funcionalidade UNA PHP (Exemplo Hipotético):**
    *   `BxGroupsModule->service_my_groups(int $viewer_profile_id, int $count = 10)`
    *   Retornaria HTML com uma lista dos grupos do usuário.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/groups`
    *   **Query Parameters:**
        *   `member_profile_id={id_do_usuario_logado}` (O ID do usuário logado seria obtido do JWT no backend e usado para filtrar).
        *   `status=active` (para o grupo em si)
        *   `member_status=active` (para o status da membresia do usuário, implícito no filtro `member_profile_id` que já busca por membros ativos).
        *   `per_page={N}`
        *   `page=1`
        *   `sort_by=last_activity_desc` (se houver um campo de última atividade) ou `title_asc`.
        *   `include=avatar` (para exibir miniaturas).
    *   **Lógica no `Deeper.Content.GroupsRepo`:** A função `list_groups/2` já foi projetada para aceitar `member_profile_id` como filtro.
    *   **Responsabilidade do Cliente:** Buscar os dados e renderizar a lista \"Meus Grupos\".

## 2. Serviço: \"Listar Grupos Populares/Ativos\"

*   **Funcionalidade UNA PHP:**
    *   `BxGroupsModule->service_popular_groups(int $count = 5)`
    *   Retornaria HTML.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/groups`
    *   **Query Parameters:**
        *   `sort_by=members_count_desc` (OU `sort_by=activity_level_desc` - se houver um campo de \"nível de atividade\" calculado).
        *   `status=active`
        *   `privacy_level=public` (ou incluir `private` se a popularidade não for restrita a públicos).
        *   `per_page={N}`
        *   `page=1`
    *   **Lógica no `Deeper.Content.GroupsRepo`:** A função `list_groups/2` lidaria com a ordenação.
    *   **Responsabilidade do Cliente:** Renderizar a lista.

## 3. Serviço: \"Bloco de Feed de Atividades do Grupo\"

*   **Funcionalidade UNA PHP:**
    *   `BxGroupsModule->service_group_feed(int $group_id, int $count = 10)`
    *   Retornaria HTML com os últimos posts/atividades do grupo.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/groups/{group_id}/posts` (se usando `deeper_group_content_posts`)
    *   **OU Endpoint:** `GET /api/v1/feed?context=group&context_id={group_id}` (se houver um sistema de feed de atividades mais genérico que agregue diferentes tipos de conteúdo postados em um grupo).
    *   **Query Parameters (para `/posts`):**
        *   `per_page={N}`
        *   `page=1`
        *   `sort_by=created_at_desc`
        *   `include=author_profile,attachments`
    *   **Lógica no `Deeper.Content.GroupsRepo` (ou um `FeedRepo`):** Função para listar posts/atividades filtradas por `group_id`.
    *   **Responsabilidade do Cliente:** Buscar os posts/atividades e renderizar o feed.

## 4. Serviço: \"Bloco de Membros do Grupo\" (ex: alguns membros com avatares)

*   **Funcionalidade UNA PHP:**
    *   `BxGroupsModule->service_group_members_block(int $group_id, int $count = 8, string $role = \"any\")`
    *   Retornaria HTML com uma amostra de membros.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/groups/{group_id}/members`
    *   **Query Parameters:**
        *   `per_page={N}` (ex: 8)
        *   `page=1`
        *   `status=active`
        *   `role={role_filter}` (opcional, ex: `admin,moderator`)
        *   `sort_by=joined_at_desc` (ou aleatório, ou por \"atividade\")
        *   `include=profile_details` (para obter avatar e nome).
    *   **Lógica no `Deeper.Content.GroupsRepo`:** A função `list_group_members/3` lida com isso.
    *   **Responsabilidade do Cliente:** Renderizar o bloco de membros.

## 5. Serviço: \"Botões de Ação do Grupo\" (Juntar-se, Sair, Convidar, etc.)

*   **Funcionalidade UNA PHP:**
    *   `BxGroupsModule->service_group_actions_block(int $group_id, int $viewer_profile_id)`
    *   Retornaria HTML com os botões de ação relevantes para o usuário logado em relação ao grupo.

*   **Mapeamento para API \"Deeper\":**
    *   **Não um serviço que retorna UI diretamente.** A API fornece o estado, o cliente decide quais botões mostrar.
    *   **Passo 1: Obter detalhes do grupo E o status de membresia do usuário atual:**
        *   `GET /api/v1/groups/{group_id}?include=my_membership_status`
        *   A resposta incluiria algo como:

```json
            {
              \"data\": {
                // ... detalhes do grupo ...
                \"privacy_level\": \"private\",
                \"join_approval_mode\": \"approval\",
                \"my_membership_status\": null // ou {\"role\": \"member\", \"status\": \"active\"}, ou {\"status\": \"pending_approval\"}
              }
            }
```

    *   **Passo 2: Cliente Renderiza Botões Apropriados:**
        *   Se `my_membership_status` é `null` e `privacy_level` é `public` e `join_approval_mode` é `open`: Mostrar \"Juntar-se\".
        *   Se `my_membership_status` é `null` e `privacy_level` é `private` e `join_approval_mode` é `approval`: Mostrar \"Solicitar Entrada\".
        *   Se `my_membership_status.status` é `active`: Mostrar \"Sair do Grupo\", \"Convidar Membros\" (se permitido).
        *   Se `my_membership_status.role` é `admin/owner`: Mostrar \"Gerenciar Grupo\".
    *   **Passo 3: Cliente Envia Ação para Endpoints Específicos:**
        *   \"Juntar-se\" / \"Solicitar Entrada\": `POST /api/v1/groups/{group_id}/members`
        *   \"Sair do Grupo\": `DELETE /api/v1/groups/{group_id}/members/me`
        *   \"Convidar\": (se implementado) `POST /api/v1/groups/{group_id}/invites`

## 6. Serviço: \"Criar Grupo\" (Formulário de Criação)

*   **Funcionalidade UNA PHP:**
    *   `BxGroupsModule->service_create_group_form()`
    *   Retornaria o HTML do formulário para criar um grupo.

*   **Mapeamento para API \"Deeper\":**
    *   **Não um serviço que retorna UI.** O formulário é construído pelo cliente.
    *   O cliente pode precisar de dados para popular seletores no formulário (ex: lista de tipos de privacidade, se fosse dinâmica, mas aqui é fixa).
    *   Ao submeter, o cliente envia para: `POST /api/v1/groups`.
    *   A validação dos campos do formulário (ex: título obrigatório, slug único) é feita pelo backend (controller e/ou `GroupsRepo.create_group`).

## 7. Serviço: \"Gerenciar Membros do Grupo\" (Painel de Admin do Grupo)

*   **Funcionalidade UNA PHP:**
    *   `BxGroupsModule->service_manage_members_panel(int $group_id)`
    *   Retornaria HTML com uma tabela de membros e ações (promover, rebaixar, banir, aprovar).

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint Principal de Dados:** `GET /api/v1/groups/{group_id}/members?include=profile_details&status=active,pending_approval,invited` (para listar todos os relevantes para gerenciamento).
    *   **Endpoints de Ação (para cada membro):**
        *   `PUT /api/v1/groups/{group_id}/members/{member_profile_id}` (para mudar papel, aprovar).
        *   `DELETE /api/v1/groups/{group_id}/members/{member_profile_id}` (para remover/banir).
    *   **Responsabilidade do Cliente:** Construir a interface de gerenciamento, listando os membros e fornecendo botões/menus que chamam os endpoints de ação apropriados. O cliente também precisa verificar as permissões do usuário logado (se ele é admin/mod do grupo) antes de mostrar as opções de gerenciamento.

## Considerações:

*   **Permissões do Visualizador:** Muitos \"serviços\" do UNA levam em conta quem está visualizando para customizar a saída. Na API \"Deeper\", o cliente frequentemente precisará buscar o estado do recurso e o estado do usuário em relação a esse recurso (ex: é membro? qual papel?) para então renderizar a UI condicionalmente.
*   **Eficiência da API:** Para evitar que o cliente precise fazer muitas chamadas para construir uma visualização complexa, o parâmetro `include` nos endpoints `GET` é importante. Alternativamente, endpoints de \"sumário\" específicos podem ser criados se uma combinação particular de dados for frequentemente necessária.
*   **Lógica de Negócios:** A lógica de negócios mais complexa (ex: \"o que acontece quando o último admin sai de um grupo?\", \"pode um membro banido solicitar entrada novamente?\") residirá na Camada de Contexto/Serviço Elixir, que usa o `GroupsRepo`.

Este mapeamento ajuda a traduzir as expectativas de um sistema como o UNA para uma API RESTful, onde o cliente tem um papel mais ativo na construção da interface a partir dos dados fornecidos.