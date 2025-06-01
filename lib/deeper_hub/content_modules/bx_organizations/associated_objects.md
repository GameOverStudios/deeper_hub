# Documentação Deeper: Objetos Associados e Interações para Organizações (`bx_organizations`)

Este documento descreve como os sistemas de interação genéricos do \"Deeper\" (baseados nas funcionalidades do UNA) se associam e interagem com os perfis de Organização (`bx_organizations_data`).

Perfis de organização são entidades centrais com as quais os usuários podem interagir de diversas formas, como seguir (tornar-se fã), comentar (em um feed ou mural da organização), avaliar (se aplicável), e denunciar.

## Identificação do Objeto

Para que os sistemas de interação genéricos saibam a qual perfil de organização uma interação se refere, usaremos:

*   **`object_type` (ou `module_name`):** Um identificador textual para o tipo de conteúdo. Para organizações, este será consistentemente algo como `\"bx_organization\"` ou `\"deeper_organization_profile\"`.
*   **`object_id`:** O ID da organização específica em `bx_organizations_data.id`.

## 1. Seguidores/Fãs (Conexões - `08_advanced_features/sys_connections_api.md`)

*   **Funcionalidade:** Usuários podem \"seguir\" ou \"tornar-se fã\" de uma organização para receber atualizações ou serem listados como apoiadores.
*   **Tabelas Envolvidas (do sistema de conexões):**
    *   `sys_profiles_conn_subscriptions` (ou uma tabela similar para conexões \"seguir/fã\").
    *   O sistema de conexões usará o `id` de `sys_profiles` tanto para o seguidor (iniciador) quanto para a organização seguida (conteúdo). Lembre-se que uma organização também tem uma entrada em `sys_profiles`.
*   **Integração com `bx_organizations_data`:**
    *   A tabela `bx_organizations_data` possui uma coluna `fans_count` (INTEGER) para armazenar o número total de seguidores/fãs.
*   **API Endpoints (do sistema de conexões, aplicados a perfis de organização):**
    *   Se `organization_profile_id` é o `id` da entrada em `sys_profiles` para a organização:
        *   `POST /api/v1/profiles/{organization_profile_id}/follow`
            *   Cria a conexão de \"seguir\".
            *   O `ConnectionsRepo` (ou serviço) deve então chamar `Deeper.Content.OrganizationsRepo.update_organization_fans_count(org_data_id, 1)`, onde `org_data_id` é o `content_id` do perfil da organização.
        *   `DELETE /api/v1/profiles/{organization_profile_id}/unfollow`
            *   Remove a conexão de \"seguir\".
            *   O `ConnectionsRepo` (ou serviço) deve chamar `Deeper.Content.OrganizationsRepo.update_organization_fans_count(org_data_id, -1)`.
        *   `GET /api/v1/profiles/{organization_profile_id}/followers?page=1&per_page=20`
            *   Lista os perfis que seguem a organização.
        *   `GET /api/v1/profiles/{user_profile_id}/following/organizations?page=1&per_page=20`
            *   Lista as organizações que um determinado perfil de usuário está seguindo.
*   **Atualização de `fans_count`:**
    *   Mantido sincronizado pelo sistema de conexões ao adicionar ou remover um seguidor.

## 2. Comentários (Feed/Mural da Organização - `04_interaction_systems/sys_comments_system/`)

*   **Funcionalidade:** Usuários (com permissão definida por `allow_post_to` ou `allow_view_to` na organização) podem postar e visualizar comentários no \"mural\" ou feed de uma organização.
*   **Tabelas Envolvidas (do sistema de comentários):**
    *   `sys_cmts_objects` (registrando \"bx_organization\" como comentável).
    *   `sys_cmts_entries` (armazenando os comentários).
*   **Integração com `bx_organizations_data`:**
    *   A tabela `bx_organizations_data` possui uma coluna `comments_count` (INTEGER).
    *   A permissão para postar é controlada pela lógica baseada em `allow_post_to` (ver `service_logic_mapping.md`).
*   **API Endpoints (do sistema de comentários, aplicados a organizações):**
    *   `GET /api/v1/organizations/{org_data_id}/comments?page=1&per_page=10`
        *   O backend usará `object_type = \"bx_organization\"` e `object_id = {org_data_id}`.
    *   `POST /api/v1/organizations/{org_data_id}/comments`
        *   Cria um novo comentário.
        *   O `CommentsRepo` ou serviço deve verificar a permissão (`allow_post_to`) e, em sucesso, chamar `Deeper.Content.OrganizationsRepo.update_organization_interaction_count(org_data_id, :comments, 1)`.
*   **Atualização de `comments_count`:**
    *   Atualizado pelo sistema de comentários ao criar/deletar comentários.

## 3. Denúncias (`04_interaction_systems/sys_reporting_system/`)

*   **Funcionalidade:** Usuários podem denunciar perfis de organização por conteúdo inadequado, falsidade, etc.
*   **Tabelas Envolvidas (do sistema de denúncias):**
    *   `sys_reporting_objects` (registrando \"bx_organization\" como denunciável).
    *   `sys_reporting_track` (armazenando as denúncias).
*   **Integração com `bx_organizations_data`:**
    *   A tabela `bx_organizations_data` possui `reports_count` (INTEGER).
    *   (Opcional) Pode haver uma configuração `allow_reports` no UNA, que seria mapeada.
*   **API Endpoints (do sistema de denúncias):**
    *   `POST /api/v1/organizations/{org_data_id}/reports`
        *   Corpo da requisição: `{\"type\": \"impersonation\", \"text\": \"This org is fake.\"}`.
        *   O `ReportingRepo` ou serviço deve incrementar `bx_organizations_data.reports_count` e notificar administradores.
*   **Atualização de `reports_count`:**
    *   Atualizado pelo sistema de denúncias.

## 4. Visualizações (`sys_views_track` - parte do core ou `04_interaction_systems`)

*   **Funcionalidade:** Rastrear o número de visualizações do perfil de uma organização.
*   **Tabelas Envolvidas:** `sys_views_track`.
*   **Integração com `bx_organizations_data`:**
    *   A tabela `bx_organizations_data` possui uma coluna `views` (INTEGER).
*   **API Endpoint:**
    *   `POST /api/v1/organizations/{org_data_id}/view` (ou implícito na chamada `GET /api/v1/organizations/{id_or_uri}`).
*   **Lógica de Atualização de `views`:**
    *   Ao visualizar o perfil, o sistema registra a visualização e chama `Deeper.Content.OrganizationsRepo.increment_organization_view_count(org_data_id)`.

## 5. Votos/Avaliações (Opcional para Organizações - `04_interaction_systems/sys_voting_system/`)

*   **Funcionalidade:** Se aplicável, usuários poderiam avaliar organizações (ex: qualidade do serviço, confiabilidade). No UNA, isso seria menos comum para organizações do que para produtos ou posts, mas a estrutura pode permitir.
*   **Integração com `bx_organizations_data`:**
    *   Poderiam ser adicionadas colunas `allow_org_votes`, `org_votes_count`, `org_score` em `bx_organizations_data`.
*   **API Endpoints:**
    *   `POST /api/v1/organizations/{org_data_id}/votes`
    *   `GET /api/v1/organizations/{org_data_id}/votes/summary`
*   **Lógica:** Análoga a outros sistemas de votação, atualizando os contadores/score na `bx_organizations_data`.

## 6. Favoritos (Opcional para Organizações - `04_interaction_systems/sys_favorites_system/`)

*   **Funcionalidade:** Usuários poderiam \"favoritar\" organizações para fácil acesso, similar a \"seguir\", mas talvez com um propósito diferente (ex: lista pessoal de orgs de interesse sem necessariamente receber todas as atualizações).
*   **Integração com `bx_organizations_data`:**
    *   Poderia ter uma coluna `org_favorites_count`.
*   **API Endpoints:**
    *   `POST /api/v1/organizations/{org_data_id}/favorite`
    *   `DELETE /api/v1/organizations/{org_data_id}/favorite`
*   **Lógica:** Análoga a outros sistemas de favoritos.

## Considerações de Implementação para Interações:

*   **Centralização vs. Especificidade:**
    *   Os contadores (`fans_count`, `comments_count`, etc.) são mantidos em `bx_organizations_data` para otimizar a leitura em listagens e visualizações de perfil.
    *   A lógica de atualização desses contadores deve ser acionada pelos respectivos sistemas de interação (Conexões, Comentários, etc.) para manter a consistência. Isso pode ser feito através de callbacks, eventos internos (se \"Deeper\" usar um sistema de eventos), ou chamadas diretas entre os módulos Repo/Serviço.
*   **Permissões de Interação:**
    *   Cada sistema de interação (comentar, votar, seguir) terá suas próprias verificações de permissão ACL (ex: \"pode o usuário X comentar?\").
    *   Além disso, o próprio perfil da organização pode ter configurações que desabilitam certos tipos de interação (ex: `allow_comments` em `bx_organizations_data`). Ambas as camadas de permissão devem ser verificadas.

Este documento esclarece como os perfis de organização se tornam entidades interativas dentro da plataforma \"Deeper\", aproveitando os sistemas de interação genéricos.