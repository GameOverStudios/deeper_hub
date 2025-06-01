# Documentação Deeper: API de Administração - Gerenciamento de Módulos

Este documento descreve os endpoints da API \"Deeper\" para administradores visualizarem e gerenciarem (de forma conceitual) os módulos que compõem a aplicação.

**Contexto:** No sistema UNA original, os módulos são pacotes de código PHP com seus próprios arquivos, instaladores, etc. No backend \"Deeper\" em Elixir, os \"módulos\" são mais representações lógicas das funcionalidades portadas ou inspiradas nos módulos UNA. O gerenciamento aqui não envolve instalação de código em tempo de execução, mas sim a configuração e o status das funcionalidades associadas a esses conceitos de módulo.

## Escopo e Funcionalidades:

*   Listar todos os módulos conceituais reconhecidos pelo sistema \"Deeper\".
*   Visualizar informações detalhadas sobre um módulo (ex: nome, versão portada/adaptada, descrição, status).
*   Habilitar/Desabilitar funcionalidades principais associadas a um módulo (se a arquitetura permitir tal alternância dinâmica). Isso pode envolver a alteração de flags de configuração específicas.
*   Acessar configurações específicas de um módulo (um subconjunto de `sys_options` ou configurações dedicadas).

## Tabelas Relevantes:

*   `sys_modules` (do UNA original): Esta tabela pode ser lida para obter a lista de módulos originais e suas informações (título, versão, fornecedor). O sistema \"Deeper\" pode ter um mapeamento ou uma representação interna de quais desses módulos foram portados ou têm funcionalidades equivalentes.
*   `sys_options`: Muitas configurações de módulos estarão aqui, prefixadas com o nome do módulo (ex: `bx_persons_option_xyz`).

## Módulos de Acesso a Dados:

*   `Deeper.SystemCore.OptionsRepo` (para configurações).
*   Um novo módulo, talvez `Deeper.SystemCore.ModulesRepo` ou `ModuleService`, poderia ser responsável por listar os módulos \"Deeper\" e gerenciar seu estado conceitual.

## Endpoints da API de Administração para Módulos

Todos os endpoints estão sob `/api/v1/admin/modules/...` e requerem autenticação de administrador.

### 1. Listar Módulos do Sistema \"Deeper\"

*   **Endpoint:** `GET /api/v1/admin/modules`
*   **Propósito:** Retorna uma lista de todos os módulos conceituais reconhecidos pela aplicação \"Deeper\", com seu status e informações básicas.
*   **Autenticação:** Administrador.
*   **Lógica do Backend:**
    *   Pode consultar a tabela `sys_modules` do UNA para obter a lista base.
    *   Para cada módulo, verificar seu status no sistema \"Deeper\" (ex: \"Portado e Ativo\", \"Portado e Inativo\", \"Não Portado\"). Esse status pode vir de uma configuração interna do Deeper ou de flags em `sys_options`.
    *   Obter títulos traduzidos.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"name\": \"bx_persons\", // Nome do módulo original
          \"title\": \"People\", // Título traduzido
          \"vendor\": \"UNA\",
          \"version_original\": \"13.0.0\",
          \"version_deeper\": \"1.0.0\", // Versão da implementação Deeper
          \"status_deeper\": \"active\", // \"active\", \"inactive\", \"partially_implemented\", \"not_implemented\"
          \"is_core\": true, // Se é um módulo fundamental
          \"has_settings\": true, // Se há configurações específicas para este módulo
          \"description\": \"Manages user profiles of type person.\"
        },
        {
          \"name\": \"bx_events\",
          \"title\": \"Events\",
          \"vendor\": \"UNA\",
          \"version_original\": \"13.0.0\",
          \"version_deeper\": \"1.0.0\",
          \"status_deeper\": \"active\",
          \"is_core\": false,
          \"has_settings\": true,
          \"description\": \"Allows creation and management of events.\"
        },
        {
          \"name\": \"bx_chat_plus\",
          \"title\": \"Chat+\",
          \"vendor\": \"UNA\",
          \"version_original\": \"13.0.0\",
          \"version_deeper\": null,
          \"status_deeper\": \"not_implemented\",
          \"is_core\": false,
          \"has_settings\": false,
          \"description\": \"Advanced chat features.\"
        }
        // ... mais módulos ...
      ],
      \"pagination\": { /* ... se a lista for muito longa ... */ }
    }
