# Documentação Deeper: Esquema do BD para Conexões de Perfil (`sys_connections` - SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas que gerenciam os relacionamentos (conexões) entre perfis no sistema \"Deeper\", baseadas nas tabelas `sys_profiles_conn_*` do UNA.

**Nota:** Todas as referências a `profile_id`, `initiator_id`, `content_id` nestas tabelas apontam para `sys_profiles.id`.

## Tabela: `deeper_profile_connections` (Tabela Unificada e Flexível)

Em vez de replicar exatamente `sys_profiles_conn_friends`, `sys_profiles_conn_subscriptions`, etc., podemos considerar uma tabela mais unificada para \"Deeper\" que possa armazenar diferentes tipos de conexões, o que pode ser mais flexível e fácil de consultar para certos cenários. No entanto, para manter a compatibilidade conceitual com o UNA e a clareza inicial, vamos definir tabelas separadas como no UNA, e depois podemos discutir a unificação.

### Tabela: `deeper_conn_friends` (Amizades)
Corresponde a `sys_profiles_conn_friends`.

```sql
CREATE TABLE IF NOT EXISTS deeper_conn_friends (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  initiator_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) que iniciou/aceitou por último
  content_id INTEGER NOT NULL,   -- ID do perfil (sys_profiles.id) que foi o alvo/aceitou
  mutual INTEGER NOT NULL DEFAULT 0 CHECK(mutual IN (0,1)), -- 0 para solicitação pendente, 1 para amizade mútua confirmada
  added INTEGER NOT NULL,        -- Unix Timestamp da criação da conexão ou da última atualização de status

  UNIQUE (initiator_id, content_id), -- Garante que não haja múltiplas entradas na mesma direção
  -- UNIQUE (content_id, initiator_id), -- Se quisermos garantir que não haja entradas duplicadas invertidas para o mesmo par, isso é melhor tratado na lógica da aplicação
  FOREIGN KEY (initiator_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (content_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_dcf_initiator_content ON deeper_conn_friends(initiator_id, content_id, mutual);
CREATE INDEX IF NOT EXISTS idx_dcf_content_initiator ON deeper_conn_friends(content_id, initiator_id, mutual);
```

```sql
    -- Se 'deeper_conn_friends' só armazena amizades confirmadas (mútuas)
    -- CREATE TABLE IF NOT EXISTS deeper_conn_friends (
    --   profile1_id INTEGER NOT NULL, -- ID do primeiro perfil no par (ex: menor ID)
    --   profile2_id INTEGER NOT NULL, -- ID do segundo perfil no par (ex: maior ID)
    --   added INTEGER NOT NULL,
    --   PRIMARY KEY (profile1_id, profile2_id),
    --   FOREIGN KEY (profile1_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
    --   FOREIGN KEY (profile2_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
    -- );
```

```sql
CREATE TABLE IF NOT EXISTS deeper_conn_subscriptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  initiator_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) que está seguindo (o fã)
  content_id INTEGER NOT NULL,   -- ID do perfil (sys_profiles.id) que está sendo seguido
  added INTEGER NOT NULL,        -- Unix Timestamp de quando começou a seguir

  UNIQUE (initiator_id, content_id), -- Um perfil só pode seguir outro uma vez
  FOREIGN KEY (initiator_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (content_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_dcs_initiator_id ON deeper_conn_subscriptions(initiator_id);
CREATE INDEX IF NOT EXISTS idx_dcs_content_id ON deeper_conn_subscriptions(content_id);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_conn_bans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  initiator_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) que está bloqueando
  content_id INTEGER NOT NULL,   -- ID do perfil (sys_profiles.id) que está sendo bloqueado
  added INTEGER NOT NULL,        -- Unix Timestamp de quando o bloqueio foi aplicado
  -- module TEXT, -- No UNA, pode haver um contexto de módulo para o ban. Para Deeper, pode ser global.

  UNIQUE (initiator_id, content_id), -- Um perfil só pode bloquear outro uma vez
  FOREIGN KEY (initiator_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (content_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_dcb_initiator_id ON deeper_conn_bans(initiator_id);
CREATE INDEX IF NOT EXISTS idx_dcb_content_id ON deeper_conn_bans(content_id);
```

