# Documentação Deeper: Módulo de Acesso a Dados para ACL (`AclRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemCore.AclRepo`, responsável por encapsular a lógica de consulta às tabelas de Controle de Acesso (ACL) do sistema UNA (`sys_acl_levels`, `sys_acl_actions`, `sys_acl_matrix`, `sys_acl_levels_members`, `sys_acl_actions_track`).

O `AclRepo` fornecerá funções para verificar se um determinado membro (com um `IDLevel` específico) tem permissão para realizar uma `IDAction`, considerando as regras da `sys_acl_matrix` e o status da membresia e rastreamento de ações.

**Localização do Código:** `lib/deeper/system_core/acl_repo.ex`

## Funções Principais (Exemplos):

O foco principal deste repositório é a verificação de permissões. Funções CRUD para as tabelas de ACL (criar níveis, ações, etc.) seriam parte da API de Administração (`07_studio_admin_api/`).

### 1. Verificação de Permissão de Ação

*   **`is_action_allowed(member_id :: integer(), action_name :: String.t(), module_name :: String.t() | nil, action_params :: map() | nil) :: {:ok, boolean(), String.t() | nil} | {:error, any()}`**
    *   Esta é a função central de verificação.
    *   **Argumentos:**
        *   `member_id`: O `id` da conta do usuário (`sys_accounts.id`).
        *   `action_name`: O nome da ação (ex: \"create_entry\", \"view_profile\") de `sys_acl_actions.Name`.
        *   `module_name`: (Opcional) O nome do módulo da ação (de `sys_acl_actions.Module`), para desambiguação se nomes de ação forem reutilizados entre módulos.
        *   `action_params`: (Opcional) Um mapa com parâmetros adicionais que podem ser necessários para verificar `AdditionalParamValue` na `sys_acl_matrix`.
    *   **Retorno:**
        *   `{:ok, true, nil}`: Ação permitida.
        *   `{:ok, false, \"reason_key\"}`: Ação não permitida, com uma chave de motivo (ex: \"level_not_allowed\", \"membership_expired\", \"action_limit_reached\", \"action_not_found\", \"level_not_found\").
        *   `{:error, reason}`: Erro na consulta.
    *   **Lógica Interna Detalhada:**
        1.  **Obter `IDAction`:**
            *   SQL: `SELECT ID, Countable, DisabledForLevels, AdditionalParamName FROM sys_acl_actions WHERE Name = ? AND (Module = ? OR ? IS NULL) LIMIT 1;` (parâmetros: `action_name`, `module_name`, `module_name`)
            *   Se não encontrar `IDAction`, retorna `{:ok, false, \"action_not_found\"}`.
        2.  **Obter `IDLevel` Ativo do Membro:**
            *   SQL:

```sql
                SELECT alm.IDLevel, al.Name as LevelName
                FROM sys_acl_levels_members alm
                JOIN sys_acl_levels al ON alm.IDLevel = al.ID
                WHERE alm.IDMember = ?
                  AND al.Active = 'yes'
                  AND STRFTIME('%Y-%m-%d %H:%M:%S', alm.DateStarts) <= STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime') -- ou UTC se tudo for UTC
                  AND (alm.DateExpires IS NULL OR STRFTIME('%Y-%m-%d %H:%M:%S', alm.DateExpires) > STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'))
                ORDER BY al.\"Order\" DESC, alm.DateStarts DESC -- Prioriza níveis mais altos ou mais recentes se houver múltiplos ativos
                LIMIT 1;
```

            *   Parâmetros: `member_id`.
            *   Se não encontrar `IDLevel` ativo, pode-se tentar um nível de visitante/padrão ou retornar `{:ok, false, \"level_not_found_or_inactive\"}`. (A lógica de nível de visitante precisa ser definida).
        3.  **Verificar `DisabledForLevels` (Bitmask na `sys_acl_actions`):**
            *   Se a ação tem `DisabledForLevels` configurado, verificar se o `IDLevel` do usuário está na bitmask de desabilitados. Se estiver, retorna `{:ok, false, \"action_disabled_for_level\"}`.
            *   Lógica de Bitmask: `(action.DisabledForLevels && (1 <<< (level_id - 1))) != 0`.
        4.  **Consultar `sys_acl_matrix`:**
            *   SQL: `SELECT AllowedCount, AllowedPeriodLen, AllowedPeriodStart, AllowedPeriodEnd, AdditionalParamValue FROM sys_acl_matrix WHERE IDLevel = ? AND IDAction = ? LIMIT 1;`
            *   Parâmetros: `IDLevel` (do passo 2), `IDAction` (do passo 1).
            *   Se não encontrar entrada na matriz, a ação não é explicitamente permitida para este nível. Retorna `{:ok, false, \"permission_not_in_matrix\"}`.
        5.  **Verificar `AdditionalParamValue`:**
            *   Se `sys_acl_actions.AdditionalParamName` e `sys_acl_matrix.AdditionalParamValue` estiverem definidos, e `action_params` foram passados, verificar se `action_params[action.AdditionalParamName]` corresponde a `matrix_entry.AdditionalParamValue`. Se não, retorna `{:ok, false, \"additional_param_mismatch\"}`.
        6.  **Verificar Período de Validade da Regra da Matriz (`AllowedPeriodStart`, `AllowedPeriodEnd`):**
            *   Se `matrix_entry.AllowedPeriodStart` e/ou `matrix_entry.AllowedPeriodEnd` estiverem definidos, verificar se a data/hora atual está dentro do período. Se não, retorna `{:ok, false, \"rule_period_expired\"}`.
        7.  **Verificar Ações Contáveis (se `action.Countable == 1`):**
            *   Se `matrix_entry.AllowedCount` for `NULL` ou `0`, a ação é ilimitada (dentro do período, se houver).
            *   Se `matrix_entry.AllowedCount > 0`:
                a.  **Consultar `sys_acl_actions_track`:**
                    *   SQL: `SELECT ActionsLeft, ValidSince FROM sys_acl_actions_track WHERE IDAction = ? AND IDMember = ? LIMIT 1;`
                    *   Parâmetros: `IDAction`, `member_id`.
                b.  **Lógica de Contagem e Período:**
                    *   Se não houver entrada em `sys_acl_actions_track` ou se `track_entry.ValidSince` for mais antigo que `NOW - matrix_entry.AllowedPeriodLen` (se `AllowedPeriodLen` definido e > 0):
                        *   O período de contagem resetou ou é o primeiro uso.
                        *   `actions_left_effective = matrix_entry.AllowedCount`.
                    *   Senão (entrada existe e está dentro do período):
                        *   `actions_left_effective = track_entry.ActionsLeft`.
                    *   Se `actions_left_effective <= 0`, retorna `{:ok, false, \"action_limit_reached\"}`.
                    *   **Se a ação for permitida e for ser executada, esta função NÃO deve decrementar `ActionsLeft`. Isso deve ser feito por uma função separada `decrement_action_count/2` chamada APÓS a ação ser concluída com sucesso.**
        8.  Se todas as verificações passarem, retorna `{:ok, true, nil}`.

### 2. Decrementar Contagem de Ação (para ações contáveis)

*   **`decrement_action_count(member_id :: integer(), action_id :: integer(), matrix_rule :: map()) :: :ok | {:error, any()}`**
    *   Chamada APÓS uma ação contável ser executada com sucesso.
    *   `matrix_rule` é o mapa da entrada da `sys_acl_matrix` para a ação/nível, contendo `AllowedCount` e `AllowedPeriodLen`.
    *   **Lógica:**
        1.  Consultar `sys_acl_actions_track` para `member_id` e `action_id`.
        2.  Se não existe entrada ou o `ValidSince` expirou (baseado em `matrix_rule.AllowedPeriodLen`):
            *   SQL: `INSERT OR REPLACE INTO sys_acl_actions_track (IDAction, IDMember, ActionsLeft, ValidSince) VALUES (?, ?, ?, STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'));`
            *   Parâmetros: `action_id`, `member_id`, `matrix_rule.AllowedCount - 1`.
        3.  Se existe entrada e está válida:
            *   SQL: `UPDATE sys_acl_actions_track SET ActionsLeft = ActionsLeft - 1 WHERE IDAction = ? AND IDMember = ?;`
            *   Parâmetros: `action_id`, `member_id`.

### 3. Funções Auxiliares de Leitura (Opcionais, mais para Admin API)

*   **`get_level(level_id :: integer()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   SQL: `SELECT * FROM sys_acl_levels WHERE ID = ?;`
*   **`get_action(action_id :: integer()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   SQL: `SELECT * FROM sys_acl_actions WHERE ID = ?;`
*   **`get_member_level_details(member_id :: integer(), level_id :: integer()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   SQL: `SELECT * FROM sys_acl_levels_members WHERE IDMember = ? AND IDLevel = ? ORDER BY DateStarts DESC LIMIT 1;`

### Estruturas de Dados de Retorno:

*   As funções que retornam dados (como `get_level`) devem mapear as linhas SQL para mapas Elixir.
*   A função `is_action_allowed` retorna uma tupla indicando o resultado da verificação.

### Considerações Importantes:

*   **Nível de Visitante/Padrão:** A lógica para determinar o `IDLevel` de um usuário não autenticado (visitante) ou um usuário sem uma entrada explícita em `sys_acl_levels_members` precisa ser definida. O UNA geralmente tem um nível padrão para visitantes (ex: IDLevel 1) e um nível padrão para membros logados sem nível especial (ex: IDLevel 2).
*   **Performance:** As queries para `sys_acl_matrix` e `sys_acl_levels_members` são críticas para a performance. Garantir que `IDLevel`, `IDAction`, e `IDMember` estejam bem indexados é crucial.
*   **Caching:** Informações de permissão (especialmente da `sys_acl_matrix` que não muda com frequência) podem ser candidatas a caching para reduzir acessos ao banco de dados, mas com cuidado para invalidação quando as regras mudarem.
*   **Timestamp e Timezones:** Consistência no uso de UTC ou `localtime` para comparações de `DATETIME` (armazenados como TEXT) é vital. O SQLite `STRFTIME` com o modificador `'localtime'` usa o fuso horário do sistema. Se a aplicação padronizar UTC, use `STRFTIME('...', 'now', 'utc')` ou armazene timestamps Unix.