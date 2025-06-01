# Documentação Deeper: Endpoints da API Pública para Configurações do Sistema

Este documento especifica os endpoints da API RESTful \"Deeper\" para leitura pública de configurações do sistema (armazenadas em `sys_options`). A modificação dessas configurações é feita através da API de Administração.

## Objetivos:

*   Permitir que o cliente frontend acesse configurações necessárias para seu funcionamento (ex: título do site, configurações de upload, chaves de API de terceiros para o cliente).
*   Permitir que outros serviços do backend (se houver) possam consultar configurações de forma centralizada.

## Módulo de Acesso a Dados (Já Definido):

*   `Deeper.SystemCore.OptionsRepo` será utilizado.

## Endpoints da API Pública para Configurações

Todos os endpoints públicos para configurações podem estar sob `/api/v1/settings/...` ou `/api/v1/config/...`.

### 1. Obter um Conjunto Específico de Opções Públicas

Em vez de expor todas as opções, é mais seguro e prático ter um endpoint que retorne um conjunto predefinido de opções que são seguras e úteis para o cliente.

*   **Endpoint:** `GET /api/v1/config/public`
*   **Propósito:** Retorna um conjunto de configurações chave que são necessárias para o cliente frontend.
*   **Autenticação:** Nenhuma (endpoint público).
*   **Lógica do Backend:**
    1.  O controller terá uma lista predefinida de nomes de opções (`sys_options.name`) que são consideradas públicas e seguras.
    2.  Para cada nome na lista, chama `Deeper.SystemCore.OptionsRepo.get_option_value(option_name)`.
    3.  Constrói um objeto JSON com os nomes das opções como chaves e seus valores.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"site_title\": \"Deeper Community\",
        \"site_description\": \"A new way to connect.\",
        \"maintenance_mode\": \"0\", // 0 ou 1
        \"default_lang\": \"en\",
        \"max_upload_filesize_mb\": 10, // Exemplo de configuração para o cliente
        \"google_maps_api_key_frontend\": \"AIzaSy...\", // Chave segura para uso no frontend
        \"enable_feature_x\": true
        // ... outras opções públicas ...
      }
    }
```

```json
    {
      \"data\": {
        \"name\": \"site_title\",
        \"value\": \"Deeper Community\"
      }
    }
```

*   **Respostas de Erro:**
    *   `500 Internal Server Error`: Se houver problemas ao buscar as opções.

### 2. Obter o Valor de uma Opção Pública Específica (Menos Comum para Cliente)

Este endpoint pode ser útil para casos muito específicos, mas geralmente o endpoint agregado (`/api/v1/config/public`) é preferível.

*   **Endpoint:** `GET /api/v1/config/options/{option_name}`
*   **Propósito:** Retorna o valor de uma única opção pública específica.
*   **Autenticação:** Nenhuma.
*   **Parâmetros de URL:**
    *   `{option_name}` (String, Obrigatório): O nome da opção (`sys_options.name`).
*   **Lógica do Backend:**
    1.  Verificar se `{option_name}` está em uma lista de permissão de opções publicamente acessíveis por este endpoint.
    2.  Se permitido, chamar `Deeper.SystemCore.OptionsRepo.get_option_value(option_name)`.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:**
    *   `403 Forbidden`: Se a opção solicitada não estiver na lista de permissão para acesso público individual.
    *   `404 Not Found`: Se a opção não existir.
    *   `500 Internal Server Error`.

### Considerações:

*   **Segurança:** É crucial NÃO expor opções sensíveis (como senhas de banco de dados, chaves secretas de API do servidor) através destes endpoints públicos. A lista de opções retornada por `/api/v1/config/public` deve ser cuidadosamente curada.
*   **Cache:** As respostas destes endpoints são candidatas ideais para cache (tanto no lado do servidor quanto no lado do cliente via cabeçalhos HTTP Cache-Control), pois os valores das configurações não mudam com frequência. Quando um administrador atualiza uma configuração, o cache do servidor para `/api/v1/config/public` deve ser invalidado.
*   **Granularidade vs. Desempenho:** O endpoint `/api/v1/config/public` que retorna múltiplas configurações de uma vez é geralmente preferível a múltiplas chamadas para `/api/v1/config/options/{option_name}` por questões de desempenho (redução de round-trips de rede).

Estes endpoints fornecem ao cliente frontend as informações de configuração necessárias para adaptar seu comportamento e exibir informações corretas.