```

```json
    {
      \"name\": \"bx_persons\",
      \"title\": \"People\",
      // ... outros campos como na lista ...
      \"deeper_related_objects\": {
        \"pages\": [\"bx_persons_home\", \"bx_persons_view_profile\"],
        \"forms\": [\"bx_persons_add\", \"bx_persons_edit\"],
        \"grids\": [\"bx_persons_administration\"]
      },
      \"settings_endpoint\": \"/api/v1/admin/settings/options?module_filter=bx_persons\" // Exemplo de link
    }
```

```json
    {
      \"status_deeper\": \"active\" // ou \"inactive\"
    }
```

```json
    {
      \"name\": \"bx_persons\",
      \"status_deeper\": \"active\",
      \"message\": \"Module status updated successfully.\"
    }
```

### 2. Obter Detalhes de um Módulo Específico

*   **Endpoint:** `GET /api/v1/admin/modules/{moduleName}`
*   **Propósito:** Retorna informações detalhadas sobre um módulo específico.
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:**
    *   `{moduleName}` (String, Obrigatório): O nome do módulo (ex: `bx_persons`).
*   **Resposta de Sucesso (200 OK):** Similar a um item da lista acima, mas pode incluir:
    *   Lista de principais \"objetos\" UNA associados (páginas, formulários, grades) que foram portados.
    *   Links para as configurações do módulo (se `has_settings` for true).
    *   Dependências (conceituais) de outros módulos Deeper.

### 3. Atualizar Status de um Módulo (Habilitar/Desabilitar Funcionalidade)

Este é o aspecto mais \"conceitual\" do gerenciamento de módulos no Deeper. Se um módulo Deeper pode ser \"desabilitado\", isso geralmente significa que:
*   Seus endpoints de API públicos podem ser desativados ou retornar um erro específico.
*   Seus blocos de página não seriam renderizados.
*   Seus itens de menu seriam ocultados.
Isso seria controlado por uma flag de configuração global para o módulo (em `sys_options` ou uma tabela de status de módulos Deeper).

*   **Endpoint:** `PUT /api/v1/admin/modules/{moduleName}/status`
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:**
    *   `{moduleName}` (String, Obrigatório).
*   **Corpo da Requisição (JSON):**

*   **Lógica do Backend:**
    1.  Verificar se o módulo pode ter seu status alterado (módulos core podem ser não desabilitáveis).
    2.  Atualizar a flag de configuração correspondente (ex: `option_name = \"deeper_module_bx_persons_enabled\"` em `sys_options`).
    3.  Invalidar caches relevantes que dependem do status do módulo (ex: cache de rotas, menus, páginas).
*   **Resposta de Sucesso (200 OK):**

### 4. Acessar Configurações Específicas de um Módulo

Isto não seria um endpoint novo, mas sim uma forma de usar a API de gerenciamento de configurações (`system_settings_admin_api.md`) com um filtro de módulo.

*   **Endpoint Referenciado:** `GET /api/v1/admin/settings/options?module_filter={moduleName}`
    *   Onde `{moduleName}` é o nome do módulo. A UI de admin para módulos pode construir este link.
*   **Lógica do Backend (`OptionsRepo`):** Precisaria de uma maneira de associar `sys_options` a módulos. No UNA, isso é feito implicitamente pelo prefixo do nome da opção (ex: `bx_persons_allow_public_profiles`) ou pela `sys_options_categories.name` que pode incluir o nome do módulo. O `OptionsRepo` precisaria de lógica para filtrar por este prefixo/categoria.

### Considerações:

*   **Módulos Core vs. Opcionais:** O sistema \"Deeper\" precisará definir quais módulos são \"core\" e não podem ser desabilitados, e quais são opcionais.
*   **Dependências entre Módulos:** Se desabilitar um módulo A quebra o módulo B, a API deve impedir a ação ou alertar o administrador. Essa lógica de dependência precisaria ser definida no Deeper.
*   **Interface do Usuário de Admin:** A UI para gerenciamento de módulos pode simplesmente listar os módulos e oferecer um toggle para habilitar/desabilitar (que chama o endpoint `PUT .../status`) e um link para as configurações do módulo (que chama o endpoint de `sys_options` filtrado).
*   **Não há \"Instalação/Desinstalação\" de Código:** É crucial lembrar que esta API não instala ou desinstala código Elixir. Ela gerencia o estado e a configuração das funcionalidades já existentes no backend Deeper. \"Desinstalar\" um módulo significaria marcar suas funcionalidades como permanentemente inativas e talvez limpar seus dados (uma operação muito mais complexa e destrutiva).

Esta API fornece uma camada de abstração para que os administradores possam entender e gerenciar os componentes funcionais da aplicação \"Deeper\" de uma maneira familiar ao conceito de \"módulos\" do UNA.