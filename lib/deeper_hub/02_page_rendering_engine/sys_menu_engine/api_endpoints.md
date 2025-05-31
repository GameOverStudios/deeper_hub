# Documentação Deeper: Endpoints da API para Menus

Este documento especifica os endpoints RESTful para que um cliente possa obter a estrutura e os itens de um menu dinâmico do sistema \"Deeper\".

**Convenções Gerais:**
*   Endpoints sob `/api/v1`.
*   Respostas em JSON.
*   Autenticação JWT para menus que dependem do nível do usuário para visibilidade de itens.

---

## 1. Obter Estrutura do Menu

*   **Endpoint:** `GET /menus/{menu_object_name}`
    *   `menu_object_name`: O nome do objeto de menu de `sys_objects_menu.object` (ex: `bx_persons_main_menu`, `sys_account_notifications`).

*   **Autenticação:** Opcional/Requerida.
    *   Se o menu não tiver itens com restrições `visible_for_levels` complexas ou for um menu público, pode não requerer JWT.
    *   Se os itens do menu são filtrados por ACL, um JWT válido é necessário para determinar o nível do usuário. Se nenhum JWT for fornecido, a API pode assumir o nível de \"Visitante\".

*   **Query Parameters (Opcionais):**
    *   `lang={lang_code}` (ex: `en`, `pt-BR`): Para solicitar títulos traduzidos. Se não fornecido, pode usar o idioma padrão do sistema ou o idioma do usuário (se autenticado).

*   **Descrição:** Retorna a definição do menu e sua lista hierárquica de itens visíveis para o usuário atual.

*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"menu_details\": { // Dados de sys_objects_menu e sys_menu_templates
          \"id\": 5,
          \"object\": \"bx_persons_main_menu\",
          \"title\": \"Menu Principal de Pessoas\", // Traduzido ou chave
          \"set_name\": \"bx_persons_main\",
          \"module\": \"bx_persons\",
          \"template_file\": \"menu_main_horizontal.html\", // Informativo
          \"template_title\": \"Menu Horizontal Principal\"
        },
        \"items\": [ // Lista hierárquica de itens de menu (sys_menu_items)
          {
            \"id\": 10,
            \"name\": \"home\",
            \"title\": \"Início\", // Traduzido ou chave
            \"link\": \"/caminho/para/home\",
            \"icon\": \"home-icon-class\",
            \"target\": \"_self\",
            \"primary\": true, // Se for o item primário/ativo
            \"markers_data\": {\"notifications\": 5}, // Exemplo se 'markers' foi processado
            \"sub_items\": [] // Lista de sub-itens (mesma estrutura)
          },
          {
            \"id\": 11,
            \"name\": \"profiles\",
            \"title\": \"Perfis\",
            \"link\": \"/caminho/para/perfis\",
            \"icon\": \"users-icon-class\",
            \"sub_items\": [
              {
                \"id\": 15,
                \"name\": \"my_profile\",
                \"title\": \"Meu Perfil\",
                \"link\": \"/caminho/para/meu-perfil\",
                \"icon\": \"user-icon-class\"
                // \"submenu_object\": \"bx_profile_actions_menu\" // Se este item abrir outro menu
              }
            ]
          },
          {
            \"id\": 12,
            \"name\": \"settings_link_direct\",
            \"title\": \"Configurações\",
            \"link\": \"\", // Sem link direto, pode ser um dropdown
            \"icon\": \"settings-icon-class\",
            \"submenu_object\": \"bx_persons_settings_submenu\" // Indica que este item carrega outro menu
          }
          // ... mais itens raiz ...
        ]
      }
    }
```