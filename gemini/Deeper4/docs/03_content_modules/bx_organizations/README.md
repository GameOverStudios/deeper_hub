# Documentação Deeper: Módulo Organizações (`bx_organizations`)

Este módulo da API \"Deeper\" é responsável por gerenciar perfis do tipo \"Organização\". No sistema UNA, `bx_organizations` permite a criação de perfis para empresas, instituições, grupos formais, etc., de forma similar a como `bx_persons` gerencia perfis de indivíduos.

A API \"Deeper\" fornecerá endpoints para criar, ler, atualizar e deletar (CRUD) perfis de organização, e para listar organizações com filtros e paginação.

## Responsabilidades Principais da API:

*   Permitir que contas de usuário (`sys_accounts`) criem e gerenciem perfis de organização.
*   Associar um perfil de organização a uma entrada na tabela `sys_profiles` com `type = 'bx_organizations'`.
*   Armazenar e recuperar dados específicos de organizações (nome, descrição, website, localização, membros, etc.).
*   Gerenciar imagens de perfil (logo) e capa para organizações.
*   Listar organizações com opções de busca e filtragem.

## Estrutura da Documentação do Módulo `bx_organizations`:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite da tabela principal `bx_organizations_data` e quaisquer tabelas auxiliares (ex: para membros, categorias de organização).

2.  [**Migrações Elixir (`migrations/README.md`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir e sua documentação para criar as tabelas de organizações.

3.  [**Módulos de Acesso a Dados (`data_access_modules.md`)**](./data_access_modules.md):
    *   Descreve os módulos Elixir (ex: `Deeper.Content.OrganizationsRepo`) que encapsulam as queries SQL para interagir com as tabelas de organizações.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para todas as operações relacionadas a perfis de organização.

5.  [**Mapeamento da Lógica de Serviço (`service_logic_mapping.md`)**](./service_logic_mapping.md):
    *   Analisa como as funcionalidades do módulo `bx_organizations` original do UNA serão traduzidas para a lógica da API Elixir.

6.  [**Objetos Associados (`associated_objects.md`)**](./associated_objects.md):
    *   Detalha como sistemas de interação (comentários, votos, favoritos, denúncias, seguidores/membros) se aplicam aos perfis de organização.

## Tabelas Principais do UNA (Referência para Adaptação):

*   `bx_organizations_data`: Tabela principal para os dados específicos de organizações. Similar à `bx_persons_data`.
*   `bx_organizations_pics`, `bx_organizations_pics_resized`: Para imagens de logo (se não usar `sys_files`).
*   `bx_organizations_admins`: Para gerenciar administradores/membros da organização (se for além do `author_id`).
*   Tabelas de rastreamento para visualizações, comentários, votos, seguidores, etc., específicas do módulo (ex: `bx_organizations_views_track`, `bx_organizations_cmts`, `bx_organizations_fans`).

## Considerações para a API `bx_organizations`:

*   **Vínculo com `sys_profiles`:** Uma organização criada resultará em uma entrada em `sys_profiles` com `type='bx_organizations'` e `content_id` apontando para o ID da organização em `bx_organizations_data`.
*   **Autoria e Administração:** O perfil (`sys_profiles.id`) que cria a organização é o `author_id`. Pode haver um sistema mais complexo para múltiplos administradores/membros com diferentes papéis dentro da organização.
*   **Imagens:** Logo e imagem de capa serão gerenciados, idealmente integrados com o `06_file_management/`.
*   **Interações:** Organizações poderão ser seguidas (fans), avaliadas, comentadas, etc.

Esta documentação guiará a implementação da API para o módulo `bx_organizations`, permitindo que a plataforma \"Deeper\" suporte perfis de organizações de forma robusta.