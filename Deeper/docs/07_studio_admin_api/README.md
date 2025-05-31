# Documentação Deeper: API de Administração (Studio API)

Este diretório descreve a API de Administração (\"Studio API\") para o backend \"Deeper\". Esta API é destinada a ser consumida por uma interface de painel de administração (semelhante ao \"Studio\" do UNA) para gerenciar todos os aspectos do sistema.

**Objetivo Principal:** Fornecer endpoints RESTful seguros e abrangentes para que administradores possam configurar o sistema, gerenciar usuários, módulos, conteúdo, permissões, e outras funcionalidades core da plataforma \"Deeper\".

**Princípios de Design da Studio API:**

*   **Segurança:** Todos os endpoints requerem autenticação de administrador e verificação de permissões granulares (se aplicável, ex: um \"moderador de conteúdo\" pode ter acesso a algumas partes, mas não a configurações do sistema).
*   **Consistência:** Seguir as mesmas convenções de design da API pública (`api_design_conventions.md`), mas com um foco em operações de gerenciamento.
*   **Abrangência:** Idealmente, cobrir todas as funcionalidades de gerenciamento que o Studio do UNA oferece.
*   **CRUD:** Muitos endpoints seguirão padrões CRUD (Create, Read, Update, Delete) para as entidades gerenciáveis.
*   **Operações em Lote (Bulk):** Onde apropriado, suportar ações em múltiplos itens (ex: deletar vários usuários, aprovar vários comentários).

## Estrutura da Documentação da Studio API:

Devido à vastidão das funcionalidades de administração, esta seção será organizada por áreas de gerenciamento, espelhando as seções típicas de um painel de administração. Cada subdiretório conterá um `README.md` e, se necessário, `api_endpoints.md` específicos.

1.  [**Autenticação e Autorização da API de Admin (`auth/`)**](./auth/README.md):
    *   Como os administradores se autenticam para usar a Studio API.
    *   Gerenciamento de papéis e permissões administrativas (se houver um sistema de ACL para os próprios administradores).

2.  [**Gerenciamento do Dashboard (`dashboard/`)**](./dashboard/README.md):
    *   Endpoints para obter estatísticas e informações resumidas para o painel principal do admin.

3.  [**Gerenciamento de Configurações (`settings/`)**](./settings/README.md):
    *   API para ler e **modificar** todas as configurações do sistema (`sys_options`).
    *   Endpoints para gerenciar \"mixes\" de temas/configurações (`sys_options_mixes`).

4.  [**Gerenciamento de Módulos (`modules/`)**](./modules/README.md):
    *   API para listar, visualizar detalhes, **habilitar, desabilitar, (e potencialmente no futuro) instalar/desinstalar** módulos (`sys_modules`).
    *   Endpoints para gerenciar dependências e relações entre módulos.

5.  [**Gerenciamento de Usuários e Perfis (`users_and_profiles/`)**](./users_and_profiles/README.md):
    *   API CRUD completa para `sys_accounts` e `sys_profiles`.
    *   Gerenciamento de dados de perfis específicos (ex: `bx_persons_data`).
    *   Ações como confirmar email, banir usuário, mudar papel, etc.

6.  [**Gerenciamento de ACL (`acl/`)**](./acl/README.md):
    *   API CRUD para `sys_acl_levels`, `sys_acl_actions`, `sys_acl_matrix`.
    *   API para gerenciar associações de membros a níveis (`sys_acl_levels_members`).

7.  [**Construtor de Páginas (`page_builder/`)**](./page_builder/README.md):
    *   API CRUD para `sys_objects_page`, `sys_pages_blocks`, `sys_pages_layouts`.
    *   Endpoints para reordenar blocos, alterar conteúdo de blocos HTML, etc.

8.  [**Gerenciamento de Menus (`menus/`)**](./menus/README.md):
    *   API CRUD para `sys_objects_menu`, `sys_menu_sets`, `sys_menu_items`.

9.  [**Gerenciamento de Formulários (`forms/`)**](./forms/README.md):
    *   API CRUD para `sys_objects_form`, `sys_form_inputs`, `sys_form_displays`, `sys_form_display_inputs`, `sys_form_pre_lists`, `sys_form_pre_values`.

10. [**Gerenciamento de Grids (`grids/`)**](./grids/README.md):
    *   API CRUD para `sys_objects_grid`, `sys_grid_fields`, `sys_grid_actions`.

11. [**Gerenciamento de Conteúdo (por módulo)** (`content_management/`)](./content_management/README.md):
    *   Subdiretórios por módulo de conteúdo (ex: `bx_persons/`, `bx_posts/`) com APIs para moderar/gerenciar o conteúdo específico daquele módulo (ex: editar qualquer perfil de pessoa, deletar qualquer post).

12. [**Gerenciamento de Interações (`interactions_management/`)**](./interactions_management/README.md):
    *   API para moderar comentários, gerenciar denúncias, etc.
    *   Endpoints para visualizar e gerenciar `sys_objects_cmts`, `sys_objects_vote`, etc.

13. [**Gerenciamento de Localização (`localization/`)**](./localization/README.md):
    *   API CRUD para `sys_localization_languages`, `sys_localization_categories`, `sys_localization_keys`, `sys_localization_strings`.

14. [**Ferramentas do Sistema (`system_tools/`)**](./system_tools/README.md):
    *   Endpoints para limpar cache, visualizar logs (se a API \"Deeper\" tiver seu próprio sistema de logs), gerenciar tarefas agendadas (`sys_cron_jobs` - se a API \"Deeper\" controlar isso).

15. [**Gerenciamento de Armazenamento (`storage/`)**](./storage/README.md):
    *   API CRUD para `sys_objects_storage`.
    *   Visualizar estatísticas de uso, gerenciar arquivos (ex: deletar arquivos órfãos).

## Considerações Gerais para a Studio API:

*   **Granularidade:** A API precisa ser granular o suficiente para permitir que uma interface de administração rica seja construída.
*   **Validação:** Validação rigorosa de todos os inputs.
*   **Respostas Detalhadas:** Respostas de sucesso e erro devem ser claras e fornecer feedback suficiente.
*   **Segurança:** Medidas contra CSRF, XSS (embora seja uma API, a interface que a consome precisa ser segura), e garantia de que apenas administradores autorizados possam acessar.
*   **Impacto das Ações:** Muitas ações de administração podem ter um grande impacto no sistema. Operações destrutivas devem ser claramente marcadas e, idealmente, ter mecanismos de confirmação (embora isso seja mais na UI do cliente).
*   **Portabilidade da Lógica de Admin do UNA PHP:** O Studio do UNA PHP contém muita lógica de negócios para gerenciar essas entidades. Portar ou replicar essa lógica para os serviços Elixir que suportam a Studio API será um esforço significativo.

A Studio API é essencialmente a \"sala de controle\" do sistema \"Deeper\" e exigirá um planejamento e implementação cuidadosos.