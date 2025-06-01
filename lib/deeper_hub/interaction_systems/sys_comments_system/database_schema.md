# Documentação Deeper: Esquema do Banco de Dados para Comentários (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite para um sistema de comentários unificado no \"Deeper\".

## Tabela: `deeper_comments` (Tabela Principal de Comentários)

```sql
CREATE TABLE IF NOT EXISTS deeper_comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  system_name TEXT NOT NULL, -- Identificador do sistema de comentários (ex: 'deeper_articles', 'bx_persons_profile')
  object_id INTEGER NOT NULL, -- ID da entidade sendo comentada (ex: article_id, profile_id)
  author_profile_id INTEGER NOT NULL, -- FK para sys_profiles.id do autor do comentário
  parent_id INTEGER DEFAULT 0, -- ID do comentário pai (para respostas aninhadas, 0 se for raiz)
  level INTEGER NOT NULL DEFAULT 0, -- Nível de aninhamento (0 para raiz, 1 para resposta direta, etc.)
  text TEXT NOT NULL, -- Conteúdo do comentário
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'pending_approval', 'spam', 'deleted_by_user', 'deleted_by_admin')),
  -- Campos para votos/score no próprio comentário (do UNA sys_cmts_ids)
  votes INTEGER NOT NULL DEFAULT 0,       -- Contagem de votos (ex: up/down ou estrelas)
  score INTEGER NOT NULL DEFAULT 0,       -- Pontuação líquida
  reactions_up INTEGER NOT NULL DEFAULT 0, -- Contagem de reações positivas
  reactions_down INTEGER NOT NULL DEFAULT 0, -- Contagem de reações negativas
  reports INTEGER NOT NULL DEFAULT 0,     -- Contagem de denúncias
  replies_count INTEGER NOT NULL DEFAULT 0, -- Contagem de respostas diretas a este comentário
  created_at INTEGER NOT NULL, -- Unix Timestamp
  updated_at INTEGER NOT NULL, -- Unix Timestamp
  FOREIGN KEY (author_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (parent_id) REFERENCES deeper_comments(id) ON DELETE CASCADE ON UPDATE CASCADE -- Auto-referência para respostas
);

CREATE INDEX IF NOT EXISTS idx_deeper_comments_system_object ON deeper_comments(system_name, object_id, status, created_at);
CREATE INDEX IF NOT EXISTS idx_deeper_comments_author_id ON deeper_comments(author_profile_id);
CREATE INDEX IF NOT EXISTS idx_deeper_comments_parent_id ON deeper_comments(parent_id);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_comment_votes_track (
  comment_id INTEGER NOT NULL, -- FK para deeper_comments.id
  voter_profile_id INTEGER NOT NULL, -- FK para sys_profiles.id
  vote_type TEXT NOT NULL DEFAULT 'score' CHECK(vote_type IN ('score', 'reaction', 'report_type')), -- Tipo de interação
  value INTEGER NOT NULL, -- Ex: +1 para upvote, -1 para downvote; ou ID da reação; ou valor da estrela
  -- Para 'report_type', 'value' poderia ser um código para o tipo de denúncia
  voted_at INTEGER NOT NULL, -- Unix Timestamp
  PRIMARY KEY (comment_id, voter_profile_id, vote_type), -- Um usuário pode ter um score E uma reação em um comentário
  FOREIGN KEY (comment_id) REFERENCES deeper_comments(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (voter_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
);
```

*   **`system_name`**: Identifica o \"contexto\" ou \"objeto de comentários\" ao qual este comentário pertence (ex: qual módulo e tipo de conteúdo).
*   **`object_id`**: ID da entidade principal que está sendo comentada.
*   **`parent_id`**: Para comentários aninhados. `ON DELETE CASCADE` aqui significa que se um comentário pai for excluído, todas as suas respostas também serão.
*   **`level`**: Profundidade do aninhamento, útil para renderização.
*   **Contadores (`votes`, `score`, `reactions_up`, `replies_count`, etc.)**: Estes são agregados. Eles seriam atualizados por triggers no DB ou pela lógica da aplicação quando um voto/reação/resposta é adicionado.

## Tabela: `deeper_comment_votes_track` (Rastreamento de Votos/Reações em Comentários)

Esta tabela rastreia quem votou/reagiu a qual comentário, similar a `sys_cmts_votes_track` ou `sys_cmts_scores_track` do UNA.

*   **`comment_id`**: O comentário que recebeu o voto/reação.
*   **`voter_profile_id`**: Quem fez o voto/reação.
*   **`vote_type`**: Para diferenciar entre um \"score\" (up/down), uma \"reação\" específica (like, love), ou até mesmo um tipo de \"denúncia\".
*   **`value`**: O valor da interação. Para scores, +1 ou -1. Para reações, um ID que representa a reação.
*   A chave primária permite que um usuário possa, por exemplo, dar um \"upvote\" (score) e também uma \"reação\" (like) a um mesmo comentário, se o sistema permitir isso como `vote_type`s diferentes.

**Atualização de Contadores em `deeper_comments`:**
Quando uma nova linha é inserida/atualizada/excluída em `deeper_comment_votes_track`, os campos de contagem (`votes`, `score`, `reactions_up`, etc.) na tabela `deeper_comments` devem ser atualizados. Isso pode ser feito:
1.  **Na lógica da aplicação Elixir:** Após cada operação de voto/reação, recalcular e atualizar os contadores.
2.  **Com Triggers no SQLite:** Definir triggers no banco de dados para automatizar essas atualizações. (Mais complexo de gerenciar em migrações, mas mais robusto para consistência de dados).

Para a API, a lógica da aplicação Elixir é uma abordagem comum.