# Documentação Deeper: Lógica de Controle de Acesso (ACL)

Este documento descreve como a lógica de Controle de Acesso (ACL) do sistema UNA será integrada e utilizada pelo backend \"Deeper\" para proteger os endpoints da API e controlar as ações dos usuários.

**Objetivo Principal:** Garantir que os usuários autenticados só possam realizar ações e acessar recursos para os quais têm permissão, com base em seus níveis de membresia e nas regras definidas no sistema ACL do UNA.

**Nota:** Esta seção foca na *utilização* e *verificação* do ACL pelo backend. A API para *gerenciar* as configurações de ACL (criar níveis, definir ações, modificar a matriz) será parte da \"API do Studio/Admin\" (`07_studio_admin_api/`).

## Componentes do ACL do UNA Relevantes para \"Deeper\":

As seguintes tabelas do esquema UNA são cruciais para a lógica de ACL:

1.  **`sys_acl_levels`**:
    *   Define os diferentes níveis de membresia (ex: Visitante, Membro Grátis, Membro Premium).
    *   Contém `ID`, `Name`, `Purchasable`, `Removable`, cotas, etc.

2.  **`sys_acl_actions`**:
    *   Define as ações específicas que podem ser controladas no sistema.
    *   Contém `ID`, `Module`, `Name` (da ação, ex: `view profile`, `post comment`), `Countable`, `DisabledForLevels`.
    *   **Mapeamento Crucial:** Será necessário um mapeamento claro entre estas `Name` de ações e as operações/endpoints da API \"Deeper\".

3.  **`sys_acl_levels_members`**:
    *   Associa um `IDMember` (que no UNA é o `sys_profiles.id`, então precisaremos do `profile_id` do usuário) a um `IDLevel`.
    *   Contém `DateStarts` e `DateExpires` para a validade da membresia no nível.
    *   O backend \"Deeper\" precisará determinar o `IDLevel` ativo do usuário logado. Esta informação pode ser incluída no payload do JWT para otimizar as buscas.

4.  **`sys_acl_matrix`**:
    *   A tabela central que concede permissões.
    *   Liga `IDLevel` a `IDAction`.
    *   `AllowedCount`: Quantas vezes a ação pode ser realizada (se `sys_acl_actions.Countable` for true).
    *   `AllowedPeriodLen`: Duração do período para `AllowedCount` (ex: por dia, por semana).
    *   `AdditionalParamValue`: Para permissões mais granulares baseadas em um parâmetro adicional da ação.

5.  **`sys_acl_actions_track`**:
    *   Rastreia o uso de ações contáveis (`Countable`) por membro.
    *   Contém `IDAction`, `IDMember`, `ActionsLeft`, `ValidSince`.

## Integração da Lógica de ACL na API \"Deeper\":

### 1. Obtenção do Nível de ACL do Usuário:

*   Durante o processo de login (`POST /api/v1/auth/login`), após verificar as credenciais:
    1.  Obter o `profile_id` do usuário (da tabela `sys_profiles` associada à `sys_accounts.id`).
    2.  Consultar `sys_acl_levels_members` para encontrar o `IDLevel` ativo para esse `profile_id`.
        *   SQL: `SELECT IDLevel FROM sys_acl_levels_members WHERE IDMember = ? AND (DateStarts <= CURRENT_TIMESTAMP_SQLITE_FUNCTION) AND (DateExpires IS NULL OR DateExpires >= CURRENT_TIMESTAMP_SQLITE_FUNCTION) ORDER BY DateStarts DESC LIMIT 1;`
        *   (A função de timestamp precisa ser a correta para comparar com os formatos de data/hora armazenados).
    3.  O `IDLevel` obtido (ou um nível padrão para visitantes/não logados) deve ser incluído no payload do JWT. Ex: `claim \"acl_level_id\": 5`.

### 2. Verificação de Permissão (Middleware ou Função de Verificação):

Para cada endpoint da API que corresponda a uma ação protegida pelo ACL do UNA:

*   **Identificar a Ação do UNA:** O controller da API ou um middleware precisa saber qual `sys_acl_actions.Name` (ou `IDAction`) corresponde à operação do endpoint. Esse mapeamento pode ser:
    *   Codificado diretamente.
    *   Definido em uma configuração.
    *   Inferido de metadados associados à rota.
