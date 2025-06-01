# Documentação Deeper: Módulos e Funcionalidades Core do Sistema

Este diretório detalha a implementação da API para os módulos e funcionalidades centrais do sistema UNA, que são a base para muitas outras partes da aplicação \"Deeper\".

Estas funcionalidades incluem:

*   Gerenciamento de Contas de Usuário e Perfis.
*   Lógica de Controle de Acesso (ACL).
*   Configurações Globais do Sistema.
*   Internacionalização e Localização.
*   Gerenciamento de Permalinks e Roteamento base da API.

## Estrutura dos Submódulos Core:

Cada subdiretório aqui representa um componente fundamental do sistema:

1.  [**Contas de Usuário e Perfis (`sys_accounts_and_profiles/`)**](./sys_accounts_and_profiles/README.md):
    *   API para registro, login, e gerenciamento de dados de contas de usuário (`sys_accounts`).
    *   API para gerenciamento de perfis associados a contas (`sys_profiles`, `bx_persons_data`, etc., conforme os tipos de perfil do UNA).

2.  [**Controle de Acesso (ACL) (`sys_acl/`)**](./sys_acl/README.md):
    *   Detalha como a lógica de ACL do UNA (`sys_acl_levels`, `sys_acl_actions`, `sys_acl_matrix`, `sys_acl_levels_members`) será consultada e aplicada pelo backend \"Deeper\" para proteger os endpoints da API.
    *   Foco principal na validação interna, não necessariamente em endpoints API para manipular o ACL diretamente (isso seria parte do `07_studio_admin_api/`).

3.  [**Configurações do Sistema (`sys_options/`)**](./sys_options/README.md):
    *   API para permitir que o cliente (e o próprio backend) acesse as configurações globais e de módulos armazenadas em `sys_options`.

4.  [**Internacionalização e Localização (`sys_localization/`)**](./sys_localization/README.md):
    *   API para obter strings de tradução (`sys_localization_keys`, `sys_localization_strings`) para diferentes idiomas (`sys_localization_languages`), permitindo que o cliente renderize a interface no idioma apropriado.

5.  [**Permalinks e Roteamento da API (`sys_permalinks_and_routing/`)**](./sys_permalinks_and_routing/README.md):
    *   Descreve a estratégia para mapear as URLs amigáveis (permalinks do UNA, armazenados em `sys_permalinks`) para as rotas da API \"Deeper\".
    *   Como o roteador do Phoenix lidará com isso.

## Abordagem de Implementação

Para cada um desses componentes core:

*   **Definição do Esquema SQLite:** Os `CREATE TABLE` statements para as tabelas relevantes do UNA serão adaptados para SQLite.
*   **Migrações Elixir:** Módulos de migração Elixir (`*.ex`) serão criados para aplicar esses esquemas ao banco de dados. A documentação (`*.elixir.md`) acompanhará esses módulos.
*   **Módulos de Acesso a Dados (Repositórios):** Módulos Elixir (ex: `Deeper.SystemCore.AccountsRepo`) serão desenvolvidos para encapsular as queries SQL diretas, fornecendo uma interface clara para a lógica de negócios e os controllers da API.
*   **Endpoints da API:** Rotas e controllers Phoenix serão definidos para expor as funcionalidades via REST, utilizando JSON para troca de dados.

A implementação desses módulos core é prioritária, pois eles formam a espinha dorsal da aplicação \"Deeper\".