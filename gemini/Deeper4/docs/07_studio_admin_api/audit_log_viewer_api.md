# API de Administração: Visualizador de Log de Auditoria (`sys_audit`)

Esta seção da API de Administração \"Deeper\" fornece endpoints para que administradores pesquisem e visualizem as entradas do log de auditoria do sistema. O log de auditoria registra ações significativas realizadas por usuários ou pelo próprio sistema, com base na tabela `sys_audit` do UNA.

**Autenticação:** Requerida (nível de superadministrador ou permissões específicas para visualizar logs de auditoria).

## Objetivos da API do Visualizador de Log de Auditoria:

*   Permitir a listagem e filtragem de entradas do log de auditoria.
*   Fornecer detalhes de cada entrada de auditoria, incluindo quem realizou a ação, qual ação foi realizada, em qual conteúdo/contexto, e quando.

## Considerações sobre `sys_audit` no \"Deeper\":

*   **Estrutura do UNA:** A tabela `sys_audit` no UNA contém colunas como:
    *   `id`, `added` (timestamp)
    *   `profile_id` (quem realizou a ação)
    *   `profile_title` (nome do perfil que realizou a ação, para referência rápida)
    *   `content_id`, `content_title`, `content_module`, `content_info_object` (detalhes do item afetado pela ação)
    *   `context_profile_id`, `context_profile_title` (se a ação ocorreu no contexto de outro perfil)
    *   `action_lang_key` (chave de tradução para descrever a ação)
    *   `action_lang_key_params` (parâmetros JSON para a chave de tradução da ação)
    *   `extras` (dados JSON adicionais sobre a ação, como valores antigos/novos)
*   **Registro de Auditoria no \"Deeper\":** A lógica para registrar entradas em `sys_audit` no backend Elixir \"Deeper\" precisará ser implementada em pontos apropriados da aplicação (ex: após um administrador alterar uma configuração, após um usuário criar um post importante, etc.).
*   **Interpretação de `action_lang_key`:** A API pode retornar a `action_lang_key` e seus `action_lang_key_params`. O cliente da API (a interface de admin) seria responsável por usar o sistema de internacionalização para renderizar a descrição da ação de forma amigável.

## 1. Endpoints para Logs de Auditoria (`/api/v1/admin/audit-logs`)

### `GET /api/v1/admin/audit-logs`
*   **Descrição:** Lista as entradas do log de auditoria com filtros, ordenação e paginação.
*   **Query Parameters:**
    *   `profile_id` (integer): Filtra por ID do perfil que realizou a ação.
    *   `action_filter` (string): Busca na `action_lang_key` ou em uma descrição textual da ação (se a API pré-processar).
    *   `content_module` (string): Filtra por módulo do conteúdo afetado (ex: `\"bx_persons\"`, `\"sys_options\"`).
    *   `content_id` (integer): Filtra por ID do conteúdo específico afetado.
    *   `start_date` (ISO 8601 string ou Unix timestamp, para `added`).
    *   `end_date` (ISO 8601 string ou Unix timestamp, para `added`).
    *   `ip_address` (string, se o IP for registrado em `extras`).
    *   `page` (integer, default 1).
    *   `per_page` (integer, default 50).
    *   `sort_by` (string, ex: `\"added_desc\"` - padrão, `\"added_asc\"`).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 12345, // sys_audit.id
          \"timestamp\": \"2023-10-28T15:00:10Z\", // sys_audit.added (convertido para ISO 8601)
          \"actor_profile_id\": 1, // sys_audit.profile_id
          \"actor_profile_title\": \"admin_user\", // sys_audit.profile_title
          \"action_key\": \"_sys_audit_auth_login\", // sys_audit.action_lang_key
          \"action_description\": \"User logged in\", // Opcional: API pode pré-renderizar a descrição
          \"action_params_json\": \"{\\\"ip\\\": \\\"192.168.1.100\\\"}\", // sys_audit.action_lang_key_params
          \"target_content\": { // sys_audit.content_*
            \"module\": null,
            \"info_object\": null,
            \"id\": null,
            \"title\": null
          },
          \"context_profile\": { // sys_audit.context_profile_*
            \"id\": null,
            \"title\": null
          },
          \"extras_json\": \"{\\\"user_agent\\\": \\\"Chrome/100...\\\"}\" // sys_audit.extras
        },
        {
          \"id\": 12346,
          \"timestamp\": \"2023-10-28T14:55:00Z\",
          \"actor_profile_id\": 1,
          \"actor_profile_title\": \"admin_user\",
          \"action_key\": \"_adm_admtools_set_option\",
          \"action_description\": \"System option 'site_title' was changed from 'Old Title' to 'New Title'\", // Exemplo de descrição rica
          \"action_params_json\": \"{\\\"option_name\\\": \\\"site_title\\\"}\",
          \"target_content\": {
            \"module\": \"system\",
            \"info_object\": \"sys_options\",
            \"id\": null, // ID da opção pode estar no extras
            \"title\": \"site_title\"
          },
          \"extras_json\": \"{\\\"old_value\\\": \\\"Old Title\\\", \\\"new_value\\\": \\\"New Title\\\"}\"
        }
        // ... mais entradas de auditoria
      ],
      \"pagination\": {
        \"total_items\": 570,
        \"total_pages\": 12,
        \"current_page\": 1,
        \"per_page\": 50
      }
    }
