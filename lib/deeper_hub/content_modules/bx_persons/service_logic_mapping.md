# Documentação Deeper: Mapeamento de Lógica de Serviço (`bx_persons`)

No sistema UNA PHP, os módulos frequentemente expõem funcionalidades através de \"service calls\" (métodos públicos em suas classes de módulo). Essas service calls são usadas, por exemplo, para popular blocos de conteúdo (`sys_pages_blocks` do tipo `service`).

A API \"Deeper\", sendo RESTful, não executará diretamente essas service calls PHP. Em vez disso, a funcionalidade que elas forneciam precisa ser mapeada para:

1.  **Endpoints da API existentes:** Muitos serviços que listam ou exibem dados podem ser substituídos por chamadas aos endpoints da API `GET /persons` ou `GET /persons/{id}` com os parâmetros corretos.
2.  **Novos endpoints de API específicos:** Se um serviço tinha uma lógica muito particular não coberta pelos endpoints CRUD básicos.
3.  **Lógica no Cliente:** Alguma lógica de apresentação que estava no serviço PHP pode precisar ser movida para o cliente, que consumirá dados mais brutos da API \"Deeper\".
4.  **Combinação de dados no cliente:** O cliente pode precisar chamar múltiplos endpoints da API \"Deeper\" e combinar os dados para replicar a informação de um bloco complexo.

Este documento lista algumas service calls comuns do módulo `bx_persons` do UNA e como suas funcionalidades seriam abordadas pela API \"Deeper\".

## Exemplos de Mapeamento de Service Calls de `bx_persons`

### 1. Bloco: \"Últimos Perfis\" / \"Perfis Recentes\"
    *   **UNA PHP Service (Exemplo Conceitual):** `BxPersonsModule::service_latest_profiles(count = 5, context_param = null)`
    *   **Funcionalidade:** Exibe uma lista dos perfis de pessoas mais recentemente adicionados.
    *   **Mapeamento para API \"Deeper\":**
        *   O cliente chamaria: `GET /api/v1/persons?sort_by=added_desc&per_page=5`
        *   O `context_param` (se relevante para filtrar por algum contexto) seria traduzido para um query parameter adicional.
        *   A API retornaria uma lista de perfis (com dados resumidos), e o cliente renderizaria o bloco.

