# API de Administração: Gerenciamento de Templates de Email (`sys_email_templates`)

Esta seção da API de Administração \"Deeper\" fornece endpoints para que administradores gerenciem os templates de email utilizados pelo sistema para diversas comunicações (ex: email de boas-vindas, notificação de nova mensagem, reset de senha). Isso se baseia na tabela `sys_email_templates` do UNA.

**Autenticação:** Requerida (nível de administrador do sistema ou permissões específicas de gerenciamento de templates).

## Objetivos da API de Gerenciamento de Templates de Email:

*   Listar todos os templates de email disponíveis, agrupados por módulo.
*   Permitir a visualização e edição do assunto e corpo (HTML e/ou texto) de cada template.
*   (Opcional) Enviar um email de teste usando um template específico.

## Considerações sobre `sys_email_templates` no \"Deeper\":

*   **Estrutura do UNA:** `sys_email_templates` armazena `Module` (a qual módulo o template pertence), `NameSystem` (identificador único interno), `Name` (nome amigável), `Subject` (assunto do email, pode conter placeholders), e `Body` (corpo do email, geralmente HTML, também com placeholders).
*   **Placeholders:** Os templates usam placeholders (ex: `{member_name}`, `{site_url}`) que são substituídos por valores reais quando o email é enviado. A API de admin deve informar sobre os placeholders disponíveis para cada template, se possível.
*   **Internacionalização:** No UNA, o assunto e corpo podem ser chaves de tradução (`_L[chave]`). A API de admin pode permitir a edição direta do texto ou a edição da chave de tradução (se o sistema de tradução for acessível para edição via API). Para \"Deeper\", o mais simples é permitir a edição do texto final, que pode incluir chaves de tradução que o sistema de envio de email do Elixir resolveria.
*   **Envio de Email no Elixir:** O backend \"Deeper\" usará uma biblioteca Elixir para envio de emails (ex: Swoosh, Bamboo). Essa biblioteca será responsável por processar os templates (com seus placeholders) e enviar os emails. Esta API de admin *gerencia os templates*, não envia emails de produção diretamente (exceto talvez para testes).

## 1. Endpoints para Templates de Email (`/api/v1/admin/email-templates`)

### `GET /api/v1/admin/email-templates`
*   **Descrição:** Lista todos os templates de email do sistema, opcionalmente filtrados.
*   **Query Parameters:**
    *   `module_name` (string): Filtra templates por módulo do UNA (ex: `\"system\"`, `\"bx_persons\"`).
    *   `search_term` (string): Busca no `NameSystem`, `Name`, `Subject`.
    *   `lang_code` (string, ex: `\"en\"`, `\"pt_BR\"`): Para obter o assunto e corpo na língua especificada, se os templates forem internacionalizados via chaves de tradução no banco. (Se o corpo armazenado já é o texto final, este parâmetro pode ser menos relevante para a *listagem*).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1, // sys_email_templates.ID
          \"module_name\": \"system\", // sys_email_templates.Module
          \"system_name\": \"t_ForgotPassword\", // sys_email_templates.NameSystem
          \"display_name\": \"Forgot Password Notification\", // sys_email_templates.Name
          \"subject_template\": \"Password Reset Request for {site_name}\", // sys_email_templates.Subject
          \"last_modified\": \"2023-10-27T14:30:00Z\" // Opcional, se rastreado
        }
        // ... mais templates
      ],
      \"pagination\": { ... } // Se houver muitos templates
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"module_name\": \"system\",
        \"system_name\": \"t_ForgotPassword\",
        \"display_name\": \"Forgot Password Notification\",
        \"subject_template\": \"Password Reset Request for {site_name}\",
        \"body_template_html\": \"<p>Hello {member_name},</p><p>You requested a password reset...</p>\", // sys_email_templates.Body
        // \"body_template_text\": \"Hello {member_name},\\nYou requested...\", // Opcional, se houver versão texto
        \"available_placeholders\": [ // Opcional, lista informativa de placeholders comuns para este template
          \"{member_name}\", \"{member_email}\", \"{reset_link}\", \"{site_name}\", \"{site_url}\"
        ],
        \"last_modified\": \"2023-10-27T14:30:00Z\"
      }
    }
