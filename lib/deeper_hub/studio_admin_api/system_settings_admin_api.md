# API de Administração: Gerenciamento de Configurações do Sistema (`sys_options`)

Esta seção da API de Administração \"Deeper\" fornece endpoints para que administradores gerenciem as configurações globais e de módulos do sistema, que são primariamente armazenadas na tabela `sys_options` (e suas tabelas relacionadas como `sys_options_categories`, `sys_options_types` no UNA).

**Autenticação:** Requerida (nível de superadministrador ou permissões específicas para gerenciar configurações).

## Objetivos da API de Configurações do Sistema:

*   Listar todas as categorias de opções e as opções dentro delas.
*   Permitir a visualização do valor atual de uma opção específica.
*   Permitir a modificação do valor de uma opção.
*   (Opcional, menos comum via API) Gerenciar a estrutura das próprias opções (adicionar/remover opções, categorias - geralmente feito por desenvolvedores ou migrações de módulo no UNA). Para \"Deeper\", o foco inicial será ler e atualizar valores de opções existentes.

## Considerações sobre `sys_options` no \"Deeper\":

*   **Estrutura do UNA:** No UNA, `sys_options` é uma tabela chave-valor com metadados adicionais como `category_id`, `type` (digit, text, checkbox, select, etc.), `extra` (para valores de select/list), `check` (validação).
*   **Cache de Configurações:** O backend Elixir \"Deeper\" provavelmente carregará as configurações de `sys_options` para um cache interno (ex: um Agente, ETS, ou Application environment) na inicialização para acesso rápido.
*   **Atualização e Invalidação de Cache:** Quando uma opção é atualizada via esta API, o cache de configurações no backend Elixir deve ser invalidado e recarregado para que as mudanças tenham efeito.

## 1. Endpoints para Configurações (`/api/v1/admin/system-settings/options`)

