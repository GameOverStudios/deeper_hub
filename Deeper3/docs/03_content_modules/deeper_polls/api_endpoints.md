# Documentação Deeper: Endpoints da API para Módulo de Enquetes

Este documento especifica os endpoints RESTful para o módulo de Enquetes (`deeper_polls`) do \"Deeper\".

Lembre-se das [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md). Todos os endpoints abaixo estão sob o prefixo `/api/v1`.

## Enquetes (`/polls`)

### 1. Criar Nova Enquete

*   **`POST /polls`**
*   **Autenticação:** Requerida. O `profile_id` do criador virá do JWT.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"question\": \"Qual sua linguagem de programação funcional favorita?\",
      \"slug\": \"linguagem-funcional-favorita\", // Opcional, pode ser gerado
      \"description\": \"Escolha uma ou mais se aplicável.\", // Opcional
      \"allow_multiple_choices\": true, // Default: false
      \"results_visibility\": \"always\", // \"always\", \"after_vote\", \"after_close\", \"owner_only\" - Default: \"after_vote\"
      \"closes_at\": 1700000000, // Opcional, Unix timestamp UTC
      \"options\": [
        { \"option_text\": \"Elixir\", \"order_index\": 0 },
        { \"option_text\": \"Clojure\", \"order_index\": 1 },
        { \"option_text\": \"Haskell\", \"order_index\": 2 },
        { \"option_text\": \"Scala\", \"order_index\": 3 }
      ]
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"profile_id\": 45,
        \"question\": \"Qual sua linguagem de programação funcional favorita?\",
        \"slug\": \"linguagem-funcional-favorita\",
        \"description\": \"Escolha uma ou mais se aplicável.\",
        \"allow_multiple_choices\": 1, // 1 para true
        \"results_visibility\": \"always\",
        \"closes_at\": 1700000000,
        \"status\": \"open\",
        \"total_votes_count\": 0,
        \"created_at\": 1699980000,
        \"updated_at\": 1699980000,
        \"creator_profile\": { \"id\": 45, \"name\": \"Nome do Criador\" },
        \"options\": [
          { \"id\": 1, \"poll_id\": 1, \"option_text\": \"Elixir\", \"order_index\": 0, \"votes_count\": 0 },
          { \"id\": 2, \"poll_id\": 1, \"option_text\": \"Clojure\", \"order_index\": 1, \"votes_count\": 0 },
          // ...
        ]
      }
    }
```

```json
    {
      \"option_ids\": [1] // ID da opção ou lista de IDs se allow_multiple_choices=true
    }
```

```json
    {
      \"message\": \"Voto registrado com sucesso.\",
      \"data\": { // Opcional: A enquete atualizada com novos resultados (se visibilidade permitir)
        \"id\": 1,
        \"total_votes_count\": 150,
        \"options\": [
          { \"id\": 1, \"option_text\": \"Elixir\", \"votes_count\": 70, \"voted_by_user\": true },
          { \"id\": 2, \"option_text\": \"Clojure\", \"votes_count\": 30, \"voted_by_user\": false }
          // ...
        ],
        \"user_voted_options\": [1]
      }
    }
```

```json
    {
      \"data\": {
        \"poll_id\": 1,
        \"voted_option_ids\": [1, 3] // Lista de option_ids que o usuário votou
      }
    }
    // Ou 404 se o usuário não votou nesta enquete
```

```json
    {
      \"option_ids\": [1] // Para remover votos de opções específicas se múltipla escolha
                       // Se vazio e voto único, remove o voto único do usuário.
    }
```

*   **Resposta de Sucesso (201 Created):**

*   **Respostas de Erro:** `400` (validação, ex: sem opções), `401`, `403`.

### 2. Listar Enquetes

*   **`GET /polls`**
*   **Autenticação:** Opcional. Filtra por visibilidade se não autenticado ou não for o proprietário.
*   **Query Parameters:**
    *   `profile_id` (integer): Filtrar por criador.
    *   `status` (string): `open`, `closed`, `draft`.
    *   `q` (string): Buscar por título/pergunta.
    *   `page`, `per_page`.
    *   `sort_by` (ex: `created_at_desc`, `total_votes_count_desc`).
    *   `include` (string CSV, ex: `creator_profile,options_summary`).
        *   `options_summary` poderia retornar apenas o texto das opções e suas contagens de votos, sem todos os detalhes.
*   **Resposta de Sucesso (200 OK):** Lista paginada de enquetes.
*   **Respostas de Erro:** `400`.

### 3. Obter uma Enquete Específica

*   **`GET /polls/{id_or_slug}`**
*   **Autenticação:** Opcional. Lógica de `results_visibility` será aplicada no backend.
*   **Query Parameters:**
    *   `include` (string CSV, ex: `creator_profile,options,my_votes`).
        *   `options`: inclui todas as opções com suas contagens de votos (se permitido pela `results_visibility`).
        *   `my_votes`: inclui as opções que o usuário logado votou (um array de `option_id`s ou um mapa).
*   **Resposta de Sucesso (200 OK):** Objeto da enquete.
    *   As opções incluirão `votes_count` se a visibilidade dos resultados permitir.
    *   Pode incluir um campo `user_voted_options: [1, 3]` se `include=my_votes` e o usuário votou.
    *   Pode incluir um campo `can_see_results: true/false` e `can_vote: true/false` com base no usuário logado e no estado da enquete.
*   **Respostas de Erro:** `401`, `403` (se a enquete for privada), `404`.

### 4. Atualizar uma Enquete (Detalhes da Enquete, não opções)

*   **`PUT /polls/{id}`** ou **`PATCH /polls/{id}`**
*   **Autenticação:** Requerida (proprietário ou admin).
*   **Corpo da Requisição (JSON):** Campos a atualizar (ex: `question`, `description`, `closes_at`, `status`).
    *   Não se deve permitir alterar `allow_multiple_choices` após votos terem sido dados.
    *   Opções são gerenciadas por endpoints separados.
*   **Resposta de Sucesso (200 OK):** Objeto da enquete atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 5. Excluir uma Enquete

*   **`DELETE /polls/{id}`**
*   **Autenticação:** Requerida (proprietário ou admin).
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Ação do Backend:** Deleta a enquete, suas opções (`deeper_poll_options`) e votos (`deeper_poll_votes`) devido ao `ON DELETE CASCADE`.

## Opções de Enquete (geralmente gerenciadas no contexto da criação/edição da enquete, mas podem ter endpoints dedicados se necessário)

### 1. Adicionar Opção a uma Enquete Existente

*   **`POST /polls/{poll_id}/options`**
*   **Autenticação:** Requerida (proprietário da enquete, se a enquete ainda estiver \"aberta\" para edição de opções).
*   **Corpo da Requisição (JSON):** `{ \"option_text\": \"Nova Opção\", \"order_index\": 4 }`
*   **Resposta de Sucesso (201 Created):** Objeto da opção criada.
*   **Respostas de Erro:** `400`, `401`, `403` (ex: enquete fechada ou já com votos), `404`.

### 2. Atualizar uma Opção de Enquete

*   **`PUT /polls/{poll_id}/options/{option_id}`** (ou `PUT /poll-options/{option_id}`)
*   **Autenticação:** Requerida (proprietário).
*   **Corpo (JSON):** `{ \"option_text\": \"Texto da Opção Editado\", \"order_index\": 1 }`
*   **Resposta (200 OK):** Objeto da opção atualizada.

### 3. Excluir uma Opção de Enquete

*   **`DELETE /polls/{poll_id}/options/{option_id}`** (ou `DELETE /poll-options/{option_id}`)
*   **Autenticação:** Requerida (proprietário).
*   **Resposta (200 OK / 204 No Content):**
*   **Ação do Backend:** Deleta a opção e seus votos. Recalcula `total_votes_count` na enquete.

## Votos em Enquetes

### 1. Registrar Voto(s) em uma Enquete

*   **`POST /polls/{poll_id}/vote`**
*   **Autenticação:** Requerida.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK ou 201 Created):**

*   **Respostas de Erro:** `400` (opção inválida, voto duplicado se não permitido), `401`, `403` (enquete fechada, já votou e não pode mudar), `404` (enquete/opção não encontrada), `409` (conflito, ex: tentar votar em múltiplas opções quando não permitido).

### 2. Obter Votos do Usuário Logado para uma Enquete

*   **`GET /polls/{poll_id}/my-votes`**
*   **Autenticação:** Requerida.
*   **Resposta de Sucesso (200 OK):**

### 3. (Opcional) Remover Voto(s) de um Usuário de uma Enquete
    (Se a funcionalidade de \"retirar voto\" for permitida)

*   **`DELETE /polls/{poll_id}/vote`**
*   **Autenticação:** Requerida.
*   **Corpo da Requisição (JSON) (opcional):**

*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Ação do Backend:** Remove o(s) voto(s) e recalcula contagens.
*   **Respostas de Erro:** `401`, `403`, `404` (sem voto para remover).

Estes endpoints cobrem as funcionalidades essenciais de um módulo de enquetes, desde a criação até a votação e visualização de resultados. A lógica de visibilidade dos resultados e as regras de votação (única vs. múltipla) serão importantes nos controllers e no `PollsRepo`.