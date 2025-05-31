# API de Administração: Gerenciamento de SEO

Esta seção da API de Administração \"Deeper\" fornece endpoints para que administradores gerenciem configurações e dados relacionados à Otimização para Mecanismos de Busca (SEO) da plataforma. Isso se baseia principalmente nas tabelas `sys_permalinks`, `sys_rewrite_rules`, e `sys_seo_uri_rewrites` do UNA.

**Autenticação:** Requerida (nível de administrador do sistema ou permissões específicas de gerenciamento de SEO).

## Objetivos da API de Gerenciamento de SEO:

*   Listar e gerenciar Permalinks (`sys_permalinks`) - como URLs padrão são transformadas em URLs amigáveis.
*   Listar e gerenciar Regras de Reescrita (`sys_rewrite_rules`) - regras de baixo nível para reescrever URLs no servidor (se aplicável ao contexto Elixir/Phoenix).
*   Listar e gerenciar Redirecionamentos de URI (`sys_seo_uri_rewrites`) - para redirecionar URLs antigas ou alternativas para as canônicas.
*   (Opcional) Gerenciar metadados SEO globais ou padrões (ex: para a homepage, se não cobertos por `sys_options`).

## 1. Permalinks (`/api/v1/admin/seo/permalinks`)

No UNA, `sys_permalinks` define como os parâmetros de query padrão (ex: `page.php?i=about-us`) são convertidos em URLs amigáveis (ex: `/about-us`). No contexto \"Deeper\", isso se traduz em como as rotas da API ou da aplicação frontend são mapeadas a partir de identificadores internos ou como o sistema de roteamento do Phoenix é configurado.

**Consideração para \"Deeper\":** O sistema de permalinks do UNA é muito ligado à sua estrutura PHP. No \"Deeper\", o roteamento será primariamente gerenciado pelo Phoenix Router. Esta API pode servir para:
    a. Visualizar as configurações de permalinks originais do UNA como referência.
    b. Gerenciar um sistema de \"slugs\" ou aliases para rotas canônicas da API/frontend, se necessário, para além do que o Phoenix Router oferece nativamente.

### `GET /api/v1/admin/seo/permalinks`
*   **Descrição:** Lista as configurações de permalinks existentes (lendo de `sys_permalinks`).
*   **Query Parameters:** `search_term` (busca em `standard` ou `permalink`), `page`, `per_page`.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1, // sys_permalinks.id
          \"standard_pattern\": \"page.php?i={uri}\", // sys_permalinks.standard
          \"permalink_pattern\": \"{uri}\", // sys_permalinks.permalink
          \"check_function\": \"BxDolPermalinks::checkForPage\", // sys_permalinks.check (informativo)
          \"compare_by_prefix\": false // Mapeado de sys_permalinks.compare_by_prefix
        }
        // ... mais permalinks
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1, // sys_rewrite_rules.id
          \"regex_pattern\": \"^(.*)\\\\.html\\\\#?(.*)$\", // sys_rewrite_rules.preg
          \"service_call_php\": \"$1.php#$2\", // sys_rewrite_rules.service (string PHP, informativa)
          \"active\": true
        }
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"original_uri\": \"/old-page-path.html\", // sys_seo_uri_rewrites.uri_orig (deve ser único)
      \"rewrite_uri\": \"/new-page-path\", // sys_seo_uri_rewrites.uri_rewrite
      \"redirect_type\": 301 // Opcional, default 301 (Pode ser 301 ou 302)
    }
```

```json
    {
      \"data\": {
        \"id\": 10, // sys_seo_uri_rewrites.id
        \"original_uri\": \"/old-page-path.html\",
        \"rewrite_uri\": \"/new-page-path\",
        \"redirect_type\": 301
      }
    }
```

```json
    {
      \"data\": {
        \"homepage_meta_title\": \"Welcome to Deeper - The Awesome Platform\",
        \"homepage_meta_description\": \"Discover amazing content and connect.\",
        \"default_meta_robots\": \"index,follow\",
        \"site_verification_google\": \"google-site-verification-code\",
        \"site_verification_bing\": \"bing-site-verification-code\"
        // Estes poderiam ser sys_options, mas agrupados aqui para conveniência de SEO.
      }
    }