*   **`initiator_id`**: O perfil que enviou a solicitação ou o \"menor ID\" do par para consistência.
*   **`content_id`**: O perfil que recebeu a solicitação ou o \"maior ID\" do par.
*   **`mutual`**:
    *   `0`: Indica uma solicitação de amizade pendente de `initiator_id` para `content_id`.
    *   `1`: Indica uma amizade mútua estabelecida. Quando uma solicitação é aceita, uma entrada com `mutual = 1` é criada (ou a existente é atualizada), e a entrada de solicitação original (se houver uma separada) é removida ou a entrada com `mutual=0` é atualizada para `mutual=1`.
*   **`added`**: Timestamp de quando a solicitação foi feita ou a amizade foi confirmada.
*   **Lógica de Amizade:** Uma amizade mútua entre Perfil A e Perfil B pode ser representada por uma única linha onde `initiator_id = A`, `content_id = B`, `mutual = 1` (assumindo uma convenção, ex: `initiator_id < content_id`). Ou, duas linhas: A->B (solicitação), B->A (aceitação), ambas marcadas como `mutual=1`. A abordagem do UNA original precisa ser verificada aqui. Se `mutual` em `sys_profiles_conn_friends` significa que *ambos* os lados confirmaram, então uma única linha por par de amigos com `mutual=1` é suficiente. Se `sys_profiles_conn_friends` guarda solicitações e amizades, o campo `mutual` diferencia.

    *Revisando o UNA, `sys_profiles_conn_friends` geralmente armazena a conexão quando ela é mútua (ou seja, `mutual` é sempre `1` ou implícito). As solicitações podem estar em uma tabela `sys_friend_requests` ou implícitas se `mutual=0` fosse usado.*

    **Alternativa Simplificada para Amizades (se `mutual` sempre `1` na tabela de amigos):**

    Para este exercício, vamos manter a estrutura inicial com `initiator_id`, `content_id` e `mutual` para flexibilidade em representar solicitações pendentes dentro da mesma tabela, se necessário, ou para espelhar mais de perto uma possível interpretação do UNA.

### Tabela: `deeper_conn_subscriptions` (Seguir/Assinaturas)
Corresponde a `sys_profiles_conn_subscriptions`.

*   **`initiator_id`**: O seguidor.
*   **`content_id`**: O perfil seguido.
*   Esta é uma conexão unidirecional.

### Tabela: `deeper_conn_bans` (Bloqueios)
Corresponde a `sys_profiles_conn_bans`.

*   **`initiator_id`**: Quem bloqueou.
*   **`content_id`**: Quem foi bloqueado.
*   Implica que `initiator_id` não quer ver/interagir com `content_id`, e/ou `content_id` não pode ver/interagir com `initiator_id`. A lógica exata do bloqueio é definida pela aplicação.

## Considerações Adicionais:

*   **Solicitações de Amizade:** Se as solicitações de amizade não forem representadas em `deeper_conn_friends` com `mutual=0`, uma tabela separada como `deeper_conn_friend_requests(id, requester_id, requested_id, added)` poderia ser usada. Quando uma solicitação é aceita, uma entrada é criada em `deeper_conn_friends` (com `mutual=1`) e a solicitação é removida.
*   **Contadores:** A criação/remoção de entradas nestas tabelas de conexão deve acionar a atualização de contadores relevantes nas tabelas de dados de perfil (ex: `bx_persons_data.friends_count`, `bx_organizations_data.fans_count`). Isso será tratado pela lógica nos `data_access_modules` ou serviços.
*   **Unicidade e Direção:** Para amizades, a lógica da aplicação deve garantir que se A é amigo de B, B também é amigo de A, e isso é representado consistentemente (ex: uma única linha com `mutual=1` e `initiator_id < content_id`, ou duas linhas se for assim que o UNA funciona).

Este esquema fornece a base para gerenciar diferentes tipos de conexões entre perfis na plataforma \"Deeper\".
**Próximo Passo:** Definir os módulos de migração Elixir para criar estas tabelas.