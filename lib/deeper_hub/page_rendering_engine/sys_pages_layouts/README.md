# Documentação Deeper: Layouts de Página (`sys_pages_layouts`)

Esta seção aborda como as informações sobre os Layouts de Página, definidos na tabela `sys_pages_layouts` do UNA, são tratadas pela API \"Deeper\".

## Integração com a API de Objetos de Página:

As informações essenciais sobre o layout de uma página (como `layout_id`, `layout_name`, `layout_template` e `layout_cells_number`) são primariamente retornadas como parte da resposta do endpoint `GET /api/v1/pages/definition` (definido em `docs/02_page_rendering_engine/sys_objects_page/api_endpoints.md`).

Quando o cliente solicita a definição de uma página, ele recebe os detalhes do layout que essa página utiliza. Isso permite ao cliente entender a estrutura de células da página (ex: uma coluna, duas colunas) e onde posicionar os blocos de conteúdo retornados.

## Tabelas Relevantes:

*   **`sys_pages_layouts`**: Contém a definição de cada layout (ID, nome, ícone, título, template HTML, número de células).

## Endpoint Opcional para Listar Layouts:

Embora a informação do layout de uma página específica seja fornecida com a própria página, um endpoint opcional pode ser disponibilizado para listar todos os layouts de página disponíveis. Isso pode ser útil para ferramentas de desenvolvimento ou para um cliente de administração que precise apresentar opções de layout.

*   **Endpoint:** `GET /api/v1/pages/layouts`
    *   **Status:** Público (ou Admin)
    *   **Descrição:** Retorna uma lista de todos os layouts de página definidos em `sys_pages_layouts`.
    *   **Resposta de Sucesso (200 OK):**

```json
        {
          \"data\": [
            {
              \"id\": 1,
              \"name\": \"layout_1_column\",
              \"icon\": \"bx-layout-one-column\",
              \"title\": \"Uma Coluna\",
              \"template\": \"layout_1_column.html\",
              \"cells_number\": 1
            },
            {
              \"id\": 2,
              \"name\": \"layout_2_columns\",
              \"icon\": \"bx-layout-two-columns\",
              \"title\": \"Duas Colunas\",
              \"template\": \"layout_2_columns.html\",
              \"cells_number\": 2
            }
            // ... outros layouts
          ]
        }
```

    *   **Lógica do Backend:** Chamaria uma função como `PagesRepo.list_page_layouts/0`.

## Migrações e Módulo de Acesso a Dados:

*   A migração para criar a tabela `sys_pages_layouts` já foi definida em:
    `docs/02_page_rendering_engine/sys_objects_page/migrations/create_sys_pages_layouts_table.elixir.md`.
*   As funções para interagir com `sys_pages_layouts` (como `list_page_layouts/0`) foram incluídas no `PagesRepo` em:
    `docs/02_page_rendering_engine/sys_objects_page/data_access_module.md`.

Para a maioria dos casos de uso do cliente final, a informação de layout obtida através da definição da página será suficiente. O endpoint de listagem de layouts é mais um utilitário.