*   **Função de Verificação `check_acl(profile_id, acl_level_id, action_name, params_adicionais)`:**
    1.  Obter `IDAction` de `sys_acl_actions` usando `action_name` (e o módulo, se necessário).
    2.  Verificar `sys_acl_actions.DisabledForLevels`: Se o `acl_level_id` do usuário estiver nesta máscara de bits, a permissão é negada.
    3.  Consultar `sys_acl_matrix`:
        *   SQL: `SELECT AllowedCount, AllowedPeriodLen, AdditionalParamValue FROM sys_acl_matrix WHERE IDLevel = ? AND IDAction = ?;`
        *   Se não houver entrada, a permissão é negada (a menos que haja uma regra padrão de \"permitir se não especificado\", o que é incomum para ACLs).
    4.  **Para Ações Contáveis (`sys_acl_actions.Countable = 1`):**
        *   Consultar `sys_acl_actions_track`:
            *   SQL: `SELECT ActionsLeft, ValidSince FROM sys_acl_actions_track WHERE IDMember = ? AND IDAction = ?;`
        *   Verificar se `ActionsLeft > 0`.
        *   Verificar se o período (`ValidSince` + `AllowedPeriodLen` de `sys_acl_matrix`) ainda é válido. Se expirou, resetar `ActionsLeft` para `AllowedCount` e atualizar `ValidSince`.
        *   Se a permissão for concedida e a ação realizada, decrementar `ActionsLeft` (ou inserir/atualizar o registro em `sys_acl_actions_track`). Isso deve ser feito atomicamente.
    5.  **Verificar `AdditionalParamValue`:** Se `sys_acl_matrix.AdditionalParamValue` estiver definido, a função `check_acl` pode precisar de `params_adicionais` para comparar com este valor.
    6.  Retornar `true` (permitido) ou `false` (negado).

### 3. Aplicação no Fluxo da Requisição:

*   Um middleware Phoenix pode ser usado para interceptar requisições para endpoints protegidos.
*   O middleware extrai `profile_id` e `acl_level_id` do JWT.
*   Chama a função `check_acl/4`.
*   Se `check_acl` retornar `false`, o middleware responde com `403 Forbidden`.
*   Se `true`, a requisição prossegue para o controller.

### 4. Módulos de Acesso a Dados para ACL (`Deeper.SystemCore.AclRepo` - Interno):

Um módulo como `Deeper.SystemCore.AclRepo` encapsularia as queries SQL para as tabelas `sys_acl_*`.

*   **`get_active_level_for_member(profile_id :: integer()) :: {:ok, acl_level_id :: integer()} | {:error, :not_found}`**
    *   SQL mencionado acima.

*   **`get_action_id(action_module :: String.t(), action_name :: String.t()) :: {:ok, action_id :: integer()} | {:error, :not_found}`**
    *   SQL: `SELECT ID FROM sys_acl_actions WHERE Module = ? AND Name = ? LIMIT 1;`

*   **`check_matrix_permission(acl_level_id :: integer(), action_id :: integer()) :: {:ok, matrix_entry :: map() | nil} | {:error, any()}`**
    *   SQL: `SELECT AllowedCount, AllowedPeriodLen, AdditionalParamValue, DisabledForLevels FROM sys_acl_matrix LEFT JOIN sys_acl_actions ON sys_acl_matrix.IDAction = sys_acl_actions.ID WHERE sys_acl_matrix.IDLevel = ? AND sys_acl_matrix.IDAction = ? LIMIT 1;`
    *   (Modificado para também pegar `DisabledForLevels` para checagem mais cedo, ou fazer duas queries).

*   **`get_action_track(profile_id :: integer(), action_id :: integer()) :: {:ok, track_entry :: map() | nil} | {:error, any()}`**
    *   SQL: `SELECT ActionsLeft, ValidSince FROM sys_acl_actions_track WHERE IDMember = ? AND IDAction = ? LIMIT 1;`

*   **`update_action_track(profile_id, action_id, new_actions_left, new_valid_since)`**
    *   SQL: `INSERT OR REPLACE INTO sys_acl_actions_track (IDMember, IDAction, ActionsLeft, ValidSince) VALUES (?, ?, ?, ?);` (SQLite `INSERT OR REPLACE`).

## Tabelas de ACL (Esquema SQLite):

Os `CREATE TABLE` statements para `sys_acl_levels`, `sys_acl_actions`, `sys_acl_levels_members`, `sys_acl_matrix`, `sys_acl_actions_track` precisarão ser definidos no `docs/00_core_concepts/database_schema_sqlite.md` e ter suas respectivas migrações.

**Exemplo `sys_acl_levels` (SQLite):**

```sql
CREATE TABLE IF NOT EXISTS sys_acl_levels (
  ID INTEGER PRIMARY KEY AUTOINCREMENT,
  Name TEXT NOT NULL UNIQUE,
  Icon TEXT, -- Caminho ou classe do ícone
  Description TEXT,
  Active TEXT NOT NULL DEFAULT 'no' CHECK(Active IN ('yes', 'no')), -- 'yes'/'no' ou 0/1
  Purchasable TEXT NOT NULL DEFAULT 'yes' CHECK(Purchasable IN ('yes', 'no')),
  Removable TEXT NOT NULL DEFAULT 'yes' CHECK(Removable IN ('yes', 'no')),
  QuotaSize INTEGER NOT NULL DEFAULT 0, -- Em bytes
  QuotaNumber INTEGER NOT NULL DEFAULT 0, -- Número de arquivos
  QuotaMaxFileSize INTEGER NOT NULL DEFAULT 0, -- Em bytes
  \"Order\" INTEGER NOT NULL DEFAULT 0, -- Renomeado de Order para evitar conflito com palavra chave SQL
  PasswordExpired INTEGER NOT NULL DEFAULT 0, -- Dias para expirar
  PasswordExpiredNotify INTEGER NOT NULL DEFAULT 0 -- Dias antes para notificar
);
```

*(As outras tabelas de ACL seguiriam um padrão similar de adaptação para SQLite).*

## Considerações de Performance:

*   As verificações de ACL podem adicionar overhead a cada requisição.
*   Incluir o `acl_level_id` no JWT é uma otimização importante.
*   As queries ao `AclRepo` devem ser rápidas e bem indexadas.
*   Cachear resultados de permissões que não mudam frequentemente pode ser considerado para cenários de altíssimo tráfego, mas com cuidado para não servir dados de permissão desatualizados.

A implementação correta e eficiente da lógica de ACL é fundamental para a segurança e funcionalidade da API \"Deeper\".