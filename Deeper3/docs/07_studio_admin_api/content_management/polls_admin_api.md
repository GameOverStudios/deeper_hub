# API de Administração: Gerenciamento de Enquetes (`deeper_polls`)

Endpoints da API para administradores e moderadores globais gerenciarem as enquetes criadas por usuários no módulo `deeper_polls`.

**Permissões:** Todos os endpoints aqui requerem um papel de administrador do site ou um super-moderador com permissões para gerenciar todas as enquetes.

## Endpoints para Enquetes

### 1. Listar Todas as Enquetes (Visão Administrativa)

*   **`GET /admin/polls`**
*   **Autenticação:** Admin Requerida.
*   **Diferenças da API Pública (`GET /polls`):**
    *   Retorna enquetes de **todos** os criadores.
    *   Pode listar enquetes com **qualquer status** (`draft`, `open`, `closed`) por padrão ou via filtro.
*   **Query Parameters:**
    *   `profile_id` (integer): Filtrar por criador.
    *   `status` (string).
    *   `q` (string): Termo de busca (pergunta, descrição).
    *   `page`, `per_page`.
    *   `sort_by` (ex: `created_at_desc`, `total_votes_count_desc`, `closes_at_asc`).
    *   `include` (ex: `creator_profile,options_summary,admin_notes`).
*   **Resposta de Sucesso (200 OK):** Lista paginada de todas as enquetes.

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"question\": \"Enquete com conteúdo a ser revisado?\",
          \"status\": \"draft\", // Admin pode ver rascunhos de outros
          \"creator_profile\": { \"id\": 45, \"name\": \"Usuário A\" },
          \"total_votes_count\": 0,
          \"created_at\": 1699980000,
          // ... outros campos da enquete ...
          \"admin_notes\": \"Aguardando aprovação do conteúdo.\"
        }
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"question\": \"Pergunta da Enquete Revisada (Admin)\",
      \"status\": \"closed\", // Ex: Admin fecha uma enquete manualmente
      \"results_visibility\": \"always\",
      // \"profile_id\": 70, // Reatribuir criador (cuidado com a lógica de propriedade)
      \"admin_notes\": \"Enquete fechada por admin.\"
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"poll_id\": 10,
          \"option_id\": 25,
          \"option_details\": { \"option_text\": \"Elixir\" },
          \"profile_id\": 77,
          \"profile_details\": { \"name\": \"Votante Um\" },
          \"voted_at\": 1699990000
        }
      ]
    }
