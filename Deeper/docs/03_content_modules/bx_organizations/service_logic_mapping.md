# Documentação Deeper: Mapeamento da Lógica de Serviço para Organizações (`bx_organizations`)

Este documento descreve como as funcionalidades e \"service calls\" (métodos de serviço) do módulo `bx_organizations` original do UNA PHP serão mapeadas para a lógica no backend Elixir \"Deeper\" e expostas através da API RESTful.

A lógica de negócio do `bx_organizations` do UNA, que envolve a criação de perfis de organização, gerenciamento de dados, permissões e interações, será distribuída entre os módulos de acesso a dados (`Deeper.Content.OrganizationsRepo`, `Deeper.SystemCore.ProfilesRepo`), controllers da API, e potencialmente módulos de serviço Elixir para orquestração mais complexa.

## Mapeamento de Funcionalidades Chave:

### 1. Criação de um Perfil de Organização

*   **Funcionalidade UNA Original:**
    *   Um usuário logado (com permissão) acessa um formulário para criar uma nova organização.
    *   Após a submissão, o sistema:
        1.  Cria uma entrada na tabela `bx_organizations_data`.
        2.  Cria uma entrada correspondente na tabela `sys_profiles` com `type = 'bx_organizations'` e `content_id` apontando para o novo ID da organização. O `account_id` em `sys_profiles` é o da conta do usuário criador.
        3.  O `author_id` em `bx_organizations_data` é o `profile_id` (de `sys_profiles`) do usuário criador.
        4.  (Opcional) Adiciona o criador à tabela `bx_organizations_admins` (ou `members`) com um papel de administrador.
        5.  Lida com upload de logo/capa.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `POST /api/v1/organizations`
    *   **Controller Elixir:**
        1.  Recebe dados da organização via JSON.
        2.  Extrai o `profile_id` do usuário autenticado (JWT) para ser o `author_id`.
        3.  Chama `Deeper.Content.OrganizationsRepo.create_organization(author_profile_id, params)`.
    *   **`Deeper.Content.OrganizationsRepo.create_organization/2` (em transação):**
        1.  Busca o `account_id` associado ao `author_profile_id` (necessário para criar a entrada em `sys_profiles`).
        2.  Insere os dados em `bx_organizations_data`, obtendo o `new_org_id`.
        3.  Chama `Deeper.SystemCore.ProfilesRepo.create_profile(%{account_id: author_account_id, type: \"bx_organizations\", content_id: new_org_id, status: \"active\"})`, obtendo o `new_system_profile_id` para a organização.
        4.  (Opcional) Se a tabela `bx_organizations_members` existir, chama `Deeper.Content.OrganizationsRepo.add_member_to_organization(new_org_id, author_profile_id, \"admin\")`.
        5.  Retorna a organização criada e o `profile_id` do sistema da organização.
    *   **Upload de Logo/Capa:**
        *   O cliente primeiro faz upload dos arquivos para `POST /api/v1/files` (do `06_file_management`), obtendo `file_id`s.
        *   Esses `file_id`s (`org_logo`, `org_cover`) são incluídos nos `params` da criação da organização. O `OrganizationsRepo` apenas armazena esses IDs.

### 2. Visualização de um Perfil de Organização (`serviceViewOrganizationProfile` no UNA)

*   **Funcionalidade UNA Original:**
    *   Busca dados da organização, dados do perfil do sistema (`sys_profiles`), informações do autor, logo, capa, membros/admins, contadores de interação.
    *   Verifica permissões de visualização.
    *   Incrementa contador de visualizações.
    *   Renderiza a página do perfil da organização.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/organizations/{id_or_uri}`
    *   **Controller Elixir:**
        1.  Recebe `id_or_uri` e o query param `preload`.
        2.  Chama `Deeper.Content.OrganizationsRepo.get_organization_by_id_or_uri(id_or_uri, preload_opts)`.
        3.  (Opcional) Chama `Deeper.Content.OrganizationsRepo.increment_organization_view_count(organization.id)`.
    *   **`Deeper.Content.OrganizationsRepo.get_organization_by_id_or_uri/2`:**
        1.  Busca a entrada principal em `bx_organizations_data`.
        2.  Se encontrada, e com base nas `preload_opts`:
            *   Busca a categoria (se aplicável).
            *   Busca o perfil do autor/criador (`ProfilesRepo.get_profile_summary/1`).
            *   Busca membros (`OrganizationsRepo.list_organization_members/2`).
            *   Obtém URLs para logo/capa do `FileRepo` usando os `file_id`s armazenados.
            *   (Para contadores de interação como comentários, fãs, a API pode retornar os contadores armazenados ou links para os endpoints de interação).
        3.  Verifica as permissões de visualização (`allow_view_to`) contra o `profile_id` do solicitante (se autenticado) e seu nível de ACL. Se não tiver permissão, retorna `403 Forbidden` ou não inclui certos campos.
        4.  Mapeia para a struct `Deeper.Content.Organizations.Organization`.
    *   **Cliente Remoto:** Renderiza o perfil com base nos dados JSON recebidos.

### 3. Listagem de Organizações (`serviceBrowseOrganizations` no UNA)

*   **Funcionalidade UNA Original:**
    *   Filtros por categoria, autor, termo de busca, status, etc.
    *   Ordenação e paginação.
    *   Busca e formata um resumo de cada organização (logo, nome, snippet de descrição, contadores).
    *   Renderiza a lista.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/organizations`
    *   **Controller Elixir:**
        1.  Recebe e valida query parameters para filtros, ordenação, paginação, preload.
        2.  Chama `Deeper.Content.OrganizationsRepo.list_organizations(filters, pagination_opts, preload_opts)`.
    *   **`Deeper.Content.OrganizationsRepo.list_organizations/3`:**
        1.  Constrói e executa queries SQL (principal + contagem) com base nos filtros, ordenação e paginação.
        2.  Para cada organização na lista, aplica a lógica de preload (logo, categoria, resumo do autor) de forma otimizada (ex: buscando todos os logos necessários de uma vez).
        3.  Retorna a lista de organizações e metadados de paginação.

