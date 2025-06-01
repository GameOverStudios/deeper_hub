# Documentação Deeper: API de Administração (Studio API)

Este diretório detalha a API RESTful \"Deeper\" destinada ao painel de administração (referido como \"Studio\" no contexto do UNA). Esta API permitirá que administradores gerenciem todos os aspectos do sistema, desde usuários e conteúdo até configurações e módulos.

## Objetivos Principais:

*   Fornecer endpoints seguros e granulares para todas as operações de administração.
*   Permitir o gerenciamento de:
    *   Usuários, Perfis e Níveis de Acesso (ACL).
    *   Conteúdo de todos os módulos (artigos, eventos, grupos, etc.).
    *   Configurações globais e de módulos (`sys_options`).
    *   Estrutura do site (Páginas, Blocos, Menus, Formulários, Grades).
    *   Módulos do sistema \"Deeper\" (habilitação, desabilitação, configurações conceituais).
    *   Ferramentas do sistema (logs, cache, etc.).
    *   Internacionalização e Localização.
*   Garantir que todas as operações de administração sejam devidamente autenticadas e autorizadas com base em papéis/permissões de administrador.

## Estrutura da Documentação da API de Administração:

Cada subdiretório ou arquivo `.md` aqui representará uma área específica da administração:

*   **Gerenciamento de Conteúdo (`content_management/`)**: Endpoints para CRUD em todos os tipos de conteúdo dos módulos.
*   **Gerenciamento de Usuários e Perfis (`users_and_profiles_admin_api.md`)**: Gerenciar contas, perfis, banimentos, etc.
*   **Gerenciamento de Configurações do Sistema (`system_settings_admin_api.md`)**: Ler e atualizar `sys_options`.
*   **Gerenciamento de Módulos (`modules_admin_api.md`)**: Gerenciar os módulos do sistema \"Deeper\".
*   **Gerenciamento de ACL (`acl_admin_api.md`)**: Gerenciar níveis, ações e a matriz de permissões.
*   **Construtor de Páginas (`page_builder_admin_api.md`)**: Gerenciar `sys_objects_page`, `sys_pages_blocks`, etc.
*   **Gerenciador de Menus (`menu_admin_api.md`)**: Gerenciar `sys_objects_menu`, `sys_menu_items`.
*   **Gerenciador de Formulários e Grades (`forms_grids_admin_api.md`)**: Gerenciar `sys_objects_form`, `sys_objects_grid`.
*   **Outras Ferramentas de Administração**: Logs, SEO, Templates de Email, etc.

## Convenções Específicas da API de Administração:

*   **Prefixo de Endpoint:** Todos os endpoints da API de administração usarão um prefixo distinto, por exemplo: `/api/v1/admin/...`.
*   **Autenticação e Autorização:**
    *   **Obrigatória:** Todas as requisições à API de administração devem ser autenticadas usando JWT.
    *   **Verificação de Papel/Permissão:** Além da autenticação, o backend verificará se o usuário autenticado possui o papel de administrador ou permissões específicas para realizar a operação solicitada. Isso pode envolver a consulta a `sys_accounts.role` ou uma integração mais fina com `sys_acl_actions` para ações de administração.
*   **Respostas:** Seguirão as convenções gerais da API \"Deeper\" (JSON, códigos de status HTTP, formato de erro).
*   **Paginação e Filtragem:** Endpoints que listam recursos de administração (ex: listar todos os usuários, todos os artigos) devem suportar paginação e filtragem, similarmente aos endpoints públicos.

## Considerações de Segurança:

*   A API de administração expõe funcionalidades críticas. A segurança é primordial.
*   Rate limiting pode ser implementado para proteger contra abusos.
*   Auditoria detalhada de todas as ações de administração (a tabela `sys_audit` do UNA pode ser usada ou um sistema similar no \"Deeper\").

Esta API será a espinha dorsal para qualquer interface de administração construída para o sistema \"Deeper\", permitindo o controle total da plataforma de forma programática.