```

```json
    {
      \"data\": {
        \"id\": 12346,
        \"timestamp\": \"2023-10-28T14:55:00Z\",
        \"actor_profile_id\": 1,
        \"actor_profile_title\": \"admin_user\",
        \"action_key\": \"_adm_admtools_set_option\",
        \"action_description\": \"System option 'site_title' was changed from 'Old Title' to 'New Title'\",
        \"action_params\": { // JSON parseado
          \"option_name\": \"site_title\"
        },
        \"target_content\": {
          \"module\": \"system\",
          \"info_object\": \"sys_options\",
          \"id\": null,
          \"title\": \"site_title\"
        },
        \"context_profile\": null,
        \"extras\": { // JSON parseado
          \"old_value\": \"Old Title\",
          \"new_value\": \"New Title\"
        }
      }
    }
```

### `GET /api/v1/admin/audit-logs/{log_id}`
*   **Descrição:** Obtém detalhes completos de uma entrada específica do log de auditoria.
*   **Resposta de Sucesso (200 OK):** Um único objeto similar ao da lista acima, mas potencialmente com mais detalhes ou formatação nos campos JSON (`action_params_json`, `extras_json` podem ser retornados como objetos JSON parseados).

*   **Respostas de Erro:** `404 Not Found`.

## Considerações para API de Visualização de Log de Auditoria:

*   **Performance:** A tabela `sys_audit` pode crescer bastante. As queries de listagem devem ser otimizadas com índices adequados nas colunas usadas para filtro e ordenação (especialmente `added`, `profile_id`, `content_module`, `content_id`).
*   **Não Modificação:** Esta API é estritamente para visualização. Logs de auditoria, uma vez escritos, não devem ser modificados ou deletados via API para manter sua integridade. A remoção de logs antigos (pruning) deve ser um processo de backend separado e controlado, se necessário.
*   **Formatação da Ação:** A coluna `action_description` na resposta é opcional e um \"nice-to-have\". Se a API a fornecer, ela precisaria ter acesso à lógica de internacionalização para resolver as `action_lang_key` com os `action_lang_key_params`. Caso contrário, o cliente da API faria essa resolução.
*   **Sensibilidade dos Dados:** `extras_json` pode conter dados sensíveis (ex: valores antigos/novos de campos). O acesso a esta API deve ser altamente restrito.

Esta API permitirá que administradores rastreiem atividades importantes na plataforma \"Deeper\", auxiliando na segurança, depuração e conformidade.