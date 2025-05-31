# Documentação Deeper: Esquema do Banco de Dados para Contas e Perfis (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas centrais de gerenciamento de contas e perfis: `sys_accounts`, `sys_profiles`, e `bx_persons_data`.

## Tabela: `sys_accounts`

```sql
CREATE TABLE IF NOT EXISTS sys_accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER, -- FK para sys_profiles.id após a criação de sys_profiles
  name TEXT NOT NULL, -- Nome de exibição/login, pode ser o mesmo que bx_persons_data.fullname inicialmente
  email TEXT NOT NULL UNIQUE,
  email_confirmed INTEGER NOT NULL DEFAULT 0, -- 0 for false, 1 for true
  phone TEXT,
  phone_confirmed INTEGER NOT NULL DEFAULT 0,
  receive_updates INTEGER NOT NULL DEFAULT 1,
  receive_news INTEGER NOT NULL DEFAULT 1,
  password_hash TEXT NOT NULL,
  role INTEGER NOT NULL DEFAULT 1, -- Role ID básico, pode ser mapeado para sys_std_roles ou sys_acl_levels
  lang_id INTEGER DEFAULT 0, -- FK para sys_localization_languages.ID
  added INTEGER NOT NULL, -- Unix Timestamp
  changed INTEGER NOT NULL, -- Unix Timestamp
  logged INTEGER, -- Unix Timestamp
  ip TEXT,
  referred TEXT,
  login_attempts INTEGER NOT NULL DEFAULT 0,
  locked INTEGER NOT NULL DEFAULT 0, -- 0 for false, 1 for true
  active INTEGER NOT NULL DEFAULT 0 -- 0 para inativo/pendente, 1 para ativo
);

CREATE INDEX IF NOT EXISTS idx_sys_accounts_email ON sys_accounts(email);
CREATE INDEX IF NOT EXISTS idx_sys_accounts_profile_id ON sys_accounts(profile_id);
-- Nota: A chave estrangeira para profile_id será adicionada após a definição de sys_profiles, ou gerenciada pela aplicação.
-- Para SQLite, é mais fácil definir FKs na criação da tabela ou com ALTER TABLE ADD COLUMN (se a coluna não existir).
-- Recriar a tabela com a FK é mais seguro se a tabela já existir sem ela.
```

```sql
CREATE TABLE IF NOT EXISTS sys_profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id INTEGER NOT NULL,
  type TEXT NOT NULL, -- Ex: 'bx_persons', 'bx_organizations' (tipo de módulo do perfil)
  content_id INTEGER NOT NULL, -- ID na tabela de dados específica do tipo (ex: bx_persons_data.id)
  -- cfw_value, cfw_items, cfu_items, cfu_locked (relacionado a content filter, pode ser simplificado ou omitido inicialmente)
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'pending', 'suspended')),
  FOREIGN KEY (account_id) REFERENCES sys_accounts(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sys_profiles_account_id ON sys_profiles(account_id);
CREATE INDEX IF NOT EXISTS idx_sys_profiles_type_content_id ON sys_profiles(type, content_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_profiles_account_type_content ON sys_profiles(account_id, type, content_id);
```

```sql
CREATE TABLE IF NOT EXISTS bx_persons_data (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- Este ID será o content_id em sys_profiles
  author INTEGER NOT NULL, -- ID do perfil do autor/criador (pode ser o próprio perfil em alguns casos, ou um admin)
  added INTEGER NOT NULL, -- Unix Timestamp
  changed INTEGER NOT NULL, -- Unix Timestamp
  picture INTEGER, -- ID de um arquivo/imagem (FK para uma futura tabela de arquivos/sys_files)
  cover INTEGER, -- ID de um arquivo/imagem para capa
  -- cover_data TEXT, -- Informações de posicionamento da capa, pode ser JSON
  fullname TEXT NOT NULL,
  last_name TEXT, -- Opcional, se fullname não for suficiente
  description TEXT,
  gender TEXT, -- Ex: 'male', 'female', 'other'
  birthday TEXT, -- Formato 'YYYY-MM-DD'
  -- labels TEXT, -- Pode ser uma tabela separada de tags/labels
  location TEXT, -- Texto simples da localização, ou pode ser mais estruturado
  views INTEGER NOT NULL DEFAULT 0,
  rate REAL NOT NULL DEFAULT 0, -- Média de avaliação
  votes INTEGER NOT NULL DEFAULT 0, -- Número de votos
  score INTEGER NOT NULL DEFAULT 0,
  sc_up INTEGER NOT NULL DEFAULT 0, -- Votos positivos para score
  sc_down INTEGER NOT NULL DEFAULT 0, -- Votos negativos para score
  favorites INTEGER NOT NULL DEFAULT 0, -- Número de vezes que foi favoritado
  comments INTEGER NOT NULL DEFAULT 0, -- Número de comentários
  reports INTEGER NOT NULL DEFAULT 0, -- Número de denúncias
  featured INTEGER NOT NULL DEFAULT 0, -- 0 ou 1 (ou timestamp se for \"featured until\")
  allow_view_to TEXT NOT NULL DEFAULT '3', -- ID do grupo de privacidade (do UNA)
  allow_post_to TEXT NOT NULL DEFAULT '5',
  allow_contact_to TEXT NOT NULL DEFAULT '3',
  settings TEXT -- Configurações específicas do perfil, pode ser JSON
);

CREATE INDEX IF NOT EXISTS idx_bx_persons_data_author ON bx_persons_data(author);
CREATE INDEX IF NOT EXISTS idx_bx_persons_data_fullname ON bx_persons_data(fullname); -- Para buscas
```

