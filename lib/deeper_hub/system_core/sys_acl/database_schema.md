# Documentação Deeper: Esquema do Banco de Dados para ACL (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas do sistema de Controle de Acesso (ACL) do UNA: `sys_acl_levels`, `sys_acl_actions`, `sys_acl_levels_members`, `sys_acl_matrix`, e `sys_acl_actions_track`.

## Tabela: `sys_acl_levels`

```sql
CREATE TABLE IF NOT EXISTS sys_acl_levels (
  ID INTEGER PRIMARY KEY AUTOINCREMENT,
  Name TEXT NOT NULL UNIQUE,
  Icon TEXT, -- Pode ser um nome de ícone ou caminho
  Description TEXT,
  Active TEXT NOT NULL DEFAULT 'no' CHECK(Active IN ('yes', 'no')),
  Purchasable TEXT NOT NULL DEFAULT 'yes' CHECK(Purchasable IN ('yes', 'no')),
  Removable TEXT NOT NULL DEFAULT 'yes' CHECK(Removable IN ('yes', 'no')),
  QuotaSize INTEGER NOT NULL DEFAULT 0, -- Em bytes
  QuotaNumber INTEGER NOT NULL DEFAULT 0, -- Número de arquivos/itens
  QuotaMaxFileSize INTEGER NOT NULL DEFAULT 0, -- Em bytes
  \"Order\" INTEGER NOT NULL DEFAULT 0, -- SQLite não gosta de 'Order' como nome de coluna sem aspas
  PasswordExpired INTEGER NOT NULL DEFAULT 0, -- Dias para expirar senha
  PasswordExpiredNotify INTEGER NOT NULL DEFAULT 0 -- Dias antes para notificar
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_acl_actions (
  ID INTEGER PRIMARY KEY AUTOINCREMENT,
  Module TEXT NOT NULL,
  Name TEXT NOT NULL, -- Nome da ação (ex: 'create_entry', 'view_profile')
  AdditionalParamName TEXT, -- Nome de um parâmetro adicional para diferenciar ações (raro)
  Title TEXT NOT NULL, -- Chave de tradução para o título da ação
  \"Desc\" TEXT, -- Chave de tradução para a descrição (SQLite não gosta de 'Desc' como nome de coluna)
  Countable INTEGER NOT NULL DEFAULT 0, -- 0 ou 1 (se a ação é contável)
  DisabledForLevels INTEGER NOT NULL DEFAULT 3 -- Bitmask dos níveis para os quais esta ação é SEMPRE desabilitada (1=Visitante, 2=Não-membro)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_acl_actions_module_name_param ON sys_acl_actions(Module, Name, AdditionalParamName);
```

```sql
CREATE TABLE IF NOT EXISTS sys_acl_levels_members (
  IDMember INTEGER NOT NULL, -- FK para sys_accounts.id
  IDLevel INTEGER NOT NULL, -- FK para sys_acl_levels.ID
  DateStarts INTEGER NOT NULL, -- Unix Timestamp: quando a membresia inicia
  DateExpires INTEGER, -- Unix Timestamp: quando a membresia expira (NULL para nunca)
  State TEXT DEFAULT '' CHECK(State IN ('', 'active', 'pending', 'expired')), -- Estado da transação/membresia específica
  TransactionID TEXT,
  PRIMARY KEY (IDMember, IDLevel, DateStarts), -- Chave composta
  FOREIGN KEY (IDMember) REFERENCES sys_accounts(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (IDLevel) REFERENCES sys_acl_levels(ID) ON DELETE CASCADE ON UPDATE CASCADE
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_acl_matrix (
  IDLevel INTEGER NOT NULL, -- FK para sys_acl_levels.ID
  IDAction INTEGER NOT NULL, -- FK para sys_acl_actions.ID
  AllowedCount INTEGER, -- Número de vezes que a ação é permitida (NULL para ilimitado)
  AllowedPeriodLen INTEGER, -- Duração do período em segundos (NULL se não aplicável)
  AllowedPeriodStart INTEGER, -- Unix Timestamp: início do período de contagem (raro, geralmente gerenciado por sys_acl_actions_track.ValidSince)
  AllowedPeriodEnd INTEGER, -- Unix Timestamp: fim do período de contagem (raro)
  AdditionalParamValue TEXT, -- Valor correspondente a AdditionalParamName em sys_acl_actions
  PRIMARY KEY (IDLevel, IDAction),
  FOREIGN KEY (IDLevel) REFERENCES sys_acl_levels(ID) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (IDAction) REFERENCES sys_acl_actions(ID) ON DELETE CASCADE ON UPDATE CASCADE
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_acl_actions_track (
  IDAction INTEGER NOT NULL, -- FK para sys_acl_actions.ID
  IDMember INTEGER NOT NULL, -- FK para sys_accounts.id
  ActionsLeft INTEGER NOT NULL, -- Quantas ações restam
  ValidSince INTEGER, -- Unix Timestamp: quando o período de contagem atual começou/foi resetado
  PRIMARY KEY (IDAction, IDMember),
  FOREIGN KEY (IDAction) REFERENCES sys_acl_actions(ID) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (IDMember) REFERENCES sys_accounts(id) ON DELETE CASCADE ON UPDATE CASCADE
);
```