```

*(CRUD para permalinks via API é menos provável no \"Deeper\", pois o roteamento é mais estaticamente definido no Phoenix. Se houver necessidade de um sistema de slugs dinâmicos gerenciados por admin, endpoints POST/PUT/DELETE seriam adicionados aqui).*

## 2. Regras de Reescrita (`/api/v1/admin/seo/rewrite-rules`)

No UNA, `sys_rewrite_rules` são regras (geralmente expressões regulares) usadas pelo servidor web (ex: Apache `.htaccess`) para reescrever URLs.

**Consideração para \"Deeper\":** A reescrita de URL de baixo nível é geralmente tratada na configuração do servidor web (Nginx, Apache) na frente da aplicação Elixir, ou pelo Phoenix Router para normalização de caminhos. Esta API serviria mais para visualizar as regras antigas ou para gerenciar um conjunto de regras que a aplicação Elixir *poderia* aplicar internamente antes do roteamento Phoenix, se tal camada customizada for necessária.

### `GET /api/v1/admin/seo/rewrite-rules`
*   **Descrição:** Lista as regras de reescrita existentes (lendo de `sys_rewrite_rules`).
*   **Query Parameters:** `search_term` (busca em `preg` ou `service`), `active` (boolean), `page`, `per_page`.
*   **Resposta de Sucesso (200 OK):**

*(CRUD para regras de reescrita via API é altamente improvável no \"Deeper\", pois isso afeta diretamente o roteamento de baixo nível).*

## 3. Redirecionamentos de URI (`/api/v1/admin/seo/uri-rewrites`)

Interage com `sys_seo_uri_rewrites`. Esta é a funcionalidade mais relevante para uma API de admin, permitindo gerenciar redirecionamentos 301/302.

### `POST /api/v1/admin/seo/uri-rewrites`
*   **Descrição:** Cria uma nova regra de redirecionamento de URI.
*   **Corpo da Requisição (JSON):**

*   **Lógica do Backend:**
    *   Insere na tabela `sys_seo_uri_rewrites`.
    *   O sistema de roteamento \"Deeper\" (ou um plug/middleware Phoenix) precisará consultar esta tabela para aplicar redirecionamentos antes de processar as rotas normais.
*   **Resposta de Sucesso (201 Created):** Detalhes do redirecionamento criado.

*   **Respostas de Erro:** `400`, `422` (ex: `original_uri` já existe).

### `GET /api/v1/admin/seo/uri-rewrites`
*   **Descrição:** Lista todas as regras de redirecionamento de URI.
*   **Query Parameters:** `search_term` (busca em `original_uri` ou `rewrite_uri`), `page`, `per_page`.
*   **Resposta de Sucesso (200 OK):** Lista de redirecionamentos.

### `GET /api/v1/admin/seo/uri-rewrites/{rewrite_id}`
*   **Descrição:** Obtém detalhes de uma regra de redirecionamento específica.
*   **Resposta de Sucesso (200 OK):** Detalhes do redirecionamento.
*   **Respostas de Erro:** `404 Not Found`.

### `PUT /api/v1/admin/seo/uri-rewrites/{rewrite_id}`
*   **Descrição:** Atualiza uma regra de redirecionamento existente.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados (`original_uri`, `rewrite_uri`, `redirect_type`).
*   **Resposta de Sucesso (200 OK):** Detalhes do redirecionamento atualizado.
*   **Respostas de Erro:** `400`, `404`, `422`.

### `DELETE /api/v1/admin/seo/uri-rewrites/{rewrite_id}`
*   **Descrição:** Deleta uma regra de redirecionamento.
*   **Resposta de Sucesso (204 No Content).**
*   **Respostas de Erro:** `404`.

## 4. (Opcional) Metadados SEO Globais (`/api/v1/admin/seo/global-meta`)

Se houver necessidade de gerenciar metadados SEO que não se encaixam em `sys_options` ou em páginas específicas (ex: para a homepage raiz, ou padrões para tipos de conteúdo).

### `GET /api/v1/admin/seo/global-meta`
*   **Descrição:** Obtém os metadados SEO globais/padrão.
*   **Resposta de Sucesso (200 OK):**

### `PUT /api/v1/admin/seo/global-meta`
*   **Descrição:** Atualiza os metadados SEO globais/padrão.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.
*   **Lógica do Backend:** Atualiza as `sys_options` correspondentes.
*   **Resposta de Sucesso (200 OK):** Metadados atualizados.

## Considerações para API de Admin de SEO:

*   **Integração com Roteamento Elixir:** A parte mais crítica é como as `sys_seo_uri_rewrites` são integradas ao pipeline de roteamento do Phoenix para que os redirecionamentos ocorram efetivamente. Isso pode ser feito com um Plug customizado.
*   **Validação de URIs:** Garantir que as URIs fornecidas sejam válidas e não criem loops de redirecionamento.
*   **Cache:** Se os redirecionamentos forem cacheados, o cache deve ser invalidado após alterações.

Esta API fornecerá aos administradores as ferramentas básicas para gerenciar aspectos importantes de SEO e redirecionamento para a plataforma \"Deeper\".