*   **`id`**: Chave primária autoincrementável.
*   **`profile_id`**: ID do perfil principal associado a esta conta na tabela `sys_profiles`.
*   **`name`**: Nome de usuário ou nome de exibição.
*   **`email`, `email_confirmed`**: Endereço de email e status de confirmação.
*   **`phone`, `phone_confirmed`**: Número de telefone e status de confirmação.
*   **`receive_updates`, `receive_news`**: Preferências de notificação.
*   **`password_hash`**: Hash da senha do usuário (usar Argon2, Bcrypt).
*   **`role`**: Papel do usuário no sistema (nível básico).
*   **`lang_id`**: ID do idioma preferido do usuário.
*   **`added`, `changed`, `logged`**: Timestamps Unix para criação, última alteração e último login.
*   **`ip`**: Último IP de login.
*   **`referred`**: Informação de referência (quem indicou).
*   **`login_attempts`, `locked`**: Para controle de tentativas de login e bloqueio de conta.
*   **`active`**: Status da conta (0=pendente/inativo, 1=ativo, outros valores para suspenso, etc.).

## Tabela: `sys_profiles`

*   **`id`**: Chave primária autoincrementável.
*   **`account_id`**: Chave estrangeira para `sys_accounts.id`, indicando a qual conta este perfil pertence. `ON DELETE CASCADE` garante que os perfis são removidos se a conta for.
*   **`type`**: O \"tipo\" de perfil, geralmente o nome do módulo que gerencia os dados deste perfil (ex: \"bx_persons\").
*   **`content_id`**: O ID da entrada na tabela de dados específica do tipo de perfil (ex: `id` da tabela `bx_persons_data`).
*   **`status`**: Status do perfil (ativo, pendente, suspenso).

## Tabela: `bx_persons_data` (Dados para Perfis do Tipo \"Pessoa\")

*   **`id`**: Chave primária. Este valor é usado como `content_id` na tabela `sys_profiles` quando `type` é \"bx_persons\".
*   **`author`**: ID do perfil que criou esta entrada de pessoa.
*   **`added`, `changed`**: Timestamps de criação e modificação.
*   **`picture`, `cover`**: IDs para imagens de perfil e capa (precisarão de uma tabela de arquivos).
*   **`fullname`, `last_name`, `description`, `gender`, `birthday`**: Campos de dados pessoais.
*   **`location`**: Informação de localização.
*   **`views`, `rate`, `votes`, `score`, `sc_up`, `sc_down`, `favorites`, `comments`, `reports`, `featured`**: Contadores e métricas de interação.
*   **`allow_view_to`, `allow_post_to`, `allow_contact_to`**: Níveis de privacidade (originalmente referenciam grupos de privacidade do UNA, que precisarão ser mapeados ou simplificados).
*   **`settings`**: Campo genérico para configurações adicionais (armazenado como JSON).

### Relacionamentos Pós-Criação:

Após a criação de todas as três tabelas, se `sys_accounts.profile_id` não foi definida como FK durante sua criação, pode-se considerar recriar a tabela `sys_accounts` (se vazia) ou usar `ALTER TABLE` (com limitações no SQLite para adicionar FKs a tabelas existentes sem recriá-las de forma mais complexa). A maneira mais simples em SQLite para garantir FKs é defini-las no `CREATE TABLE` inicial.

**Próximo Passo:** Definir os módulos de migração Elixir para criar estas tabelas.