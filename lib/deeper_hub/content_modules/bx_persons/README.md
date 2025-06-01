# Documentação Deeper: API para Módulo de Pessoas (`bx_persons`)

Esta seção detalha a API RESTful \"Deeper\" para interagir com os dados do módulo \"Pessoas\" (`bx_persons`) do UNA. O módulo `bx_persons` é geralmente usado para gerenciar perfis de usuários individuais.

As funcionalidades cobertas incluem a listagem de perfis de pessoas, visualização de detalhes de um perfil, criação, atualização e exclusão (com as devidas permissões), além de interações como upload de fotos, visualizações, comentários, etc., específicos para esses perfis.

## Tabelas Relevantes do UNA (Foco `bx_persons`):

*   **`bx_persons_data`**: Tabela principal com os dados dos perfis de pessoa (já definida em `01_system_core/sys_accounts_and_profiles/database_schema.md` e migrada).
*   **`sys_profiles`**: Liga `bx_persons_data` a `sys_accounts` (também já definida e migrada).
*   **`bx_persons_pictures`**: Armazena as imagens de perfil (galeria, não apenas a foto principal).
*   **`bx_persons_pictures_resized`**: Armazena versões redimensionadas das imagens.
*   **`bx_persons_views_track`**: Rastreia visualizações de perfis.
*   **`bx_persons_cmts`**: Tabela de comentários para perfis de pessoas (se o UNA usa uma tabela de comentários específica para o módulo em vez de um sistema genérico para todos os comentários).
*   **`bx_persons_favorites_track`**: Rastreia quem favoritou quais perfis.
*   **`bx_persons_reports_track`**: Rastreia denúncias de perfis.
*   **`bx_persons_scores_track`**: Rastreia pontuações (up/down) de perfis.
*   **`bx_persons_votes_track`**: Rastreia votos/avaliações de perfis.
*   **`bx_persons_meta_keywords`, `bx_persons_meta_locations`, `bx_persons_meta_mentions`**: Metadados associados.
*   **`bx_persons_skills`**: Habilidades associadas a perfis.

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados Adicional (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas específicas do `bx_persons` que ainda não foram cobertas (ex: `bx_persons_pictures`, `_views_track`, `_cmts`, etc.).

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar essas tabelas adicionais.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Detalha o `Deeper.Content.PersonsRepo` (ou estende o já existente de `01_system_core`) com funções para CRUD em `bx_persons_data` e para interagir com as tabelas relacionadas (fotos, visualizações, comentários, etc.).

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para listar pessoas, obter detalhes de um perfil, criar/atualizar/deletar perfis, gerenciar fotos, etc.

5.  [**Mapeamento de Lógica de \"Serviço\" (`service_logic_mapping.md`)**](./service_logic_mapping.md):
    *   Descreve como as \"service calls\" do módulo `bx_persons` (usadas em blocos de página do UNA PHP) são mapeadas para dados ou funcionalidades expostas pela API \"Deeper\".

6.  [**Interações Associadas (`associated_objects.md`)**](./associated_objects.md):
    *   Detalha como os sistemas genéricos de comentários, votos, favoritos, etc. (de `04_interaction_systems/`) são aplicados e acessados no contexto dos perfis de `bx_persons`.

## Fluxos Comuns:

*   **Listar Perfis:** `GET /api/v1/persons` com paginação, filtros (localização, gênero) e ordenação (mais recentes, mais vistos).
*   **Ver Perfil:** `GET /api/v1/persons/{profile_id_or_uri}`.
*   **Criar Perfil:** Geralmente parte do fluxo de registro em `POST /api/v1/auth/register` ou um endpoint de admin.
*   **Atualizar Perfil:** `PUT /api/v1/persons/me` (para o usuário logado atualizar seu próprio perfil) ou `PUT /api/v1/persons/{profile_id}` (para admin).
*   **Upload de Foto de Perfil:** `POST /api/v1/persons/me/pictures`.
*   **Adicionar Comentário a um Perfil:** `POST /api/v1/persons/{profile_id}/comments` (utilizando o sistema genérico de comentários).