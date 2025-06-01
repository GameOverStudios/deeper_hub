# Documentação Deeper: Controle de Acesso (ACL) - Lógica de Validação

Este documento descreve como a lógica de Controle de Acesso (ACL) do sistema UNA será utilizada pelo backend \"Deeper\" para proteger endpoints da API e validar permissões de usuário.

**Foco Principal:** Esta seção foca na **validação e consulta** das regras de ACL existentes no banco de dados (`sys_acl_levels`, `sys_acl_actions`, `sys_acl_matrix`, `sys_acl_levels_members`). A API para **administração** do ACL (criar/editar níveis, ações, matriz) será detalhada na seção `07_studio_admin_api/acl_admin_api.md`.

## Responsabilidades Principais da Lógica de ACL no Backend \"Deeper\":

*   Determinar o nível de ACL de um usuário autenticado.
*   Verificar se um usuário (baseado em seu nível de ACL) tem permissão para executar uma ação específica representada por um endpoint da API.
*   Considerar restrições de contagem e período para ações, se aplicável (interagindo com `sys_acl_actions_track`).
*   Garantir que a associação do usuário a um nível de ACL esteja ativa e dentro do período de validade.

## Componentes do Banco de Dados UNA para ACL:

*   **`sys_acl_levels`**: Define os diferentes níveis de membresia (ex: Visitante, Membro Grátis, Membro Premium).
    *   Campos importantes: `ID`, `Name`, `Purchasable`, `Removable`, `QuotaSize`, `QuotaNumber`, `Order`.
*   **`sys_acl_actions`**: Define as ações que podem ser controladas no sistema (ex: `bx_persons_view_profile`, `bx_articles_create_entry`).
    *   Campos importantes: `ID`, `Module`, `Name` (da ação), `Countable`, `DisabledForLevels`.