### `GET /api/v1/admin/system-settings/options`
*   **Descrição:** Lista todas as opções do sistema, agrupadas por categoria (como no Studio do UNA).
*   **Query Parameters:**
    *   `category_key` (string): Filtra opções por uma chave de categoria específica (ex: \"general\", \"site_preferences\", \"bx_persons_general\"). A chave da categoria pode ser o `sys_options_categories.name`.
    *   `type_key` (string): Filtra por tipo de opção (ex: \"performance\", \"security\"). Baseado em `sys_options_types.name`.
    *   `search_term` (string): Busca no nome (`sys_options.name`) ou legenda (`sys_options.caption`) da opção.
*   **Resposta de Sucesso (200 OK):** Uma estrutura que agrupa opções por categoria e tipo.

```json
    {
      \"data\": [
        {
          \"type_name\": \"General Settings\", // sys_options_types.caption
          \"type_key\": \"general\",         // sys_options_types.name
          \"categories\": [
            {
              \"category_name\": \"Site Preferences\", // sys_options_categories.caption
              \"category_key\": \"site_preferences\",  // sys_options_categories.name
              \"options\": [
                {
                  \"name\": \"site_title\", // sys_options.name
                  \"caption\": \"Site Title\", // sys_options.caption
                  \"value\": \"My Awesome Deeper Site\", // sys_options.value
                  \"type\": \"text\", // sys_options.type
                  \"info\": \"The main title of your website.\", // sys_options.info
                  \"extra\": \"\" // sys_options.extra (ex: para selects)
                },
                {
                  \"name\": \"enable_feature_x\",
                  \"caption\": \"Enable Feature X\",
                  \"value\": \"on\", // ou 1, true
                  \"type\": \"checkbox\",
                  \"info\": \"Toggles Feature X globally.\",
                  \"extra\": \"\"
                }
                // ... mais opções nesta categoria
              ]
            }
            // ... mais categorias neste tipo
          ]
        }
        // ... mais tipos de configurações
      ]
    }
```

```json
    {
      \"data\": {
        \"name\": \"site_title\",
        \"caption\": \"Site Title\",
        \"value\": \"My Awesome Deeper Site\",
        \"type\": \"text\",
        \"info\": \"The main title of your website.\",
        \"extra\": \"\",
        \"category_key\": \"site_preferences\",
        \"type_key\": \"general\"
      }
    }
```

```json
    {
      \"value\": \"My Updated Deeper Site Title\" // O tipo do valor deve corresponder ao sys_options.type
    }
```

```json
    {
      \"data\": {
        \"name\": \"site_title\",
        \"caption\": \"Site Title\",
        \"value\": \"My Updated Deeper Site Title\",
        // ...
      }
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1, // sys_options_mixes.id
          \"type\": \"template\",
          \"category\": \"theme\",
          \"name\": \"lucid\", // sys_options_mixes.name (slug do tema)
          \"title\": \"Lucid Theme (Light)\", // sys_options_mixes.title
          \"dark\": false,
          \"active\": true,
          \"published\": true
        },
        {
          \"id\": 2,
          \"type\": \"template\",
          \"category\": \"theme\",
          \"name\": \"lucid_dark\",
          \"title\": \"Lucid Theme (Dark)\",
          \"dark\": true,
          \"active\": false,
          \"published\": true
        }
      ]
    }
```

```json
    {
      \"data\": {
        \"mix_id\": 1,
        \"mix_name\": \"lucid\",
        \"options\": [ // Array de { option_name: string, value: any }
          { \"option_name\": \"sys_template_page_width_min\", \"value\": \"768\" },
          { \"option_name\": \"sys_template_color_bg\", \"value\": \"#FFFFFF\" }
          // ...
        ]
      }
    }
```

```json
    {
      \"message\": \"Mix 'lucid' activated successfully.\",
      \"active_mix\": { /* ... detalhes do mix ativado ... */ }
    }
```

### `GET /api/v1/admin/system-settings/options/{option_name}`
*   **Descrição:** Obtém o valor e os detalhes de uma opção específica pelo seu nome (`sys_options.name`).
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `404 Not Found`.

### `PUT /api/v1/admin/system-settings/options/{option_name}`
*   **Descrição:** Atualiza o valor de uma opção específica.
*   **Corpo da Requisição (JSON):**

    *   Para checkboxes, o valor pode ser `\"on\"`/`\"off\"`, `true`/`false`, ou `1`/`0`. A API deve ser consistente.
*   **Lógica do Backend:**
    1.  Valida o novo valor com base no `sys_options.type` e `sys_options.check` (se a lógica de validação do UNA for portada).
    2.  Atualiza `sys_options.value` no banco de dados.
    3.  **Invalida/Atualiza o cache de configurações no Elixir.**
*   **Resposta de Sucesso (200 OK):** Os detalhes da opção atualizada.

*   **Respostas de Erro:** `400 Bad Request` (valor inválido), `404 Not Found`, `422 Unprocessable Entity` (falha na validação).

## 2. Gerenciamento de \"Mixes\" de Opções (Ex: Temas) (`/api/v1/admin/system-settings/mixes`)
*No UNA, `sys_options_mixes` e `sys_options_mixes2options` são usados para criar conjuntos de valores de opções, como temas (claro/escuro) ou outros presets.*

### `GET /api/v1/admin/system-settings/mixes`
*   **Descrição:** Lista todos os mixes de opções disponíveis.
*   **Query Parameters:** `type` (string, ex: \"template\" para temas), `category` (string).
*   **Resposta de Sucesso (200 OK):**

### `GET /api/v1/admin/system-settings/mixes/{mix_id}/options`
*   **Descrição:** Obtém todos os valores de opções específicas para um determinado mix.
*   **Resposta de Sucesso (200 OK):**

### `POST /api/v1/admin/system-settings/mixes/activate/{mix_id}`
*   **Descrição:** Ativa um mix específico (ex: muda o tema do site).
*   **Lógica do Backend:**
    1.  Marca o `mix_id` como `active=1` e outros mixes do mesmo `type` e `category` como `active=0` em `sys_options_mixes`.
    2.  Aplica os valores de `sys_options_mixes2options` para o `mix_id` ativado às opções correspondentes em `sys_options`. (Esta lógica é complexa e precisa ser cuidadosamente portada do UNA se esta funcionalidade for mantida).
    3.  **Invalida/Atualiza o cache de configurações no Elixir.**
*   **Corpo da Requisição:** Vazio.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `404 Not Found`.

*(Endpoints para criar/editar/deletar mixes e suas opções associadas seriam mais complexos e podem ser adiados, pois geralmente são definidos por desenvolvedores de temas/módulos).*

## Considerações para API de Admin de Configurações:

*   **Tipos de Dados:** A API deve lidar corretamente com os diferentes `type` de `sys_options` ao receber e retornar valores (ex: booleanos para checkboxes, strings para texto, números para `digit`).
*   **Validação:** Se a lógica de `sys_options.check`, `sys_options.check_params`, `sys_options.check_error` do UNA for portada, a API `PUT /options/{option_name}` deve usá-la para validar o novo valor.
*   **Impacto das Mudanças:** Alterar configurações do sistema pode ter um impacto significativo no comportamento da plataforma. A interface de administração deve alertar o usuário sobre isso.
*   **Segurança:** Acesso a esta API deve ser estritamente controlado.

Esta API fornecerá a capacidade de ajustar dinamicamente o comportamento e a aparência da plataforma \"Deeper\" através de um painel de administração.