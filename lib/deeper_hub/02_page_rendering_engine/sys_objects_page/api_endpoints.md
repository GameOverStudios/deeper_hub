# Documentação Deeper: Endpoints da API para Páginas, Blocos e Layouts

Este documento especifica os endpoints RESTful para que um cliente possa obter a estrutura completa e o conteúdo de uma página dinâmica do sistema \"Deeper\", baseada nas definições do UNA.

**Convenções Gerais:**
*   Todos os endpoints estão sob o prefixo `/api/v1`.
*   Respostas e corpos de requisição são em JSON.
*   A autenticação é feita via JWT no header `Authorization: Bearer <token>` (para páginas/blocos que requerem login).
*   Códigos de status HTTP e formatos de erro seguem as [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md).

---

## 1. Obter Estrutura da Página

*   **Endpoint:** `GET /pages/{page_object_name_or_uri}`
    *   `page_object_name_or_uri`: Pode ser o `sys_objects_page.object` (ex: `bx_persons_home`) ou um `sys_objects_page.uri` (ex: `persons-home`, se os URIs forem usados diretamente como identificadores na API após uma possível resolução interna de permalink). Para simplicidade inicial, vamos focar em usar `sys_objects_page.object` como o identificador principal no path.
    *   Alternativamente, um query parameter: `GET /pages?object={page_object_name}` ou `GET /pages?uri_alias={page_uri_alias}`. Usar um path parameter é mais RESTful para identificar um recurso específico.

*   **Endpoint (Alternativa com Query Param):** `GET /pages?object={page_object_name}`
    *   Este pode ser mais flexível se a resolução do que constitui uma \"página\" for complexa (ex: permalinks que não mapeiam diretamente para um `sys_objects_page.object`).

*   **Autenticação:** Opcional.
    *   Se a página for pública (`visible_for_levels` permite visitantes), não requer JWT.
    *   Se a página requer login, um JWT válido é necessário. A lógica de ACL da página e dos blocos será aplicada.

*   **Descrição:** Retorna a definição completa de uma página, incluindo seus metadados, informações de layout, e uma lista de blocos de conteúdo com seus dados processados (ou definições de serviço).

*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"page\": { // Dados de sys_objects_page, sys_pages_types, sys_pages_layouts
          \"object\": \"bx_persons_home\",
          \"uri\": \"persons-home\",
          \"title\": \"Página Inicial de Pessoas\", // Já traduzido ou chave de tradução
          \"module\": \"bx_persons\",
          \"cover_enabled\": true,
          \"cover_image_url\": \"/path/to/cover.jpg\", // Se aplicável
          \"cover_title\": \"Bem-vindo!\",
          \"page_type\": {
            \"id\": 1,
            \"title\": \"Padrão\",
            \"template\": \"default_page_template.html\" // Informativo para o cliente
          },
          \"layout\": { // Dados de sys_pages_layouts
            \"id\": 2,
            \"name\": \"col_1_2\", // Ex: Layout de 3 colunas, principal à esquerda
            \"title\": \"Layout Esquerda Larga\",
            \"template\": \"layout_1_wide_2_narrow.html\", // Informativo
            \"cells_number\": 3
          },
          \"submenu_object\": \"bx_persons_submenu_home\", // Nome do menu a ser buscado separadamente
          \"meta_title\": \"Meta Título da Página\",
          \"meta_description\": \"Descrição para SEO.\",
          \"meta_keywords\": \"palavras, chave, seo\",
          \"meta_robots\": \"index, follow\",
          \"cache_lifetime\": 3600 // Em segundos
          // ... outros campos relevantes de sys_objects_page ...
        },
        \"cells\": { // Blocos agrupados por cell_id (da sys_pages_layouts.cells_number)
          \"1\": [ // Blocos para a célula 1
            {
              \"id\": 101, // sys_pages_blocks.id
              \"title\": \"Últimos Perfis\", // Já traduzido ou chave
              \"design_box\": {
                \"id\": 11,
                \"title\": \"Caixa Padrão com Título\",
                \"template\": \"designbox_title.html\" // Informativo
              },
              \"type\": \"service\", // sys_pages_blocks.type
              \"visible\": true, // Resultado da verificação ACL para este bloco
              \"processed_content\": { // Conteúdo processado/definido pelo PageRepo
                \"type\": \"service_data\", // Indica que são dados de um serviço
                \"service_name\": \"latest_profiles\", // Nome lógico do serviço
                \"data\": [ // Dados JSON que o serviço PHP original produziria
                  {\"id\": 1, \"fullname\": \"Usuário A\", \"avatar_url\": \"...\"},
                  {\"id\": 2, \"fullname\": \"Usuário B\", \"avatar_url\": \"...\"}
                ]
              },
              \"cache_lifetime\": 600
              // ... outros campos de sys_pages_blocks ...
            },
            // ... mais blocos na célula 1 ...
          ],
          \"2\": [
            {
              \"id\": 102,
              \"title\": \"Menu de Navegação Pessoal\",
              \"design_box\": { \"id\": 1, \"title\": \"Sem Caixa\", \"template\": \"designbox_raw.html\"},
              \"type\": \"menu\",
              \"visible\": true,
              \"processed_content\": {
                \"type\": \"menu_object\",
                \"object_name\": \"bx_persons_member_menu\" // Cliente busca este menu via API de menus
              }
            },
            {
              \"id\": 103,
              \"title\": \"Boas Vindas\",
              \"design_box\": { \"id\": 11, \"title\": \"Caixa Padrão com Título\"},
              \"type\": \"html\",
              \"visible\": true,
              \"processed_content\": {
                \"type\": \"html_content\",
                \"html\": \"<p>Bem-vindo ao nosso site!</p>\"
              }
            }
          ],
          \"3\": [] // Célula 3 vazia
        }
      }
    }
```