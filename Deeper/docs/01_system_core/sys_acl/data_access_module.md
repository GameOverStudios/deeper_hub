# Documentação Deeper: Módulo de Acesso a Dados para ACL (`Deeper.SystemCore.AclRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemCore.AclRepo`. Sua principal responsabilidade é interagir com as tabelas do sistema de Controle de Acesso (ACL) do UNA (`sys_acl_levels`, `sys_acl_actions`, `sys_acl_levels_members`, `sys_acl_matrix`, `sys_acl_actions_track`) para fornecer informações e realizar verificações de permissão.

Este repositório será usado internamente por outros serviços e controllers da API \"Deeper\" para determinar se um usuário autenticado tem permissão para realizar uma ação específica.

## Responsabilidades Principais:

*   Buscar o nível de ACL ativo de um membro (perfil).
*   Obter o ID de uma ação ACL pelo seu nome e módulo.
*   Verificar as permissões de um nível ACL para uma ação específica na matriz de ACL.
*   Buscar, verificar e atualizar o rastreamento de uso para ações ACL contáveis.

## Tabelas ACL (Esquema SQLite - Migrações a serem detalhadas separadamente):

*   **`sys_acl_levels`**: Define os níveis de membresia.
    *   Campos: `ID`, `Name`, `Icon`, `Description`, `Active`, `Purchasable`, `Removable`, `QuotaSize`, `QuotaNumber`, `QuotaMaxFileSize`, `Order`, `PasswordExpired`, `PasswordExpiredNotify`.
*   **`sys_acl_actions`**: Define as ações controláveis.
    *   Campos: `ID`, `Module`, `Name`, `AdditionalParamName`, `Title`, `Desc`, `Countable`, `DisabledForLevels`.
*   **`sys_acl_levels_members`**: Associa membros (perfis) a níveis.
    *   Campos: `IDMember` (sys_profiles.id), `IDLevel` (sys_acl_levels.ID), `DateStarts`, `DateExpires`, `State`, `TransactionID`.
*   **`sys_acl_matrix`**: A matriz de permissão.
    *   Campos: `IDLevel`, `IDAction`, `AllowedCount`, `AllowedPeriodLen`, `AllowedPeriodStart`, `AllowedPeriodEnd`, `AdditionalParamValue`.
*   **`sys_acl_actions_track`**: Rastreia o uso de ações contáveis.
    *   Campos: `IDAction`, `IDMember`, `ActionsLeft`, `ValidSince`.

*(Os `CREATE TABLE` statements para estas tabelas serão definidos em `docs/01_system_core/sys_acl/migrations/`)*

## Funções Públicas Principais e Lógica SQL:

*   **`get_member_active_level(profile_id :: integer()) :: {:ok, acl_level_info :: map()} | {:error, :not_found | any()}`**
    *   Busca o nível de ACL ativo para um `profile_id`.
    *   `current_ts = System.os_time(:second)` (ou o formato de data/hora armazenado).
    *   SQL:

```sql
        SELECT
            slm.IDLevel,
            sl.Name AS LevelName,
            slm.DateStarts,
            slm.DateExpires
        FROM sys_acl_levels_members slm
        JOIN sys_acl_levels sl ON slm.IDLevel = sl.ID
        WHERE
            slm.IDMember = ? AND
            (slm.DateStarts <= ? OR slm.DateStarts IS NULL) AND
            (slm.DateExpires >= ? OR slm.DateExpires IS NULL) AND
            sl.Active = 'yes' -- ou 1 se booleano
            -- Adicionar verificação de slm.State se aplicável (ex: 'active')
        ORDER BY slm.IDLevel DESC -- Ou alguma lógica de prioridade se múltiplos níveis ativos
        LIMIT 1;
```

        (A comparação de `DateStarts` e `DateExpires` precisa corresponder ao formato de data armazenado. Se forem timestamps Unix, a comparação é direta. Se strings ISO8601, o SQLite pode compará-las lexicograficamente se estiverem no formato UTC correto).
    *   Retorna `%{id_level: ..., level_name: ..., ...}` ou `{:error, :not_found}`.

*   **`get_action_details(action_module :: String.t(), action_name :: String.t()) :: {:ok, action_info :: map()} | {:error, :not_found | any()}`**
    *   Busca detalhes de uma ação ACL.
    *   SQL: `SELECT ID, Name, Module, Countable, DisabledForLevels, AdditionalParamName FROM sys_acl_actions WHERE Module = ? AND Name = ? LIMIT 1;`
    *   Retorna `%{id_action: ..., name: ..., module: ..., countable: (0 ou 1), disabled_for_levels: ..., ...}`.

*   **`get_matrix_permission(acl_level_id :: integer(), action_id :: integer()) :: {:ok, matrix_entry :: map() | nil} | {:error, any()}`**
    *   Busca a entrada da matriz de permissão.
    *   SQL: `SELECT AllowedCount, AllowedPeriodLen, AllowedPeriodStart, AllowedPeriodEnd, AdditionalParamValue FROM sys_acl_matrix WHERE IDLevel = ? AND IDAction = ? LIMIT 1;`
    *   Retorna o mapa da entrada ou `nil` se não houver permissão explícita.

*   **`get_action_track(profile_id :: integer(), action_id :: integer()) :: {:ok, track_entry :: map() | nil} | {:error, any()}`**
    *   Busca o rastreamento de uso de uma ação contável.
    *   SQL: `SELECT ActionsLeft, ValidSince FROM sys_acl_actions_track WHERE IDMember = ? AND IDAction = ? LIMIT 1;`
    *   Retorna `%{actions_left: ..., valid_since: ...}` ou `nil`.

