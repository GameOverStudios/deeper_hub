# API de Administração: Gerenciamento de Configurações do Sistema

Endpoints da API para administradores gerenciarem as configurações globais e de módulos da plataforma \"Deeper\", que são armazenadas e estruturadas de forma análoga às tabelas `sys_options*` do UNA.

**Permissões:** Todos os endpoints aqui requerem um papel de administrador do site com plenos poderes sobre as configurações do sistema.

## Contexto das Configurações no UNA (e Adaptação para \"Deeper\")

No UNA, as configurações são organizadas em:
*   `sys_options_types`: Tipos de opções (ex: \"Geral\", \"Avançado\", \"Templates\").
*   `sys_options_categories`: Categorias dentro de cada tipo (ex: \"Site\", \"Segurança\", \"Email\" dentro do tipo \"Geral\").
*   `sys_options`: As opções individuais, cada uma com nome, valor, tipo de dado (digit, text, checkbox, select, etc.), e associada a uma categoria.
*   `sys_options_mixes`: \"Temas\" ou conjuntos de pré-configurações que podem ser aplicados, alterando os valores de um subconjunto de `sys_options`.

A API de administração \"Deeper\" precisará expor funcionalidades para listar e modificar essas configurações.

## Endpoints para Tipos e Categorias de Opções
(Principalmente para a UI do painel de administração poder organizar as opções)

### 1. Listar Tipos de Opções
*   **`GET /admin/settings/types`**
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        { \"id\": 1, \"name\": \"general\", \"caption\": \"Geral\", \"icon\": \"...\", \"order\": 0 },
        { \"id\": 2, \"name\": \"advanced\", \"caption\": \"Avançado\", \"icon\": \"...\", \"order\": 1 }
        // ...
      ]
    }
```

```json
    {
      \"data\": [
        // Se type_id=1 (Geral)
        { \"id\": 10, \"type_id\": 1, \"name\": \"site_info\", \"caption\": \"Informações do Site\", \"order\": 0 },
        { \"id\": 11, \"type_id\": 1, \"name\": \"security\", \"caption\": \"Segurança\", \"order\": 1 }
        // ...
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 101,
          \"category_id\": 10,
          \"name\": \"site_title\",
          \"caption\": \"Título do Site\",
          \"info\": \"O título principal exibido no navegador.\",
          \"value\": \"Minha Plataforma Deeper\",
          \"type\": \"text\", // \"digit\", \"text\", \"checkbox\", \"select\", \"textarea\", \"code\"
          \"extra\": \"\", // Para 'select', 'list', 'rlist': valores possíveis (ex: \"val1:Label1\\nval2:Label2\")
          \"order\": 0
        },
        {
          \"id\": 102,
          \"category_id\": 10,
          \"name\": \"maintenance_mode\",
          \"caption\": \"Modo de Manutenção\",
          \"info\": \"Coloca o site em modo de manutenção.\",
          \"value\": \"0\", // \"0\" ou \"1\" para checkbox
          \"type\": \"checkbox\",
          \"extra\": \"\",
          \"order\": 1
        }
        // ...
      ]
    }
```

```json
    {
      \"value\": \"Nova Plataforma Deeper Incrível\" // O valor deve ser compatível com o `type` da opção
    }
    // Para tipo \"checkbox\", \"value\" seria \"0\" ou \"1\" (string).
    // Para \"select\", \"value\" seria uma das chaves de `extra`.
```

```json
    {
      \"options\": [
        { \"name\": \"site_title\", \"value\": \"Título em Lote\" },
        { \"name\": \"maintenance_mode\", \"value\": \"1\" }
      ]
    }
```

```json
    {
      \"message\": \"Configurações atualizadas.\",
      \"results\": [
        { \"name\": \"site_title\", \"status\": \"success\", \"data\": { /* opção atualizada */ } },
        { \"name\": \"maintenance_mode\", \"status\": \"success\", \"data\": { /* opção atualizada */ } },
        { \"name\": \"opcao_invalida\", \"status\": \"error\", \"reason\": \"Opção não encontrada.\" }
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"type\": \"template\",
          \"category\": \"system\",
          \"name\": \"lucid_light_mix\",
          \"title\": \"Lucid Light (Default)\",
          \"dark\": 0,
          \"active\": 1,
          \"published\": 1
        }
        // ...
      ]
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"name\": \"lucid_light_mix\",
        // ... outros campos do mix ...
        \"options_values\": [ // Valores de sys_options_mixes2options
          { \"option_name\": \"template_site_logo_url\", \"value\": \"/path/to/logo.png\" },
          { \"option_name\": \"template_color_accent\", \"value\": \"#FF0000\" }
          // ...
        ]
      }
    }
```

### 2. Listar Categorias de Opções (Opcionalmente filtradas por tipo)
*   **`GET /admin/settings/categories`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:**
    *   `type_id` (integer): Filtrar categorias por um `sys_options_types.id`.
*   **Resposta de Sucesso (200 OK):**

*   **Nota:** CRUD para tipos e categorias é menos comum via API de runtime, pois são geralmente definidos pelos módulos na instalação. Mas poderiam existir se a flexibilidade for total.

## Endpoints para Opções de Configuração (`sys_options`)

### 1. Listar Opções de Configuração
*   **`GET /admin/settings/options`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:**
    *   `category_id` (integer): Filtrar opções por um `sys_options_categories.id`.
    *   `type_id` (integer): Filtrar opções por um `sys_options_types.id` (indiretamente, via categorias).
    *   `name_like` (string): Buscar opções pelo nome (ex: `site_%`).
*   **Resposta de Sucesso (200 OK):** Lista de opções.

### 2. Obter uma Opção de Configuração Específica
*   **`GET /admin/settings/options/{option_name_or_id}`**
    *   Pode aceitar o nome único da opção (ex: `site_title`) ou seu ID numérico.
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK):** Objeto da opção (formato do item da lista acima).
*   **Respostas de Erro:** `404`.

### 3. Atualizar o Valor de uma Opção de Configuração
*   **`PUT /admin/settings/options/{option_name_or_id}`**
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):**

*   **Ação do Backend:**
    *   Valida o novo valor contra o `type` da opção e, se aplicável, contra a lista de valores em `extra` ou `check`/`check_params` do `sys_options`.
    *   Atualiza o campo `value` na tabela `sys_options`.
    *   **Importante:** Muitas configurações podem exigir a limpeza de caches do sistema ou a recarga de configurações em runtime. A API pode apenas atualizar o DB, ou pode tentar disparar um evento para que o sistema Elixir recarregue suas configurações.
*   **Resposta de Sucesso (200 OK):** Objeto da opção atualizado.
*   **Respostas de Erro:** `400` (validação do valor falhou), `401`, `403`, `404`.

### 4. Atualizar Múltiplas Opções de Configuração (Em Lote)
*   **`PUT /admin/settings/options`**
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):** Lista de objetos, cada um com `name` (ou `id`) e `value`.

*   **Ação do Backend:** Itera sobre as opções, valida e atualiza cada uma. Pode ser dentro de uma transação.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `400`, `401`, `403`.

## Endpoints para \"Mixes\" de Configuração (`sys_options_mixes`)
(Se a funcionalidade de \"temas\" ou \"presets\" de configuração for portada)

### 1. Listar Mixes de Configuração Disponíveis
*   **`GET /admin/settings/mixes`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `type` (ex: `template`, `colors`), `category`.
*   **Resposta de Sucesso (200 OK):**

### 2. Obter Detalhes de um Mix (incluindo suas opções e valores)
*   **`GET /admin/settings/mixes/{mix_id_or_name}`**
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK):**

### 3. Ativar um Mix de Configuração
*   **`POST /admin/settings/mixes/{mix_id_or_name}/activate`**
*   **Autenticação:** Admin Requerida.
*   **Ação do Backend:**
    1.  Desativa outros mixes do mesmo `type` e `category` (se aplicável).
    2.  Marca o mix selecionado como `active = 1`.
    3.  **Importante:** Aplica os valores de `sys_options_mixes2options` do mix ativado para as respectivas entradas em `sys_options`. Isso pode envolver a atualização de múltiplas opções.
    4.  Pode precisar limpar caches do sistema.
*   **Resposta de Sucesso (200 OK):** `{ \"message\": \"Mix 'lucid_light_mix' ativado e configurações aplicadas.\" }`
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 4. (Opcional) Criar/Atualizar/Excluir Mixes
    (Mais complexo, pois envolve gerenciar `sys_options_mixes` e `sys_options_mixes2options`)
*   `POST /admin/settings/mixes`
*   `PUT /admin/settings/mixes/{mix_id}`
*   `DELETE /admin/settings/mixes/{mix_id}`

## Considerações para Repositórios e Contextos:

*   **`Deeper.SystemCore.SettingsRepo` (ou `OptionsRepo`):**
    *   Funções para listar tipos, categorias e opções com filtros.
    *   Funções para obter uma opção por nome ou ID.
    *   Função para atualizar o valor de uma opção (ex: `update_option_value(option_name, new_value)`).
    *   Funções para CRUD de mixes e suas opções associadas.
    *   Lógica para aplicar um mix (ler todas as opções do mix e atualizar `sys_options`).
*   **`Deeper.SystemCore.Settings` (Contexto/Serviço):**
    *   Verificará permissões de admin.
    *   Orquestrará a aplicação de um mix, incluindo a atualização de múltiplas opções e, potencialmente, o disparo de um evento para recarregar configurações no sistema Elixir.
    *   Pode conter lógica de validação para os valores das opções com base no seu `type` e `extra` antes de chamar o Repo.
*   **Recarga de Configuração em Runtime:**
    *   Quando uma configuração é alterada via API, o sistema Elixir (que pode ter carregado as configurações na inicialização) precisa ser notificado para recarregar os valores atualizados. Isso pode ser feito através de:
        *   Um `Agent` ou `GenServer` que mantém as configurações e pode ser instruído a recarregar.
        *   Um sistema de PubSub onde a API publica um evento \"config_updated\" e os módulos interessados (incluindo o próprio guardião de config) subscrevem a ele.
        *   Simplesmente lendo do DB a cada vez para configurações menos críticas (menos performático).

Esta API de administração de configurações é vital para a customização e manutenção da plataforma \"Deeper\".