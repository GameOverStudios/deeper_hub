# Documentação Deeper: Contas de Usuário e Perfis

Este módulo da API \"Deeper\" é responsável pelo gerenciamento de contas de usuário (`sys_accounts`) e os perfis associados a elas (inicialmente focando em `sys_profiles` e `bx_persons_data` como o principal tipo de perfil de \"pessoa\").

## Responsabilidades Principais:

*   Registro de novas contas de usuário.
*   Autenticação de usuários (login) e geração de JWT.
*   Recuperação e atualização de dados da conta de usuário.
*   Criação e recuperação de perfis associados a contas.
*   Gerenciamento de status da conta (ativa, bloqueada, etc.).

## Componentes Detalhados:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas `sys_accounts`, `sys_profiles`, e `bx_persons_data` (e tabelas relacionadas como `bx_persons_pictures` se o escopo inicial incluir upload de avatar).

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir e sua documentação para criar as tabelas de contas e perfis.
    *   Links para:
        *   [Criar Tabela `sys_accounts` (`create_sys_accounts_table.elixir.md`)](./migrations/create_sys_accounts_table.elixir.md)
        *   [Criar Tabela `sys_profiles` (`create_sys_profiles_table.elixir.md`)](./migrations/create_sys_profiles_table.elixir.md)
        *   [Criar Tabela `bx_persons_data` (`create_bx_persons_data_table.elixir.md`)](./migrations/create_bx_persons_data_table.elixir.md)
        *   *(Outras tabelas relacionadas a perfis, como `bx_persons_pictures`, podem ser adicionadas aqui)*

3.  [**Módulos de Acesso a Dados (`data_access_modules.md`)**](./data_access_modules.md):
    *   Descreve os módulos Elixir (ex: `Deeper.SystemCore.AccountsRepo`, `Deeper.SystemCore.ProfilesRepo`, `Deeper.Content.PersonsRepo`) que encapsulam as queries SQL para interagir com as tabelas de contas e perfis.
    *   Detalha as funções (com seus SQLs) para operações CRUD e lógicas específicas (ex: encontrar usuário por email, verificar senha).

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para todas as operações relacionadas a contas e perfis (registro, login, obter/atualizar perfil, etc.).
    *   Inclui exemplos de requisições e respostas JSON.

## Fluxos Importantes:

*   **Registro de Usuário:**
    1.  Cliente envia dados para `POST /api/v1/accounts` (ou `POST /api/v1/auth/register`).
    2.  API valida os dados.
    3.  `AccountsRepo.create_account/1` insere na tabela `sys_accounts`.
    4.  (Opcional/Próximo Passo) `ProfilesRepo.create_profile/1` cria uma entrada em `sys_profiles` ligada à nova conta.
    5.  (Opcional/Próximo Passo) `PersonsRepo.create_person_data/1` cria uma entrada em `bx_persons_data` ligada ao novo perfil.
    6.  API retorna sucesso (talvez com um JWT para login automático).
*   **Login de Usuário:**
    1.  Cliente envia email/senha para `POST /api/v1/auth/login`.
    2.  `AccountsRepo.get_account_by_email/1` busca o usuário.
    3.  API verifica a senha (comparando o hash).
    4.  Se válido, API gera e retorna um JWT.
*   **Obtenção de Perfil do Usuário Logado:**
    1.  Cliente envia `GET /api/v1/profiles/me` com JWT.
    2.  API extrai `profile_id` do JWT.
    3.  `ProfilesRepo.get_profile_details/1` (que pode fazer JOINs com `sys_accounts` e `bx_persons_data`) busca os dados do perfil.
    4.  API retorna os dados do perfil.

A integração entre `sys_accounts`, `sys_profiles`, e a tabela de dados do tipo de perfil (como `bx_persons_data`) é fundamental e será refletida nas queries SQL e na lógica dos módulos de acesso a dados.