# Documentação Deeper: Módulo de Conteúdo - Pessoas (`bx_persons`)

Este documento descreve a API \"Deeper\" para o módulo \"Pessoas\" (`bx_persons`) do sistema UNA. Este módulo é fundamental, pois gerencia os perfis de usuário do tipo \"pessoa\", que são a base para muitas interações sociais na plataforma.

**Propósito do Módulo no UNA:**

*   Armazenar dados detalhados de perfis de indivíduos (nome completo, descrição, avatar, capa, etc.).
*   Gerenciar conexões entre perfis (amizades, seguidores - embora a lógica de conexão possa ser um sistema separado referenciado aqui).
*   Fornecer blocos de página para exibir informações de perfil, listas de perfis, etc.
*   Integrar-se com sistemas de comentários, votos, favoritos, denúncias para os perfis.

**Funcionalidades Chave da API \"Deeper\" para `bx_persons`:**

*   Obter dados detalhados de um perfil de pessoa (já parcialmente coberto pela API de `GET /api/v1/profiles/me` e `GET /api/v1/profiles/{profile_id}`).
*   Listar perfis de pessoas com filtros, ordenação e paginação.
*   (Se aplicável e não totalmente coberto pela API de Contas/Perfis) Atualizar dados específicos do perfil de pessoa.
*   Gerenciar fotos de perfil e de capa.
*   Expor dados para blocos de \"serviço\" relacionados a pessoas (ex: \"Últimos membros\", \"Amigos de João\").
*   Integrar com APIs de comentários, votos, etc., para perfis de pessoas.

## Estrutura da Documentação para `bx_persons`:

1.  [**Modelo de Dados e Esquema SQLite (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` para `bx_persons_data`, `bx_persons_pictures`, `bx_persons_pictures_resized`, `bx_persons_cmts` (comentários de perfil), `bx_persons_views_track`, etc.
    *   (Nota: `bx_persons_data` já foi parcialmente definido em `01_system_core/sys_accounts_and_profiles/database_schema.md` devido à sua forte ligação com `sys_profiles`. Aqui podemos refinar ou adicionar tabelas específicas do módulo `bx_persons`.)

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Documentação e código para as migrações das tabelas de `bx_persons`.

3.  [**Módulos de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Detalha o `Deeper.Content.PersonsRepo` (e possivelmente outros repositórios auxiliares como `PersonsPicturesRepo`).
    *   [**Queries SQL Otimizadas (`data_access_module/sql_queries.md`)**](./data_access_module/sql_queries.md): Foco nas queries para listar perfis com filtros complexos, buscar dados para blocos de serviço, etc.

4.  [**Endpoints da API (`api_endpoints/`)**](./api_endpoints/README.md):
    *   Endpoints específicos para `bx_persons` que não são cobertos pela API genérica de `/profiles`.
    *   Ex: `GET /api/v1/persons` (para listar), `POST /api/v1/persons/{person_id}/pictures` (para upload de avatar).

5.  [**Mapeamento da Lógica de \"Serviço\" PHP (`service_logic_mapping.md`)**](./service_logic_mapping.md):
    *   Como os blocos de serviço do UNA (ex: `service_entity_friends`, `service_latest_profiles`) serão implementados pela API \"Deeper\".

6.  [**Objetos Associados (`associated_objects/`)**](./associated_objects/README.md):
    *   Como acessar comentários (`bx_persons_cmts`), votos, favoritos, etc., para um perfil de pessoa.

## Relação com `sys_accounts` e `sys_profiles`:

O módulo `bx_persons` está intrinsecamente ligado às tabelas `sys_accounts` e `sys_profiles`.
*   Um registro em `sys_accounts` representa uma conta de login.
*   Um registro em `sys_profiles` com `type = 'bx_persons'` liga uma `account_id` a um `content_id`.
*   Esse `content_id` é o `id` de um registro na tabela `bx_persons_data`.

A API \"Deeper\" para perfis (`GET /api/v1/profiles/me`, `GET /api/v1/profiles/{profile_id}`) já lida com a busca e apresentação combinada desses dados. Os endpoints específicos de `bx_persons` podem focar em listagens mais especializadas ou operações que não se encaixam no contexto genérico de \"perfil\".