# Documentação Deeper: API de Conexões de Perfil (`sys_connections`)

Este módulo da API \"Deeper\" é responsável por gerenciar os diversos tipos de relacionamentos (conexões) entre perfis do sistema. Isso inclui funcionalidades como:

*   **Amizades:** Conexões mútuas que geralmente requerem uma solicitação e aceitação.
*   **Seguir/Ser Seguido (Assinaturas):** Conexões unidirecionais onde um perfil (iniciador) segue outro (conteúdo/alvo).
*   **Bloqueios:** Permite que um perfil impeça outro de interagir ou ver seu conteúdo.
*   (Opcional) Outros tipos de relacionamento definidos pelo sistema UNA.

A implementação será baseada nas tabelas `sys_profiles_conn_*` do UNA (ex: `sys_profiles_conn_friends`, `sys_profiles_conn_subscriptions`, `sys_profiles_conn_bans`).

## Responsabilidades Principais da API:

*   Permitir que um perfil solicite amizade a outro.
*   Permitir que um perfil aceite ou recuse uma solicitação de amizade.
*   Permitir que um perfil desfaça uma amizade.
*   Permitir que um perfil siga outro.
*   Permitir que um perfil deixe de seguir outro.
*   Permitir que um perfil bloqueie outro.
*   Permitir que um perfil desbloqueie outro.
*   Listar amigos, seguidores, quem está seguindo, e perfis bloqueados para um determinado perfil.
*   Verificar o status de conexão entre dois perfis.

## Estrutura da Documentação do Módulo `sys_connections`:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas `sys_profiles_conn_friends`, `sys_profiles_conn_subscriptions`, `sys_profiles_conn_bans`, e potencialmente `sys_profiles_conn_requests` (se as solicitações de amizade forem armazenadas separadamente antes de se tornarem uma amizade mútua).

2.  [**Migrações Elixir (`migrations/README.md`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir e sua documentação para criar as tabelas de conexões.

3.  [**Módulos de Acesso a Dados (`data_access_modules.md`)**](./data_access_modules.md):
    *   Descreve o módulo Elixir (ex: `Deeper.AdvancedFeatures.ConnectionsRepo`) que encapsula as queries SQL para interagir com as tabelas de conexões.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para todas as operações relacionadas a conexões de perfil.

5.  [**Mapeamento da Lógica de Serviço (`service_logic_mapping.md`)**](./service_logic_mapping.md):
    *   Analisa como as funcionalidades de conexão do UNA (geralmente através de `BxDolConnection` e seus objetos derivados) serão traduzidas para a lógica da API Elixir.

## Considerações Importantes:

*   **Bidirecionalidade vs. Unidirecionalidade:** A API deve tratar claramente a diferença entre conexões mútuas (amizades) e unidirecionais (seguir).
*   **Notificações:** Ações de conexão (solicitação de amizade, aceitação, novo seguidor) devem idealmente disparar notificações para os perfis envolvidos. Essa lógica de notificação será gerenciada por um sistema de notificações separado, mas acionada pelas operações de conexão.
*   **Contadores:** Contadores como \"número de amigos\", \"número de seguidores\", \"número de seguindo\" (geralmente armazenados em tabelas como `bx_persons_data` ou `bx_organizations_data`) precisarão ser atualizados quando as conexões forem criadas ou removidas.
*   **Privacidade:** As ações de conexão e a visibilidade das listas de conexões podem ser influenciadas pelas configurações de privacidade dos perfis.

Esta API é fundamental para as funcionalidades sociais da plataforma \"Deeper\".