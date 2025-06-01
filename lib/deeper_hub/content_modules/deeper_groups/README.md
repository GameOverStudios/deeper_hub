# Documentação Deeper: Módulo de Grupos (`deeper_groups`)

Este módulo da API \"Deeper\" é responsável pelo gerenciamento de grupos ou comunidades criadas por usuários. Ele permitirá a criação, descoberta, adesão e interação dentro desses grupos, replicando funcionalidades encontradas em módulos como `bx_groups` do sistema UNA.

## Responsabilidades Principais:

*   Criação, leitura, atualização e exclusão (CRUD) de grupos.
*   Armazenamento de informações do grupo: nome, descrição, tipo de privacidade (público, privado, secreto), regras, imagem de capa/avatar.
*   Gerenciamento de membros do grupo (administradores, moderadores, membros).
*   Controle de convites e solicitações de adesão.
*   Possibilidade de postar conteúdo dentro do grupo (ex: discussões, anúncios - pode integrar com `deeper_articles` ou ter um sistema de posts específico para grupos).
*   Integração com sistemas de comentários, votos, favoritos (para o grupo em si e para o conteúdo dentro do grupo).

## Componentes Detalhados:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite para a tabela principal `deeper_groups`, a tabela de membros `deeper_group_members`, e tabelas de suporte como `deeper_group_invites` ou `deeper_group_join_requests`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir e sua documentação para criar as tabelas do módulo de grupos.

3.  [**Módulos de Acesso a Dados (`data_access_modules.md`)**](./data_access_modules.md):
    *   Descreve os módulos Elixir (ex: `Deeper.Content.GroupsRepo`) que encapsulam as queries SQL.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para todas as operações relacionadas a grupos, membros e conteúdo do grupo.

5.  [**Mapeamento da Lógica de Serviço (`service_logic_mapping.md`)**](./service_logic_mapping.md):
    *   Descreve como funcionalidades que seriam \"serviços\" no UNA (ex: \"meus grupos\", \"grupos populares\", \"feed de atividades do grupo\") serão implementadas na API.

6.  [**Objetos Associados (`associated_objects.md`)**](./associated_objects.md):
    *   Detalha como este módulo se integra com comentários, votos, favoritos, gerenciamento de arquivos (para avatares/capas de grupo), e potencialmente o módulo `deeper_articles` para posts dentro do grupo.

## Estrutura da Tabela Principal (`deeper_groups` - a ser detalhada em `database_schema.md`):

*   `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
*   `profile_id` (INTEGER, FK para `sys_profiles.id` - criador/proprietário do grupo)
*   `title` (TEXT NOT NULL)
*   `slug` (TEXT NOT NULL UNIQUE)
*   `description` (TEXT)
*   `rules` (TEXT - opcional, regras do grupo)
*   `avatar_file_id` (INTEGER, FK para `deeper_files.id` - opcional)
*   `cover_file_id` (INTEGER, FK para `deeper_files.id` - opcional)
*   `privacy_level` (TEXT NOT NULL DEFAULT 'public' CHECK(privacy_level IN ('public', 'private', 'secret')))
    *   `public`: Qualquer um pode ver e entrar (ou solicitar entrada).
    *   `private`: Qualquer um pode ver, mas precisa solicitar entrada. Conteúdo visível apenas para membros.
    *   `secret`: Não listado, entrada apenas por convite. Conteúdo visível apenas para membros.
*   `allow_member_invites` (INTEGER NOT NULL DEFAULT 1) -- Se membros podem convidar outros.
*   `join_approval_mode` (TEXT NOT NULL DEFAULT 'open' CHECK(join_approval_mode IN ('open', 'approval_required', 'invite_only'))) -- Para grupos públicos/privados.
*   `status` (TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'suspended')))
*   `members_count` (INTEGER NOT NULL DEFAULT 0) -- Denormalizado, atualizado por triggers/aplicação
*   `created_at` (INTEGER NOT NULL - Unix Timestamp)
*   `updated_at` (INTEGER NOT NULL - Unix Timestamp)
*   Contadores (views, posts_count - se houver posts no grupo)

Este módulo formará a base para a construção de comunidades dentro da plataforma \"Deeper\".