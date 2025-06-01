# Documentação Deeper: API de Administração (Studio API)

Este diretório detalha a API RESTful \"Deeper\" projetada para fins administrativos, similar ao que o \"Studio\" do UNA oferece. Esta API permitirá o gerenciamento de vários aspectos do sistema, desde conteúdo e usuários até configurações e módulos.

**Público Alvo:** Desenvolvedores de uma interface de administração (seja web ou de outro tipo) para a plataforma \"Deeper\".

**Autenticação e Autorização:**
*   Todos os endpoints nesta API exigirão autenticação robusta.
*   A autorização será baseada em papéis de administrador ou permissões ACL específicas para tarefas administrativas. Usuários comuns não terão acesso a estes endpoints.

## Objetivos da API de Administração:

*   Fornecer endpoints para CRUD (Criar, Ler, Atualizar, Deletar) em entidades centrais do sistema.
*   Permitir a moderação de conteúdo e usuários.
*   Permitir a configuração de parâmetros do sistema e módulos.
*   Facilitar o gerenciamento de módulos, níveis de acesso (ACL), e outras funcionalidades de back-office.

## Estrutura da Documentação da API de Administração:

A documentação será dividida em seções lógicas, cada uma cobrindo uma área de administração:

1.  [**Gerenciamento de Conteúdo (`content_management/`)**](./content_management/README.md):
    *   APIs para administrar os diferentes tipos de conteúdo criados pelos usuários (ex: moderar artigos, gerenciar listagens de marketplace, eventos, grupos, etc.).

2.  [**Gerenciamento de Usuários e Perfis (`users_and_profiles_admin_api.md`)**](./users_and_profiles_admin_api.md):
    *   APIs para listar, visualizar, criar, editar, banir, e deletar contas de usuário e seus perfis associados.

3.  [**Configurações do Sistema (`system_settings_admin_api.md`)**](./system_settings_admin_api.md):
    *   API para ler e modificar as configurações globais do sistema armazenadas em `sys_options`.

4.  [**Gerenciamento de Módulos (`modules_admin_api.md`)**](./modules_admin_api.md):
    *   API para listar módulos do sistema (baseado em `sys_modules`), habilitar/desabilitar (conceitualmente, já que o backend Elixir pode não ter módulos dinâmicos da mesma forma que o PHP UNA).

5.  [**Gerenciamento de ACL (`acl_admin_api.md`)**](./acl_admin_api.md):
    *   API para gerenciar níveis de acesso (`sys_acl_levels`), ações (`sys_acl_actions`), e a matriz de permissões (`sys_acl_matrix`).

6.  [**Construtor de Páginas (`page_builder_admin_api.md`)**](./page_builder_admin_api.md):
    *   API para gerenciar objetos de página (`sys_objects_page`), blocos (`sys_pages_blocks`), layouts (`sys_pages_layouts`), e menus (`sys_objects_menu`, `sys_menu_items`).

7.  [**Ferramentas do Sistema (`system_tools_admin_api.md`)**](./system_tools_admin_api.md):
    *   APIs para tarefas como gerenciamento de cache, visualização de logs do sistema, informações do servidor, etc.

8.  [**Busca Avançada (`advanced_search_admin_api.md`)**](./advanced_search_admin_api.md):
    *   API para configurar os parâmetros de busca estendida (se `sys_objects_search_extended` for implementado).

9.  [**SEO (`seo_admin_api.md`)**](./seo_admin_api.md):
    *   API para gerenciar permalinks, regras de reescrita, e outros metadados SEO (baseado em `sys_seo_*`).

10. [**Templates de Email (`email_templates_admin_api.md`)**](./email_templates_admin_api.md):
    *   API para gerenciar os templates de email do sistema (`sys_email_templates`).

11. [**Visualizador de Log de Auditoria (`audit_log_viewer_api.md`)**](./audit_log_viewer_api.md):
    *   API para buscar e visualizar entradas do log de auditoria (`sys_audit`).

## Considerações Gerais para a API de Admin:

*   **Granularidade:** Os endpoints devem ser granulares o suficiente para permitir um controle fino, mas também oferecer operações em lote onde apropriado.
*   **Respostas Detalhadas:** As respostas devem fornecer informações suficientes para que a interface de administração possa exibir o estado atual dos recursos.
*   **Segurança:** A segurança é primordial. Validações rigorosas de entrada e verificações de permissão são essenciais.

Esta API de Administração é a espinha dorsal para o gerenciamento da plataforma \"Deeper\" por operadores autorizados.