### 4. Gerenciamento de Membros/Administradores (se `bx_organizations_members` for usado)

*   **Funcionalidade UNA Original:**
    *   Permite que administradores da organização adicionem/removam outros perfis como membros ou promovam/rebaixem seus papéis.
    *   Usuários podem solicitar adesão ou sair de uma organização.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoints:**
        *   `GET /api/v1/organizations/{org_id}/members`
        *   `POST /api/v1/organizations/{org_id}/members` (Adicionar/convidar membro)
        *   `PUT /api/v1/organizations/{org_id}/members/{profile_id}` (Atualizar papel)
        *   `DELETE /api/v1/organizations/{org_id}/members/{profile_id}` (Remover membro)
    *   **Controller Elixir:**
        1.  Verifica se o usuário autenticado é um administrador da organização (`org_id`) antes de permitir operações de escrita.
        2.  Chama as funções apropriadas do `OrganizationsRepo` (`add_member_to_organization`, `update_organization_member_role`, `remove_member_from_organization`).
    *   **`Deeper.Content.OrganizationsRepo`:** Contém o SQL para gerenciar a tabela `bx_organizations_members`.

### 5. \"Seguir\" uma Organização (Tornar-se Fã)

*   **Funcionalidade UNA Original:**
    *   Usuários podem \"seguir\" ou \"tornar-se fã\" de uma organização. Isso geralmente usa o sistema de conexões do UNA (`sys_connections` com um tipo específico, ou uma tabela `bx_organizations_fans`).
    *   O contador `fans_count` em `bx_organizations_data` é atualizado.
*   **Mapeamento para API \"Deeper\":**
    *   **API de Conexões (`08_advanced_features/sys_connections_api.md`):**
        *   `POST /api/v1/profiles/{organization_profile_id}/follow` (onde `organization_profile_id` é o `sys_profiles.id` da organização).
        *   `DELETE /api/v1/profiles/{organization_profile_id}/unfollow`
    *   **Lógica de Atualização do Contador:**
        *   O `ConnectionsRepo` (ou um serviço de conexões), após criar/remover a conexão de \"seguir\", chamará `Deeper.Content.OrganizationsRepo.update_organization_fans_count(org_data_id, delta)` para manter o contador `fans_count` sincronizado. `org_data_id` é o `content_id` do perfil da organização.

### 6. Permissões de Conteúdo da Organização (`allow_post_to`, `allow_contact_to`)

*   **Funcionalidade UNA Original:**
    *   `allow_post_to`: Define quem pode postar no \"mural\" ou feed da organização (ex: admins, membros, todos os seguidores).
    *   `allow_contact_to`: Define quem pode iniciar contato direto com a organização.
*   **Mapeamento para API \"Deeper\":**
    *   Os valores dessas colunas (`c` para admins/criador, `m` para membros, `f` para fãs/seguidores, `3` para todos os usuários logados, etc.) são armazenados em `bx_organizations_data`.
    *   **Validação na API:**
        *   Quando um usuário tenta postar no feed de uma organização (via uma API de posts/feed), o backend verificará `bx_organizations_data.allow_post_to`. Isso envolverá:
            1.  Obter o perfil da organização.
            2.  Verificar o `profile_id` do usuário autenticado e seu relacionamento com a organização (é o autor? é membro com papel X? é seguidor?).
            3.  Comparar com o valor de `allow_post_to`.
        *   Lógica similar para `allow_contact_to`.
    *   Esta validação pode ocorrer em um módulo de serviço específico ou nos controllers das APIs de postagem/contato.

### 7. Atualização de Contadores de Interação (Comentários, Denúncias)

*   **Funcionalidade UNA Original:**
    *   Contadores como `comments_count`, `reports_count` em `bx_organizations_data` são atualizados quando ocorrem as respectivas interações.
*   **Mapeamento para API \"Deeper\":**
    *   Semelhante ao `fans_count`. Quando um comentário é adicionado/removido para uma organização (via API de Comentários), o `CommentsRepo` (ou serviço) chamará uma função no `OrganizationsRepo` para atualizar `comments_count`.
    *   Ex: `OrganizationsRepo.update_organization_interaction_count(org_id, :comments, delta)`

Este mapeamento ajuda a traduzir a lógica de negócios do módulo PHP para uma arquitetura de API RESTful, distribuindo responsabilidades e garantindo que as funcionalidades core sejam mantidas.