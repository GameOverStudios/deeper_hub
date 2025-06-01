# Documentação Deeper: Endpoints da API para o Motor de Formulários

Este documento especifica os endpoints RESTful para que um cliente possa obter as definições de formulários dinâmicos do sistema \"Deeper\". A submissão de formulários ocorrerá nos endpoints dos recursos específicos (ex: `POST /articles` para criar um artigo).

**Convenções Gerais:**
*   Endpoints sob `/api/v1`.
*   Respostas em JSON.
*   Autenticação JWT pode ser necessária para obter definições de formulários que têm campos com visibilidade restrita por ACL.
*   Códigos de status HTTP e formatos de erro seguem as [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md).

---

## 1. Obter Definição de Formulário

*   **Endpoint:** `GET /forms/{form_object_name}/displays/{display_name}`
    *   `form_object_name`: O nome do objeto de formulário de `sys_objects_form.object` (ex: `bx_persons_add`, `deeper_articles_edit`).
    *   `display_name`: O nome do display específico de `sys_form_displays.display_name` para este objeto de formulário (ex: `bx_persons_create_profile`, `deeper_articles_form_edit_entry`). Frequentemente, o `display_name` pode ser o mesmo que o `form_object_name` para formulários simples, ou pode haver displays específicos como `..._add`, `..._edit`, `..._view`.

*   **Autenticação:** Opcional/Requerida.
    *   Se o formulário ou seus campos tiverem restrições `visible_for_levels`, um JWT válido é necessário para determinar o nível do usuário e filtrar os campos corretamente.
    *   Se nenhum JWT for fornecido, a API pode assumir o nível de \"Visitante\" para a filtragem de campos.

*   **Query Parameters (Opcionais):**
    *   `lang={lang_code}` (ex: `en`, `pt-BR`): Para solicitar legendas, dicas e opções de select traduzidas. Se não fornecido, pode usar o idioma padrão do sistema ou o idioma do usuário (se autenticado).
    *   `context_id={integer}` (ex: `article_id` para um formulário de edição de artigo): Para pré-preencher o formulário com dados existentes de um registro. (Esta funcionalidade de \"carregar dados\" pode ser complexa e, alternativamente, o cliente busca os dados do recurso separadamente e preenche o formulário).

*   **Descrição:** Retorna a definição completa de um display de formulário, incluindo atributos do formulário e uma lista de seus campos com todas as propriedades (tipo, legenda, validações, opções de select, etc.).

*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"form_object_name\": \"deeper_articles_edit\",
        \"display_name\": \"deeper_articles_form_edit_entry\",
        \"title\": \"Editar Artigo\", // Título do display (traduzido ou chave)
        \"form_attributes\": { // Parseado de sys_objects_form.form_attrs
          \"method\": \"PUT\", // Ou POST, dependendo da ação
          \"enctype\": \"multipart/form-data\" // Se houver campos de arquivo
        },
        // O 'action_target' no UNA PHP é uma URL. Para Deeper, o cliente saberá
        // qual endpoint da API Deeper chamar baseado no contexto (ex: PUT /articles/{id}).
        // A API de formulários pode fornecer uma sugestão ou o nome da rota Deeper.
        \"submit_target_api_endpoint_pattern\": \"/articles/{id}\", // Sugestão
        \"submit_button_label\": \"Salvar Alterações\", // Traduzido ou chave (de sys_objects_form.submit_name)
        \"fields\": [
          {
            \"name\": \"title\",
            \"type\": \"text\", // Mapeado de sys_form_inputs.type
            \"caption\": \"Título do Artigo\", // Traduzido ou chave
            \"info\": \"O título principal que será exibido.\",
            \"value\": \"Título Existente do Artigo\", // Pré-preenchido se context_id foi usado
            \"is_required\": true,
            \"is_unique\": false, // (se aplicável, do sys_form_inputs.unique_input)
            \"attrs\": {\"maxlength\": \"255\"}, // Parseado de sys_form_inputs.attrs
            \"validation\": { // Derivado de checker_func, checker_params
              \"type\": \"length\", // Exemplo
              \"params\": {\"min\": 5, \"max\": 255},
              \"error_message\": \"O título deve ter entre 5 e 255 caracteres.\" // Traduzido ou chave
            }
          },
          {
            \"name\": \"category_id\",
            \"type\": \"select\",
            \"caption\": \"Categoria\",
            \"value\": 12, // ID da categoria selecionada
            \"options\": [ // De sys_form_pre_values ou values_list
              {\"value\": \"10\", \"label\": \"Tecnologia\"},
              {\"value\": \"12\", \"label\": \"Elixir\"},
              {\"value\": \"15\", \"label\": \"Notícias Gerais\"}
            ],
            \"is_required\": false
          },
          {
            \"name\": \"body\",
            \"type\": \"textarea\", // Pode ser 'custom' com um editor WYSIWYG
            \"caption\": \"Conteúdo\",
            \"value\": \"<p>Conteúdo existente do artigo...</p>\",
            \"attrs\": {\"rows\": \"10\"},
            \"is_required\": true
          },
          {
            \"name\": \"status\",
            \"type\": \"radio\", // ou select
            \"caption\": \"Status\",
            \"value\": \"published\",
            \"options\": [
              {\"value\": \"draft\", \"label\": \"Rascunho\"},
              {\"value\": \"published\", \"label\": \"Publicado\"}
            ]
          },
          {
            \"name\": \"cover_image\",
            \"type\": \"file\",
            \"caption\": \"Imagem de Capa\",
            \"info\": \"Faça upload de uma imagem JPG ou PNG.\",
            \"attrs\": {\"accept\": \"image/jpeg, image/png\"}
            // O valor aqui pode ser uma URL da imagem existente ou ID do arquivo.
            // O cliente lidará com o upload para um endpoint de arquivos separado.
          }
          // ... mais campos ...
        ]
      }
    }
```