*   **`ID`**: Identificador único do nível.
*   **`Name`**: Nome do nível (ex: \"Standard\", \"Premium\").
*   **`Icon`, `Description`**: Informações visuais e descritivas.
*   **`Active`, `Purchasable`, `Removable`**: Flags de status do nível.
*   **`Quota...`**: Limites de cota para membros deste nível.
*   **`\"Order\"`**: Ordem de exibição. (Colocado entre aspas pois `ORDER` é uma palavra reservada SQL).
*   **`PasswordExpired...`**: Configurações de expiração de senha.

## Tabela: `sys_acl_actions`

*   **`ID`**: Identificador único da ação.
*   **`Module`**: Módulo ao qual a ação pertence (ex: \"bx_persons\").
*   **`Name`**: Nome programático da ação.
*   **`AdditionalParamName`**: Usado em cenários mais complexos para diferenciar ações com o mesmo nome.
*   **`Title`, `\"Desc\"`**: Chaves de linguagem para o nome e descrição da ação.
*   **`Countable`**: Flag indicando se o uso desta ação é limitado/rastreado.
*   **`DisabledForLevels`**: Um bitmask. Se o bit correspondente ao nível do usuário estiver setado, a ação é negada, independentemente da matriz. (Ex: Nível 1 (Visitante) é bit 0 (valor 1), Nível 2 (Não-Membro/Guest) é bit 1 (valor 2). Se `DisabledForLevels` for 3 (1 OR 2), está desabilitado para Visitantes e Guests).

## Tabela: `sys_acl_levels_members`

*   **`IDMember`**: ID da conta do usuário (`sys_accounts.id`).
*   **`IDLevel`**: ID do nível de ACL.
*   **`DateStarts`, `DateExpires`**: Timestamps Unix definindo o período de validade desta associação de nível.
*   **`State`**: Estado específico desta atribuição de nível (pode ser usado por sistemas de pagamento).
*   **`TransactionID`**: ID de transação se o nível foi adquirido via pagamento.
*   A chave primária composta garante que um membro não possa ter o mesmo nível começando na mesma data múltiplas vezes. Um membro pode ter múltiplos níveis, ou o mesmo nível com diferentes períodos de validade.

## Tabela: `sys_acl_matrix`

*   **`IDLevel`, `IDAction`**: Compõem a chave primária, definindo a permissão para uma ação específica por um nível.
*   **`AllowedCount`**: Quantas vezes a ação é permitida dentro do período (se `AllowedPeriodLen` estiver definido). `NULL` significa ilimitado.
*   **`AllowedPeriodLen`**: Duração do período de contagem em segundos (ex: 86400 para 1 dia).
*   **`AllowedPeriodStart`, `AllowedPeriodEnd`**: Raramente usados diretamente aqui; a lógica de período geralmente é gerenciada com `sys_acl_actions_track.ValidSince` e `AllowedPeriodLen`.
*   **`AdditionalParamValue`**: Se `sys_acl_actions.AdditionalParamName` for usado.

## Tabela: `sys_acl_actions_track`

*   **`IDAction`, `IDMember`**: Compõem a chave primária, rastreando o uso de uma ação contável por um membro.
*   **`ActionsLeft`**: O número de execuções restantes para esta ação dentro do período atual.
*   **`ValidSince`**: Timestamp Unix de quando o contador `ActionsLeft` foi (re)iniciado para o período atual. Usado em conjunto com `sys_acl_matrix.AllowedPeriodLen`.

**Nota sobre Chaves Estrangeiras em SQLite:**
Para que as constraints de chave estrangeira funcionem em SQLite, o `PRAGMA foreign_keys = ON;` deve ser executado para cada conexão. Isso deve ser garantido pela configuração do pool de conexões `Deeper.Core.Data.Repo`.