# Documentação Deeper: API de Administração (Studio)

Este diretório descreve os endpoints e funcionalidades da API \"Deeper\" destinados a tarefas administrativas e de moderação, similar ao que seria encontrado no \"Studio\" do UNA.

A API de Administração permitirá que usuários com privilégios apropriados (administradores, moderadores) gerenciem diversos aspectos da plataforma, incluindo conteúdo gerado por usuários, configurações do sistema, gerenciamento de usuários, etc.

## Princípios Gerais:

*   **Autenticação e Autorização:** Todos os endpoints de administração exigirão autenticação robusta e verificação de papéis/permissões específicas de administrador/moderador. O JWT de um administrador conterá um papel ou claim que o identifica como tal.
*   **Endpoints Dedicados vs. Extensão de Existentes:**
    *   Para algumas operações (ex: listar *todos* os artigos, incluindo rascunhos de outros usuários), podem ser endpoints dedicados (ex: `/api/v1/admin/articles`).
    *   Para outras (ex: deletar *qualquer* artigo), o endpoint existente (`DELETE /api/v1/articles/{id}`) pode ser usado, mas a lógica de permissão no backend verificará se o solicitante é o autor OU um administrador.
*   **Retornos Detalhados:** As respostas da API de administração podem incluir mais informações ou metadados do que os endpoints públicos.
*   **Logging de Ações:** Ações administrativas críticas devem ser logadas para fins de auditoria (ver `sys_audit` no UNA).

## Estrutura dos Submódulos de Administração:

Cada subdiretório aqui representará uma área de administração:

1.  [**Gerenciamento de Conteúdo (`content_management/`)**](./content_management/README.md):
    *   Moderação e gerenciamento de tipos de conteúdo específicos (artigos, eventos, grupos, etc.).
    *   Exemplo: `content_management/articles_admin_api.md`.

2.  [**Gerenciamento de Usuários e Perfis (`users_and_profiles_admin_api.md`)**](./users_and_profiles_admin_api.md):
    *   Visualizar, editar, suspender, excluir contas e perfis de usuários.
    *   Gerenciar papéis e permissões de usuários (interação com ACL).

3.  [**Configurações do Sistema (`system_settings_admin_api.md`)**](./system_settings_admin_api.md):
    *   Endpoints para visualizar e modificar configurações de `sys_options`.

4.  [**Gerenciamento de Módulos (`modules_admin_api.md`)**](./modules_admin_api.md):
    *   Listar, habilitar, desabilitar módulos (interação com `sys_modules`).

5.  *(Outras seções podem ser adicionadas conforme necessário, como Gerenciamento de ACL, Construtor de Páginas, Moderação de Interações, Localização, etc.)*

## Abordagem de Implementação:

*   Os controllers da API de administração (ex: `DeeperWeb.Admin.ArticleController`) podem residir em um namespace `Admin` para separação.
*   Plugs específicos podem ser usados para garantir que apenas administradores acessem esses endpoints ou funcionalidades.
*   A lógica de negócios ainda pode residir nos Contextos/Serviços existentes, mas com verificações de permissão adicionais, ou podem existir funções de contexto específicas para administradores que bypassam algumas restrições de propriedade.

Esta API fornecerá as ferramentas necessárias para a manutenção e operação da plataforma \"Deeper\".