*   **`update_action_track(profile_id :: integer(), action_id :: integer(), actions_left :: integer(), valid_since_ts :: integer()) :: :ok | {:error, any()}`**
    *   Insere ou atualiza um registro em `sys_acl_actions_track`.
    *   SQL (SQLite): `INSERT OR REPLACE INTO sys_acl_actions_track (IDMember, IDAction, ActionsLeft, ValidSince) VALUES (?, ?, ?, ?);`

---
### Função de Verificação de Permissão (Lógica Principal - pode ser um serviço separado que usa este Repo):

*   **`Deeper.SystemCore.AclService.is_action_allowed(profile_id :: integer(), acl_level_id :: integer(), action_module :: String.t(), action_name :: String.t(), additional_param_value :: any() | nil) :: {:ok, boolean()} | {:error, reason :: atom()}`**
    *(Esta função é mais um serviço do que uma função direta do Repo, mas depende fortemente do AclRepo).*
    1.  `{:ok, action_info} = AclRepo.get_action_details(action_module, action_name)`
        *   Se erro, retorna `{:ok, false}` (ou erro específico).
    2.  **Verifica `DisabledForLevels`**:
        *   `disabled_mask = action_info.disabled_for_levels`
        *   `level_bit = Bitwise.bsl(1, acl_level_id - 1)` (assumindo que os níveis são 1-based para a máscara)
        *   Se `Bitwise.band(disabled_mask, level_bit) != 0`, retorna `{:ok, false}`.
    3.  `{:ok, matrix_entry_or_nil} = AclRepo.get_matrix_permission(acl_level_id, action_info.id_action)`
    4.  Se `matrix_entry_or_nil == nil` (nenhuma permissão explícita na matriz):
        *   Retorna `{:ok, false}` (política de negação padrão).
    5.  Else (`matrix_entry = matrix_entry_or_nil`):
        *   **Verifica `AdditionalParamValue`**:
            *   Se `action_info.additional_param_name` não for nulo E `matrix_entry.additional_param_value` não for nulo:
                *   Se `additional_param_value != matrix_entry.additional_param_value`, retorna `{:ok, false}`.
        *   **Se Ação Contável (`action_info.countable == 1`):**
            *   `{:ok, track_entry_or_nil} = AclRepo.get_action_track(profile_id, action_info.id_action)`
            *   `allowed_count = matrix_entry.allowed_count`
            *   `period_len_seconds = matrix_entry.allowed_period_len * 86400` (se `AllowedPeriodLen` for em dias).
            *   `current_ts = System.os_time(:second)`.
            *   Se `track_entry_or_nil == nil` (primeira vez usando a ação):
                *   Se `allowed_count == 0` (ilimitado) ou `allowed_count > 0`, retorna `{:ok, true}`. (A atualização do track será feita após a ação).
                *   Else (ex: `allowed_count` é `nil` mas deveria ser numérico, ou regra estranha), `{:ok, false}`.
            *   Else (`track_entry = track_entry_or_nil`):
                *   `valid_since = track_entry.valid_since`
                *   Se `current_ts > valid_since + period_len_seconds` (período expirou):
                    *   // Resetar o contador para este novo período
                    *   Se `allowed_count == 0` ou `allowed_count > 0`, retorna `{:ok, true}`.
                *   Else (dentro do período):
                    *   Se `track_entry.actions_left > 0`, retorna `{:ok, true}`.
                    *   Se `allowed_count == 0` (ilimitado, mesmo dentro do período, mas `actions_left` é finito?), retorna `{:ok, true}`. (A lógica do UNA para `actions_left` com `allowed_count == 0` precisa ser verificada; geralmente `actions_left` não seria usado se ilimitado).
                    *   Else, `{:ok, false}` (sem ações restantes).
        *   **Se Ação Não Contável:**
            *   Retorna `{:ok, true}` (permissão concedida pela entrada na matriz).
    6.  Caso padrão (se alguma lógica não cobrir), `{:ok, false}`.

*   **`Deeper.SystemCore.AclService.consume_action(profile_id, acl_level_id, action_module, action_name)`**
    *   Chamado *após* uma ação contável ser realizada com sucesso.
    1.  Busca `action_info` e `matrix_entry`.
    2.  Se `action_info.countable == 1`:
        *   Busca `track_entry_or_nil`.
        *   Calcula `new_actions_left` e `new_valid_since` baseado nas regras acima.
        *   Chama `AclRepo.update_action_track(profile_id, action_info.id_action, new_actions_left, new_valid_since)`.

## Considerações:

*   **Formato de Datas em `sys_acl_levels_members` e `sys_acl_matrix`:** O UNA armazena datas como `DATETIME`. Para SQLite, se forem armazenadas como strings ISO8601, as comparações de data/hora precisam ser feitas corretamente. Funções de data do SQLite (`strftime`, ` julianday`) podem ser necessárias. Se armazenadas como timestamps Unix (inteiros), a comparação é mais simples.
*   **Máscara de Bits `DisabledForLevels`:** A lógica para checar a máscara de bits precisa ser implementada corretamente.
*   **`AllowedPeriodLen` Unidade:** A coluna `AllowedPeriodLen` no UNA é geralmente em dias. Precisa ser convertida para segundos para comparações de timestamp.
*   **Complexidade da Lógica `is_action_allowed`:** Esta função é central e complexa. Testes unitários extensivos são cruciais.
*   **Cache:** Configurações de ACL (níveis, ações, matriz) raramente mudam. Elas são candidatas ideais para cachear na memória da aplicação para evitar acessos repetidos ao DB. `sys_acl_levels_members` e `sys_acl_actions_track` são mais dinâmicos.

Este `AclRepo` e o serviço associado são fundamentais para a segurança e o controle de funcionalidades da API \"Deeper\".