```

*   **Respostas de Erro:** `401`, `403`.

### 2. Obter Detalhes de Qualquer Enquete (Visão Administrativa)

*   **`GET /admin/polls/{id_or_slug}`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `include` (ex: `creator_profile,all_options_with_votes,vote_details_by_user,moderation_logs`).
    *   `all_options_with_votes`: Retorna todas as opções e suas contagens de votos, independentemente da `results_visibility`.
    *   `vote_details_by_user`: Poderia listar quem votou em quê (ação sensível, para auditoria).
*   **Resposta de Sucesso (200 OK):** Objeto completo da enquete com detalhes administrativos.
*   **Respostas de Erro:** `401`, `403`, `404`.

### 3. Atualizar Qualquer Enquete (Ação Administrativa)

*   **`PUT /admin/polls/{id}`** (ou `PATCH`)
*   **Autenticação:** Admin Requerida.
*   **Diferenças da API Pública:** Permite editar enquetes de qualquer criador. Pode forçar status, alterar `closes_at`, `results_visibility`, ou até mesmo o texto da pergunta/opções (com ressalvas se já houver votos).
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.

*   **Atenção:** Editar o texto de opções ou adicionar/remover opções de uma enquete que já recebeu votos pode invalidar os resultados ou a intenção dos votantes. Tais ações devem ser manuseadas com extremo cuidado ou bloqueadas.
*   **Resposta de Sucesso (200 OK):** Objeto da enquete atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 4. Excluir Qualquer Enquete (Ação Administrativa)

*   **`DELETE /admin/polls/{id}`**
*   **Autenticação:** Admin Requerida.
*   **Opções (Query Param ou Corpo):**
    *   `reason` (string): Motivo da exclusão.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Ação do Backend:** Deleta a enquete, suas opções e votos (`ON DELETE CASCADE`).
*   **Respostas de Erro:** `401`, `403`, `404`.

## Endpoints para Opções de Enquete (Visão Administrativa)

Administradores podem precisar gerenciar opções de qualquer enquete.

### 1. Listar Opções de Qualquer Enquete

*   **`GET /admin/polls/{poll_id}/options`**
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK):** Lista de opções da enquete, incluindo `votes_count` para cada.

### 2. Adicionar Opção a Qualquer Enquete (Ação Administrativa)

*   **`POST /admin/polls/{poll_id}/options`**
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):** `{ \"option_text\": \"Nova Opção (Admin)\", \"order_index\": 5 }`
*   **Atenção:** Adicionar opções a uma enquete com votos existentes pode ser problemático para a integridade dos resultados. Geralmente, isso só deve ser permitido se a enquete for um rascunho ou não tiver votos.
*   **Resposta de Sucesso (201 Created):** Objeto da opção criada.

### 3. Atualizar Opção de Qualquer Enquete (Ação Administrativa)

*   **`PUT /admin/polls/{poll_id}/options/{option_id}`** (ou `PUT /admin/poll-options/{option_id}`)
*   **Autenticação:** Admin Requerida.
*   **Corpo (JSON):** `{ \"option_text\": \"Texto Editado por Admin\", \"order_index\": 0 }`
*   **Atenção:** Editar o texto de uma opção que já recebeu votos pode alterar o significado para os votantes.
*   **Resposta (200 OK):** Objeto da opção atualizada.

### 4. Excluir Opção de Qualquer Enquete (Ação Administrativa)

*   **`DELETE /admin/polls/{poll_id}/options/{option_id}`** (ou `DELETE /admin/poll-options/{option_id}`)
*   **Autenticação:** Admin Requerida.
*   **Ação do Backend:** Deleta a opção e seus votos. Recalcula `total_votes_count` na enquete e `votes_count` nas opções restantes (se a lógica de contagem for afetada).
*   **Atenção:** Remover uma opção com votos altera fundamentalmente os resultados da enquete.
*   **Resposta (200 OK / 204 No Content):**

## Endpoints para Votos em Enquetes (Visão Administrativa)

### 1. Listar Todos os Votos de uma Enquete

*   **`GET /admin/polls/{poll_id}/votes`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `profile_id` (filtrar por votante), `option_id`, `page`, `per_page`, `include=profile_details,option_details`.
*   **Resposta de Sucesso (200 OK):** Lista paginada de votos detalhados.

### 2. (Opcional) Remover Voto Específico (Ação de Moderação Extrema)

*   **`DELETE /admin/poll-votes/{vote_id}`** (Usando o ID da tabela `deeper_poll_votes`)
*   **Autenticação:** Admin Requerida.
*   **Ação do Backend:** Remove o voto e recalcula `votes_count` na opção e `total_votes_count` na enquete.
*   **Atenção:** Ação muito sensível, deve ser usada com extrema cautela e bem logada.
*   **Resposta (200 OK / 204 No Content):**

## Considerações para Repositórios e Contextos:

*   **`Deeper.Content.PollsRepo`:**
    *   Funções de listagem e obtenção precisarão de variantes ou flags `as_admin: true` para bypassar filtros de status, privacidade ou visibilidade de resultados.
    *   Funções CRUD para enquetes e opções precisarão permitir operações por administradores em qualquer enquete/opção.
    *   A lógica de atualização de contadores (`total_votes_count`, `options.votes_count`) deve ser robusta, especialmente quando opções ou votos são modificados/removidos por um admin.
*   **`Deeper.Content.Polls` (Contexto/Serviço):**
    *   Verificará as permissões de administrador do `current_user_profile`.
    *   Lidará com as implicações de ações administrativas (ex: o que acontece se um admin edita o texto de uma opção que já tem muitos votos? A enquete deve ser resetada? Um aviso deve ser dado?).
    *   Pode implementar lógica para \"soft delete\" de enquetes ou opções em vez de exclusão física.
*   **Log de Auditoria:** Todas as ações administrativas (criar, editar, excluir enquetes/opções, remover votos) devem ser logadas.

Estes endpoints fornecem as ferramentas para que administradores tenham controle total sobre o módulo de enquetes.