# Documentação Deeper: Mapeamento da Lógica de \"Serviço\" para API (Módulo `deeper_polls`)

No sistema UNA, um módulo de enquetes (`bx_polls`) forneceria \"serviços\" para exibir enquetes em blocos (ex: \"Enquete Ativa\", \"Últimas Enquetes\"), mostrar resultados, e lidar com o formulário de votação. Com a API RESTful \"Deeper\", essas funcionalidades são traduzidas em endpoints que retornam dados JSON, com o cliente (frontend) responsável pela apresentação e interatividade.

## 1. Serviço: \"Exibir Enquete Ativa\" (para um bloco na página inicial ou sidebar)

*   **Funcionalidade UNA PHP (Exemplo Hipotético):**
    *   `BxPollsModule->service_display_active_poll()`
    *   Retornaria HTML da enquete atualmente ativa (ou uma aleatória se várias), com opções para votar.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/polls`
    *   **Query Parameters:**
        *   `status=open`
        *   `sort_by=created_at_desc` (ou `total_votes_count_desc` para uma popular, ou uma lógica customizada para \"enquete em destaque\")
        *   `per_page=1`
        *   `page=1`
        *   `include=options,my_votes` (para que o cliente saiba se o usuário já votou e quais opções).
    *   **Lógica no `Deeper.Content.PollsRepo`:** A função `list_polls/2` com os filtros apropriados.
    *   **Responsabilidade do Cliente:**
        1.  Buscar os dados da enquete.
        2.  Renderizar a pergunta e as opções.
        3.  Com base em `poll.allow_multiple_choices`, renderizar checkboxes ou radio buttons.
        4.  Com base em `poll.results_visibility` e se o usuário já votou (informação de `my_votes` ou de uma chamada separada `GET /polls/{id}/my-votes`), decidir se mostra os resultados parciais ou apenas as opções de voto.
        5.  Ao votar, chamar `POST /api/v1/polls/{poll_id}/vote`.

## 2. Serviço: \"Listar Últimas Enquetes\" (com resultados resumidos)

*   **Funcionalidade UNA PHP:**
    *   `BxPollsModule->service_latest_polls_list(int $count = 5)`
    *   Retornaria HTML de uma lista de enquetes recentes.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/polls`
    *   **Query Parameters:**
        *   `sort_by=created_at_desc`
        *   `status=open,closed` (para mostrar tanto ativas quanto recém-fechadas)
        *   `per_page={N}`
        *   `page=1`
        *   `include=options_summary,creator_profile` (onde `options_summary` poderia retornar apenas o texto das opções e a contagem de votos para cada uma, se a visibilidade permitir).
    *   **Lógica no `Deeper.Content.PollsRepo`:** A função `list_polls/2`. O `include=options_summary` exigiria que o repo buscasse e agregasse os dados das opções.
    *   **Responsabilidade do Cliente:** Renderizar a lista de enquetes, mostrando resultados conforme permitido pela `results_visibility` de cada enquete.

## 3. Serviço: \"Visualizar Resultados da Enquete\" (Página de Resultados)

*   **Funcionalidade UNA PHP:**
    *   `BxPollsModule->service_view_poll_results(int $poll_id)`
    *   Retornaria HTML com gráficos/barras de porcentagem dos resultados.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/polls/{id_or_slug}`
    *   **Query Parameters:** `include=options,creator_profile`
    *   **Lógica no `Deeper.Content.PollsRepo`:** A função `get_poll/2` retornaria a enquete e suas opções, cada uma com seu `votes_count`.
    *   **Responsabilidade do Cliente:**
        1.  Verificar a `results_visibility` da enquete e se o usuário tem permissão para ver os resultados (ex: já votou, ou a enquete fechou). Essa lógica de permissão pode ser parcialmente feita no backend e retornada como um campo `can_see_results: true/false`.
        2.  Se permitido, usar os `votes_count` de cada opção e o `total_votes_count` da enquete para calcular porcentagens e renderizar gráficos ou barras de resultado.

## 4. Serviço: \"Formulário de Votação\"

*   **Funcionalidade UNA PHP:** Parte do `service_display_active_poll()` ou de uma página de enquete.
*   **Mapeamento para API \"Deeper\":**
    *   **Não um serviço que retorna UI.**
    *   **Fluxo:**
        1.  Cliente obtém dados da enquete via `GET /api/v1/polls/{id_or_slug}?include=options,my_votes`.
        2.  Cliente renderiza o formulário com as opções.
        3.  Se o usuário já votou e a enquete é de voto único, o formulário pode estar desabilitado ou mostrar o voto atual.
        4.  Se a enquete estiver fechada (`status=closed` ou `closes_at` passou), o formulário de votação é desabilitado.
        5.  Ao submeter, o cliente envia para: `POST /api/v1/polls/{poll_id}/vote` com `{ \"option_ids\": [...] }`.
    *   **Lógica no `Deeper.Content.PollsRepo` e Camada de Contexto:**
        *   `PollsRepo.cast_vote/3` lida com o registro do voto e atualização dos contadores.
        *   A Camada de Contexto (ex: `Deeper.Content.Polls`) antes de chamar o repo, verificaria se a enquete está aberta para votação e se o usuário tem permissão para votar (ex: não votou ainda em enquete de voto único).

## 5. Serviço: \"Criar Nova Enquete\" (Formulário de Criação)

*   **Funcionalidade UNA PHP:**
    *   `BxPollsModule->service_create_poll_form()`
    *   Retornaria HTML do formulário.

*   **Mapeamento para API \"Deeper\":**
    *   **Não um endpoint que retorna UI.** O formulário é construído pelo cliente.
    *   O cliente pode precisar de informações sobre limites (ex: número máximo de opções), se houver.
    *   Ao submeter, o cliente envia para: `POST /api/v1/polls`.
    *   Validações são tratadas pelo backend.

## Considerações Específicas para Enquetes:

*   **Visibilidade dos Resultados (`results_visibility`):**
    *   Esta lógica é crucial. A API, ao retornar uma enquete (`GET /polls/{id}`), deve decidir se inclui os `votes_count` nas opções.
    *   Se `results_visibility == 'always'`, sempre incluir.
    *   Se `results_visibility == 'after_vote'`, incluir apenas se o `profile_id` do usuário logado tiver um voto registrado para aquela `poll_id`.
    *   Se `results_visibility == 'after_close'`, incluir apenas se `status == 'closed'` ou `closes_at` tiver passado.
    *   Se `results_visibility == 'owner_only'`, incluir apenas se o `profile_id` do usuário logado for o criador da enquete (ou admin).
    *   A API pode adicionar um campo booleano `results_are_visible_to_user: true/false` na resposta da enquete para ajudar o cliente.
*   **Voto Único vs. Múltiplo (`allow_multiple_choices`):**
    *   O cliente renderiza radio buttons (voto único) ou checkboxes (múltiplo).
    *   O backend (`PollsRepo.cast_vote/3`) reforça essa regra. Para voto único, ele deve remover qualquer voto anterior do usuário naquela enquete antes de adicionar o novo.
*   **Encerramento de Enquetes (`closes_at`, `status`):**
    *   Uma tarefa agendada no backend (cron job) pode ser necessária para mudar o `status` de enquetes para `closed` quando `closes_at` for atingido.
    *   A API não permitirá votos em enquetes com `status = 'closed'`.

A API para enquetes deve fornecer dados suficientes para que o cliente implemente uma experiência de usuário rica e interativa, respeitando as configurações de cada enquete.