```

```json
    {
      \"subject_template\": \"Your Password Reset Link from {site_name}\",
      \"body_template_html\": \"<p>Hi {member_name},</p><p>Here is your link to reset your password: {reset_link}</p><p>Thanks,<br/>The {site_name} Team</p>\"
      // \"body_template_text\": \"...\" // Opcional
    }
```

```json
    {
      \"recipient_email\": \"admin_test@example.com\",
      \"placeholders_data\": { // Valores de exemplo para os placeholders
        \"member_name\": \"Test Admin\",
        \"member_email\": \"admin_test@example.com\",
        \"reset_link\": \"https://deeepr.example.com/auth/reset/test-token-123\",
        \"site_name\": \"Deeper Test Site\",
        \"site_url\": \"https://deeepr.example.com\"
      }
    }
```

```json
    {
      \"message\": \"Test email sent successfully to admin_test@example.com.\"
    }
```

### `GET /api/v1/admin/email-templates/{template_id_or_system_name}`
*   **Descrição:** Obtém os detalhes de um template de email específico, incluindo seu corpo.
*   **`{template_id_or_system_name}`:** Pode ser o `ID` numérico ou o `NameSystem` do template.
*   **Query Parameters:**
    *   `lang_code` (string): Para obter o corpo e assunto na língua especificada, se aplicável.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `404 Not Found`.

### `PUT /api/v1/admin/email-templates/{template_id_or_system_name}`
*   **Descrição:** Atualiza o assunto e/ou corpo de um template de email.
*   **Corpo da Requisição (JSON):**

*   **Lógica do Backend:**
    1.  Atualiza os campos `Subject` e `Body` na tabela `sys_email_templates`.
    2.  (Opcional) Se os templates são cacheados pela aplicação Elixir, invalida/recarrega o cache do template modificado.
*   **Resposta de Sucesso (200 OK):** Detalhes do template atualizado.
*   **Respostas de Erro:** `400 Bad Request`, `404 Not Found`, `422 Unprocessable Entity` (ex: HTML malformado, se houver validação).

### `POST /api/v1/admin/email-templates/{template_id_or_system_name}/send-test`
*   **Descrição:** Envia um email de teste usando o template especificado para um endereço de email fornecido.
*   **Corpo da Requisição (JSON):**

*   **Lógica do Backend:**
    1.  Busca o template do banco.
    2.  Renderiza o template substituindo os placeholders com os `placeholders_data` fornecidos (e valores padrão para placeholders não fornecidos).
    3.  Usa o sistema de envio de email do Elixir para enviar o email para `recipient_email`.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `400` (email inválido, dados de placeholder faltando), `404` (template não encontrado), `500 Internal Server Error` (falha no envio do email).

## Considerações para API de Admin de Templates de Email:

*   **Editor WYSIWYG:** A interface de administração que consome esta API provavelmente usará um editor WYSIWYG para o `body_template_html`. A API apenas recebe e armazena o HTML.
*   **Segurança do Conteúdo HTML:** Embora os administradores estejam editando, o HTML armazenado deve ser sanitizado se houver qualquer chance de ser renderizado em contextos inseguros, ou se a fonte do template não for 100% confiável. Para emails, a maioria dos clientes de email já faz sua própria sanitização.
*   **Placeholders Dinâmicos:** A lista `available_placeholders` na resposta `GET` de um template é informativa. A lógica real de substituição de placeholders ocorrerá no backend Elixir quando um email de produção for enviado, usando os dados contextuais daquela situação específica.
*   **Criação/Deleção de Templates:** No UNA, templates são geralmente adicionados/removidos por módulos. Uma API para administradores criarem novos `NameSystem` de templates é menos comum, mas poderia ser adicionada se necessário, com validações cuidadosas para evitar conflitos. A deleção também é arriscada se o template estiver em uso pelo sistema.

Esta API permitirá que os administradores personalizem a comunicação por email da plataforma \"Deeper\", mantendo a consistência da marca e fornecendo informações relevantes aos usuários.