### 2. Bloco: \"Perfis em Destaque\"
    *   **UNA PHP Service:** `BxPersonsModule::service_featured_profiles(count = 3)`
    *   **Funcionalidade:** Exibe perfis marcados como \"featured\".
    *   **Mapeamento para API \"Deeper\":**
        *   O cliente chamaria: `GET /api/v1/persons?featured=true&sort_by=random&per_page=3` (ou uma ordenação específica para \"featured\").
        *   A API filtraria por `bx_persons_data.featured = 1`.

### 3. Bloco: \"Aniversariantes de Hoje\"
    *   **UNA PHP Service:** `BxPersonsModule::service_birthdays_today()`
    *   **Funcionalidade:** Lista perfis fazendo aniversário no dia atual.
    *   **Mapeamento para API \"Deeper\":**
        *   O cliente chamaria: `GET /api/v1/persons?birth_month_day=MM-DD` (onde MM-DD é o mês e dia atuais).
        *   O backend `PersonsRepo` precisaria de uma função que possa filtrar `bx_persons_data.birthday` (que é `TEXT` no formato `YYYY-MM-DD`) pela parte do mês e dia. SQLite: `WHERE SUBSTR(birthday, 6, 5) = 'MM-DD'`.

### 4. Bloco: \"Perfil (Visualização Completa)\" - Usado em páginas de perfil
    *   **UNA PHP Service:** `BxPersonsModule::service_entity_page_view(profile_id)` ou similar.
    *   **Funcionalidade:** Exibe todos os detalhes de um perfil específico.
    *   **Mapeamento para API \"Deeper\":**
        *   O cliente chamaria: `GET /api/v1/persons/{profile_id_or_uri}`
        *   A API retornaria todos os dados detalhados do perfil. O cliente é responsável por renderizar todas as seções (informações, fotos, amigos, etc.).

### 5. Bloco: \"Ações do Perfil\" (Ex: Adicionar Amigo, Enviar Mensagem, Denunciar)
    *   **UNA PHP Service:** `BxPersonsModule::service_profile_actions(profile_id, viewer_id)`
    *   **Funcionalidade:** Mostra um conjunto de botões de ação relevantes para o perfil visualizado, considerando o visualizador.
    *   **Mapeamento para API \"Deeper\":**
        *   Esta é mais complexa, pois envolve lógica de permissões e estado de conexão.
        *   A API `GET /api/v1/persons/{profile_id_or_uri}` poderia incluir uma seção `available_actions` na resposta, baseada no `viewer_id` (do token JWT) e no `profile_id` visualizado.

```json
            \"available_actions\": [
              {\"action\": \"add_friend\", \"label\": \"Adicionar Amigo\", \"api_endpoint\": \"/api/v1/connections/friends\", \"method\": \"POST\", \"params\": {\"target_profile_id\": \"{profile_id}\"}},
              {\"action\": \"send_message\", \"label\": \"Enviar Mensagem\", \"ui_link\": \"/messages/new/{profile_id}\"},
              {\"action\": \"report\", \"label\": \"Denunciar\", \"api_endpoint\": \"/api/v1/reports/persons/{profile_id}\", \"method\": \"POST\"}
            ]
```

        *   A lógica para determinar quais ações estão disponíveis residiria no backend (usando `AclRepo`, `ConnectionsRepo`, etc.) e seria parte da resposta do perfil. O cliente renderizaria os botões e executaria as chamadas de API ou navegação UI correspondentes.

### 6. Bloco: \"Galeria de Fotos do Perfil\"
    *   **UNA PHP Service:** `BxPersonsModule::service_profile_pictures(profile_id, count = 6)`
    *   **Funcionalidade:** Exibe uma prévia das fotos da galeria do perfil.
    *   **Mapeamento para API \"Deeper\":**
        *   O cliente chamaria: `GET /api/v1/persons/{profile_id}/pictures?per_page=6`
        *   A API retornaria a lista de fotos, e o cliente as renderizaria.

### 7. Bloco: \"Estatísticas Sociais do Perfil\" (Views, Votos, Comentários)
    *   **UNA PHP Service:** `BxPersonsModule::service_social_stats(profile_id)`
    *   **Funcionalidade:** Exibe contadores de visualizações, média de votos, número de comentários, etc.
    *   **Mapeamento para API \"Deeper\":**
        *   Esses contadores (`views`, `rate_avg`, `rate_count`, `comments_count`, etc.) já estão planejados para serem incluídos na resposta principal de `GET /api/v1/persons/{profile_id_or_uri}` (vindos de `bx_persons_data`). O cliente simplesmente os exibiria.

### 8. Bloco: \"Comentários do Perfil\"
    *   **UNA PHP Service:** `BxPersonsModule::service_profile_comments(profile_id)`
    *   **Funcionalidade:** Exibe o sistema de comentários para um perfil.
    *   **Mapeamento para API \"Deeper\":**
        *   O cliente chamaria: `GET /api/v1/persons/{profile_id}/comments` (que usaria o sistema genérico de comentários).
        *   A API retornaria os comentários, e o cliente os renderizaria.

## Abordagem Geral:

*   **Identificar a Intenção:** Para cada \"bloco de serviço\" do UNA PHP, o primeiro passo é entender qual *dado* ou *funcionalidade* ele realmente expõe.
*   **Usar Endpoints Existentes:** Verificar se a informação já está disponível através dos endpoints CRUD ou de listagem da API \"Deeper\" com os parâmetros corretos.
*   **Dados Estruturados:** A API \"Deeper\" deve focar em fornecer dados estruturados (JSON). A responsabilidade de apresentar esses dados em um \"bloco\" visual é do cliente.
*   **Lógica de Permissão e Relevância:** A lógica de permissão (ACL) e a relevância contextual (ex: mostrar o botão \"Editar Perfil\" apenas para o dono) devem ser tratadas pelo backend ao construir a resposta da API, ou o cliente deve ter informações suficientes (ex: `is_owner: true`) para tomar essas decisões na UI.

Este mapeamento é um processo contínuo. À medida que mais blocos de serviço do `bx_persons` (ou outros módulos) são analisados, esta lista pode ser expandida. O objetivo é garantir que a API \"Deeper\" forneça os \"blocos de construção\" de dados que o cliente precisa, em vez de replicar a lógica de renderização de HTML dos serviços PHP.