*   **`sys_acl_levels_members`**: Associa um `IDMember` (que no \"Deeper\" será o `sys_accounts.id`) a um `IDLevel`.
    *   Campos importantes: `IDMember`, `IDLevel`, `DateStarts`, `DateExpires`, `State` (ex: 'active').
*   **`sys_acl_matrix`**: A tabela central que mapeia `IDLevel` para `IDAction`, especificando se a ação é permitida e sob quais condições.
    *   Campos importantes: `IDLevel`, `IDAction`, `AllowedCount`, `AllowedPeriodLen`, `AllowedPeriodStart`, `AllowedPeriodEnd`.
*   **`sys_acl_actions_track`**: Rastreia o uso de ações contáveis por membro.
    *   Campos importantes: `IDAction`, `IDMember`, `ActionsLeft`, `ValidSince`.

## Implementação da Lógica de Validação ACL no \"Deeper\":

A validação de ACL será primariamente uma responsabilidade do backend, possivelmente implementada como:

1.  **Funções Auxiliares/Módulo de ACL (`Deeper.SystemCore.ACLValidator` ou similar):**
    *   Este módulo conteria funções para verificar permissões.
    *   Exemplo de função: `ACLValidator.can_perform_action?(account_id, action_name_or_id)`

2.  **Integração com a Autenticação:**
    *   Durante o login, ao gerar o JWT, o `IDLevel` atual e ativo do usuário (de `sys_acl_levels_members`) pode ser incluído no payload do token. Isso evita uma consulta ao DB para obter o nível a cada requisição.
        *   **Desafio:** Se o nível do usuário mudar enquanto o token ainda é válido, o token conterá um nível desatualizado. Uma alternativa é buscar o nível do usuário no DB a cada requisição protegida, ou ter um mecanismo para invalidar tokens quando o nível muda. Para simplicidade inicial, incluir no JWT e lidar com a expiração do token pode ser suficiente.

3.  **Middleware ou Plug no Phoenix (se usado):**
    *   Um plug pode ser usado nas rotas protegidas para verificar automaticamente as permissões antes que o controller seja chamado.
    *   Este plug chamaria as funções do `ACLValidator`.

### Fluxo de Verificação de Permissão para um Endpoint:

1.  **Requisição Recebida:** Usuário faz uma requisição a um endpoint protegido (ex: `POST /api/v1/articles`).
2.  **Autenticação:** O token JWT é validado. O `account_id` e (potencialmente) o `level_id` são extraídos.
3.  **Identificação da Ação:**
    *   O sistema \"Deeper\" precisa mapear o endpoint e o método HTTP para uma `IDAction` correspondente de `sys_acl_actions`. Este mapeamento pode ser:
        *   Codificado no plug/controller.
        *   Definido em uma configuração.
        *   Inferido por convenção (ex: `POST /articles` -> ação \"articles_create\").
    *   A `IDAction` pode ser obtida consultando `sys_acl_actions` pelo nome da ação e módulo.
4.  **Obtenção do Nível do Usuário:**
    *   Se não estiver no JWT, consultar `sys_acl_levels_members` usando `account_id` para obter o `IDLevel` ativo e válido (verificando `DateStarts`, `DateExpires`, `State`).
5.  **Consulta à Matriz ACL:**
    *   Chamar uma função como `Deeper.SystemCore.ACLRepo.check_permission(level_id, action_id)` que executa uma query SQL em `sys_acl_matrix`.
    *   **SQL Exemplo (para `ACLRepo.check_permission`):**

```sql
      SELECT
        AllowedCount, AllowedPeriodLen, AllowedPeriodStart, AllowedPeriodEnd
      FROM sys_acl_matrix
      WHERE IDLevel = ? AND IDAction = ?;
```

```sql
      UPDATE sys_acl_actions_track
      SET ActionsLeft = ActionsLeft - 1
      WHERE IDMember = ? AND IDAction = ? AND ActionsLeft > 0;
      -- Pode ser necessário criar a entrada em sys_acl_actions_track na primeira vez,
      -- baseando-se em AllowedCount de sys_acl_matrix.
```

6.  **Verificação de Níveis Desabilitados:**
    *   Consultar `sys_acl_actions.DisabledForLevels`. Se o `level_id` do usuário estiver nesta máscara de bits, a ação é negada.
7.  **Verificação de Ações Contáveis (se `sys_acl_actions.Countable = 1`):**
    *   Se a ação for permitida pela matriz e for contável:
        *   Consultar `sys_acl_actions_track` para `IDMember = account_id` e `IDAction = action_id`.
        *   Verificar `ActionsLeft`. Se `0` ou inexistente (assumindo que uma entrada deve existir se `AllowedCount` for definido), a ação é negada.
        *   Verificar `ValidSince` se `AllowedPeriodLen` for usado.
8.  **Decisão:**
    *   Se todas as verificações passarem: permitir a execução do controller.
    *   Caso contrário: retornar `403 Forbidden`.
9.  **Atualização de Ações Contáveis (após sucesso da ação):**
    *   Se a ação foi permitida e é contável com `AllowedCount`, decrementar `ActionsLeft` em `sys_acl_actions_track`.
    *   **SQL Exemplo (para `ACLRepo.decrement_action_count`):**

## Esquema do Banco de Dados (SQLite - Tabelas ACL Relevantes)

As definições `CREATE TABLE` para `sys_acl_levels`, `sys_acl_actions`, `sys_acl_levels_members`, `sys_acl_matrix`, e `sys_acl_actions_track` serão detalhadas em seus respectivos arquivos (`database_schema.md`, `migrations/*.elixir.md`) dentro desta pasta `sys_acl/`.

## Módulos de Acesso a Dados (`data_access_modules.md`)

Descreverá o `Deeper.SystemCore.ACLRepo` com funções para:
*   `get_active_user_level(account_id)`
*   `get_action_details(action_name, module_name)`
*   `check_matrix_permission(level_id, action_id)`
*   `get_action_track_info(account_id, action_id)`
*   `update_action_track_info(account_id, action_id, new_actions_left, new_valid_since)`

## Endpoints da API

Não haverá endpoints públicos da API nesta seção para *validar* permissões, pois isso é uma lógica interna do backend. Os endpoints para *gerenciar* o ACL estarão em `07_studio_admin_api/acl_admin_api.md`.

## Desafios:

*   **Mapeamento Ação-Endpoint:** Definir uma forma robusta e clara de mapear requisições HTTP da API para as `IDAction` do UNA.
*   **Lógica de Ações Contáveis:** A lógica de inicializar, verificar e decrementar contadores em `sys_acl_actions_track` em conjunto com `AllowedCount` e `AllowedPeriodLen` da `sys_acl_matrix` pode ser complexa e requer atenção a condições de corrida se não for transacional.
*   **Performance:** Múltiplas consultas ao DB para verificar permissões em cada requisição podem impactar a performance. Estratégias de cache ou otimizações (como incluir o nível no JWT) devem ser consideradas.

Este sistema de ACL é poderoso e granular, e portar sua lógica de validação para \"Deeper\" é essencial para a segurança da API.