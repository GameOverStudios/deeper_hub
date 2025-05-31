# Documentação Deeper: Esquema do Banco de Dados para Módulo de Enquetes (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas relacionadas ao módulo de Enquetes (`deeper_polls`).

## Tabela Principal: `deeper_polls` (Enquetes)

```sql
CREATE TABLE IF NOT EXISTS deeper_polls (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL, -- Criador da enquete
  question TEXT NOT NULL, -- A pergunta da enquete
  slug TEXT NOT NULL UNIQUE, -- Slug para URL amigável
  description TEXT, -- Descrição adicional ou contexto para a enquete (opcional)
  allow_multiple_choices INTEGER NOT NULL DEFAULT 0, -- 0 = voto único, 1 = múltiplas escolhas permitidas
  results_visibility TEXT NOT NULL DEFAULT 'after_vote'
    CHECK(results_visibility IN ('always', 'after_vote', 'after_close', 'owner_only')),
    -- 'always': Qualquer um vê a qualquer hora
    -- 'after_vote': Só vê após votar
    -- 'after_close': Só vê após a enquete fechar
    -- 'owner_only': Apenas o criador e admins podem ver os resultados até fechar (ou sempre)
  closes_at INTEGER, -- Unix Timestamp para quando a enquete fecha automaticamente (opcional, NULL = nunca fecha manualmente)
  status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open', 'closed', 'draft')),
  total_votes_count INTEGER NOT NULL DEFAULT 0, -- Contagem denormalizada de todos os votos nesta enquete
  -- Outros contadores como views, comments_count podem ser adicionados
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE -- Se o criador for deletado, suas enquetes também são
);

CREATE INDEX IF NOT EXISTS idx_dp_profile_id ON deeper_polls(profile_id);
CREATE INDEX IF NOT EXISTS idx_dp_slug ON deeper_polls(slug);
CREATE INDEX IF NOT EXISTS idx_dp_status ON deeper_polls(status);
CREATE INDEX IF NOT EXISTS idx_dp_closes_at ON deeper_polls(closes_at);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_poll_options (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  poll_id INTEGER NOT NULL,
  option_text TEXT NOT NULL,
  order_index INTEGER NOT NULL DEFAULT 0, -- Para ordenação manual das opções
  votes_count INTEGER NOT NULL DEFAULT 0, -- Contagem denormalizada de votos para esta opção específica
  FOREIGN KEY (poll_id) REFERENCES deeper_polls(id) ON DELETE CASCADE -- Se a enquete for deletada, suas opções também são
);

CREATE INDEX IF NOT EXISTS idx_dpo_poll_id_order_index ON deeper_poll_options(poll_id, order_index);
-- Não é necessário um índice em votes_count a menos que se ordene frequentemente por ele.
```

```sql
CREATE TABLE IF NOT EXISTS deeper_poll_votes (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- Ou usar uma chave primária composta (poll_id, profile_id, option_id)
  poll_id INTEGER NOT NULL,
  option_id INTEGER NOT NULL,
  profile_id INTEGER NOT NULL, -- Perfil do votante
  voted_at INTEGER NOT NULL, -- Unix Timestamp
  -- Se allow_multiple_choices = FALSE para a enquete, então (poll_id, profile_id) deve ser UNIQUE.
  -- Se allow_multiple_choices = TRUE, então (poll_id, profile_id, option_id) deve ser UNIQUE.
  -- SQLite não suporta UNIQUE constraints condicionais baseadas em valores de outra tabela diretamente.
  -- A lógica de unicidade (um voto por usuário ou um voto por opção por usuário)
  -- precisará ser gerenciada pela aplicação ou por triggers complexos.
  -- Para simplificar, vamos assumir que a aplicação gerencia isso e a tabela permite múltiplos votos
  -- de um usuário em diferentes opções se a enquete permitir, ou garante um único voto por usuário na enquete
  -- se não permitir múltiplas escolhas.
  -- Uma constraint UNIQUE (poll_id, profile_id, option_id) é uma boa base.
  UNIQUE (poll_id, profile_id, option_id),
  FOREIGN KEY (poll_id) REFERENCES deeper_polls(id) ON DELETE CASCADE,
  FOREIGN KEY (option_id) REFERENCES deeper_poll_options(id) ON DELETE CASCADE,
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_dpv_poll_id_profile_id ON deeper_poll_votes(poll_id, profile_id);
CREATE INDEX IF NOT EXISTS idx_dpv_option_id ON deeper_poll_votes(option_id);
CREATE INDEX IF NOT EXISTS idx_dpv_profile_id ON deeper_poll_votes(profile_id);
```

*   **`allow_multiple_choices`**: Define se um usuário pode selecionar mais de uma opção.
*   **`results_visibility`**: Controla quem pode ver os resultados e quando.
*   **`closes_at`**: Data de término opcional.
*   **`total_votes_count`**: Contagem total de todos os votos dados em todas as opções desta enquete.

## Tabela: `deeper_poll_options` (Opções de Resposta para uma Enquete)

*   Cada linha representa uma opção de resposta para uma `poll_id` específica.
*   **`votes_count`**: Contagem denormalizada de votos para esta opção, para facilitar a exibição dos resultados.

## Tabela: `deeper_poll_votes` (Votos dos Usuários nas Opções)

*   Registra cada voto individual.
*   A constraint `UNIQUE (poll_id, profile_id, option_id)` garante que um usuário não vote na mesma opção múltiplas vezes.
*   A lógica para enquetes de voto único (onde um usuário só pode votar em uma opção para toda a enquete) precisaria ser implementada na camada de aplicação: ao registrar um novo voto, removeria o voto anterior do mesmo usuário para aquela `poll_id` se `deeper_polls.allow_multiple_choices` for `0`.

Este conjunto de tabelas forma a base para o módulo de enquetes. A lógica de atualização dos contadores denormalizados (`total_votes_count` em `deeper_polls` e `votes_count` em `deeper_poll_options`) será crucial e residirá no `PollsRepo`.