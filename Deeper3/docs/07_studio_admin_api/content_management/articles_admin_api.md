# API de Administração: Gerenciamento de Artigos/Posts (`deeper_articles`)

Endpoints da API para administradores e moderadores gerenciarem o conteúdo do módulo `deeper_articles`.

**Permissões:** Todos os endpoints aqui requerem um papel de administrador ou moderador com permissões específicas para gerenciar artigos.

## Endpoints

### 1. Listar Todos os Artigos (Visão Administrativa)

*   **`GET /admin/articles`**
*   **Autenticação:** Admin/Moderador Requerida.
*   **Diferenças da API Pública (`GET /articles`):**
    *   Retorna artigos de **todos** os usuários.
    *   Pode listar artigos com **qualquer status** (`draft`, `published`, `archived`, `pending_review`, etc.) por padrão ou via filtro.
    *   Pode incluir informações adicionais relevantes para administração (ex: IP do autor, histórico de moderação).
*   **Query Parameters:**
    *   `profile_id` (integer): Filtrar por autor.
    *   `status` (string): Filtrar por status.
    *   `visibility` (string).
    *   `q` (string): Termo de busca.
    *   `page`, `per_page`.
    *   `sort_by` (ex: `created_at_desc`, `updated_at_desc`).
    *   `include` (ex: `author_profile,categories,featured_image,moderation_logs`).
*   **Resposta de Sucesso (200 OK):** Lista paginada de todos os artigos com metadados administrativos.

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"title\": \"Artigo Pendente de Revisão\",
          \"status\": \"pending_review\",
          \"author_profile\": { \"id\": 45, \"name\": \"Usuário X\" },
          \"created_at\": 1699980000,
          // ... outros campos do artigo ...
          \"admin_notes\": \"Conteúdo sensível, verificar fontes.\" // Exemplo de campo admin
        }
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"title\": \"Título Corrigido pelo Admin\",
      \"status\": \"published\", // Ex: Admin aprova um artigo 'pending_review'
      \"visibility\": \"public\",
      \"slug\": \"titulo-corrigido-admin\", // Admin pode corrigir slug
      // \"author_profile_id\": 50, // Reatribuir autoria (ação poderosa)
      \"admin_notes\": \"Conteúdo verificado e aprovado.\"
    }
```

```json
    {
      \"action\": \"set_status\", // ou \"delete\", \"change_visibility\"
      \"article_ids\": [10, 15, 22],
      \"payload\": { // Depende da ação
        \"status\": \"archived\" // para action \"set_status\"
        // \"reason\": \"Conteúdo duplicado\" // para action \"delete\"
      }
    }
```

```json
    {
      \"message\": \"Ação em lote processada.\",
      \"results\": [
        { \"article_id\": 10, \"status\": \"success\" },
        { \"article_id\": 15, \"status\": \"success\" },
        { \"article_id\": 22, \"status\": \"error\", \"reason\": \"Artigo não encontrado.\" }
      ]
    }
```

```elixir
        # Exemplo no Contexto
        def update_article(article_id, attrs, current_user_profile) do
          with {:ok, article} <- ArticlesRepo.get_article_record(article_id) do # get_article_record sem joins
            if article.profile_id == current_user_profile.id or UserPermissions.is_admin?(current_user_profile) do
              ArticlesRepo.update_article_record(article, attrs) # Função de update no repo
            else
              {:error, :forbidden}
            end
          end
        end
```

*   **Respostas de Erro:** `401`, `403`.

### 2. Obter Detalhes de Qualquer Artigo (Visão Administrativa)

*   **`GET /admin/articles/{id_or_slug}`**
*   **Autenticação:** Admin/Moderador Requerida.
*   **Diferenças da API Pública:** Pode retornar campos adicionais ou não aplicar restrições de visibilidade que se aplicariam a um usuário comum.
*   **Query Parameters:** `include` (ex: `author_profile,categories,featured_image,revision_history,moderation_logs`).
*   **Resposta de Sucesso (200 OK):** Objeto completo do artigo com metadados administrativos.
*   **Respostas de Erro:** `401`, `403`, `404`.

### 3. Atualizar Qualquer Artigo (Ação Administrativa)

*   **`PUT /admin/articles/{id}`** (ou `PATCH`)
*   **Autenticação:** Admin/Moderador Requerida.
*   **Diferenças da API Pública:** Permite editar artigos de qualquer usuário. Pode permitir a alteração de campos que o autor não pode (ex: `author_profile_id` para reatribuir autoria, `published_at` para retroagir publicação).
*   **Corpo da Requisição (JSON):** Campos a serem atualizados, incluindo campos administrativos.

*   **Resposta de Sucesso (200 OK):** Objeto do artigo atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 4. Excluir Qualquer Artigo (Ação Administrativa)

*   **`DELETE /admin/articles/{id}`**
*   **Autenticação:** Admin/Moderador Requerida.
*   **Diferenças da API Pública:** Permite excluir artigos de qualquer usuário.
*   **Opções (Query Param ou Corpo):**
    *   `reason` (string): Motivo da exclusão (para log de auditoria).
    *   `soft_delete` (boolean, default: true): Se true, apenas muda o status para \"deleted_by_admin\" ou similar, em vez de remover do DB.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Respostas de Erro:** `401`, `403`, `404`.

### 5. Ações de Moderação em Lote (Opcional)

*   **`POST /admin/articles/bulk-actions`**
*   **Autenticação:** Admin/Moderador Requerida.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Sumário das ações realizadas.

*   **Respostas de Erro:** `400`, `401`, `403`.

## Considerações para Repositórios e Contextos:

*   **`Deeper.Content.ArticlesRepo`:**
    *   A função `list_articles/2` precisará de lógica para não aplicar filtros de `profile_id` ou `status='published'` quando chamada por um contexto administrativo. Isso pode ser feito passando um parâmetro `as_admin: true` ou tendo funções separadas como `list_all_articles_admin/2`.
    *   Funções de update/delete também podem precisar de uma variante `_as_admin` que bypassa verificações de propriedade.
*   **`Deeper.Content.Articles` (Contexto/Serviço):**
    *   As funções de contexto (ex: `update_article/3`) verificarão se o `current_user` (passado pelo controller) é o proprietário OU um administrador.

*   **Log de Auditoria:** Ações administrativas significativas (mudança de status, exclusão, reatribuição de autoria) devem gerar entradas em uma tabela de auditoria (análoga a `sys_audit`). Isso seria feito na Camada de Contexto/Serviço após uma operação bem-sucedida.

Estes endpoints administrativos fornecem as ferramentas básicas para a moderação e gerenciamento do conteúdo de artigos. Abordagens similares seriam aplicadas para outros módulos de conteúdo.