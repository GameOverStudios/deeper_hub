# Módulo: `DeeperHub.ServerTags` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.ServerTags`

O módulo `DeeperHub.ServerTags` é responsável por gerenciar as **tags (etiquetas)** associadas aos servidores na plataforma DeeperHub. As tags são palavras-chave ou frases curtas que descrevem características, modos de jogo, comunidades ou outros aspectos relevantes de um servidor, ajudando os usuários a encontrar servidores de seu interesse e permitindo que os proprietários categorizem seus servidores.

Este módulo lida com a criação de novas tags, a associação de tags a servidores, a remoção dessas associações e a consulta de servidores por tags ou tags por servidor. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Criação e Gerenciamento de Tags (`create_tag/1`, `get_tag_by_name/1`, `update_tag/2`, `delete_tag/1`):**
    *   Permitir a criação de novas tags (potencialmente com moderação ou sugestão).
    *   Evitar a duplicação de tags (normalizando a entrada, ex: lowercase, sem espaços extras).
    *   Permitir a atualização (ex: renomear, adicionar descrição) ou exclusão de tags (com cuidado para as associações existentes).
*   **Associação de Tags a Servidores (`add_tag_to_server/3`, `remove_tag_from_server/3`):**
    *   Permitir que proprietários de servidores (ou administradores) associem tags existentes a um servidor.
    *   Permitir a remoção de tags de um servidor.
    *   Limitar o número de tags por servidor (configurável).
*   **Consulta de Tags e Servidores:**
    *   Listar todas as tags associadas a um servidor específico (`list_tags_by_server/1`).
    *   Listar todos os servidores associados a uma ou mais tags (`list_servers_by_tags/2`).
    *   Listar todas as tags disponíveis no sistema, possivelmente com contagem de uso (`list_tags/1`).
    *   Listar tags populares ou em tendência (`list_popular_tags/1`).
*   **Normalização e Validação de Tags:**
    *   Validar o formato das tags (ex: comprimento, caracteres permitidos).
    *   Normalizar tags para consistência (ex: converter para minúsculas, remover espaços extras, tratar sinônimos se avançado).
*   **Sugestão de Tags (Opcional):**
    *   Sugerir tags existentes enquanto um usuário digita.
*   **Observabilidade:**
    *   Registrar logs e métricas para operações com tags.
    *   Publicar eventos de domínio (tag criada, tag associada a servidor) no `Core.EventBus`.
*   **Caching:**
    *   Cachear listas de tags populares ou tags por servidor para melhorar o desempenho.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.ServerTags` (Fachada Pública):**
    *   Ponto de entrada para todas as operações relacionadas a tags de servidor.
    *   Delega para o `ServerTagsService`.
2.  **`DeeperHub.ServerTags.Services.ServerTagsService` (ou `DefaultServerTagsService`):**
    *   **Responsabilidade:** Orquestra a lógica de negócio para tags.
    *   **Interações:**
        *   `DeeperHub.Core.Repo`: Para CRUD com `TagSchema` e `ServerTagLinkSchema` (tabela de junção).
        *   `DeeperHub.Core.Cache`: Para cachear tags populares e tags por servidor.
        *   `DeeperHub.Core.EventBus`: Para publicar eventos.
        *   `DeeperHub.Core.ConfigManager`: Para obter configurações (limite de tags, caracteres permitidos).
3.  **Schemas Ecto:**
    *   **`DeeperHub.ServerTags.Schema.Tag`:** Representa uma tag única no sistema (ex: `id`, `name`, `description`, `usage_count`).
    *   **`DeeperHub.ServerTags.Schema.ServerTagLink` (ou `ServerTagAssociation`):** Tabela de junção many-to-many entre `Servers` e `Tags` (ex: `server_id`, `tag_id`, `added_by_user_id`, `added_at`).
4.  **`DeeperHub.ServerTags.Storage` (ou lógica dentro do `ServerTagsService`):**
    *   Encapsula as consultas Ecto.
5.  **`DeeperHub.ServerTags.CachedAdapter` (Opcional, da documentação original):**
    *   Se for decidido ter uma camada de cache explícita para este módulo, além do `Core.Cache`.

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/server_tags/
├── server_tags.ex                    # Fachada Pública
│
├── services/
│   └── server_tags_service.ex        # Serviço principal
│
├── schemas/                          # (Ou schema/)
│   ├── tag.ex
│   └── server_tag_link.ex
│
├── storage.ex                        # (Opcional) Módulo de queries Ecto
├── supervisor.ex                     # (Se houver GenServers, ex: para calcular popularidade)
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Tabela de Tags Únicas:** Manter uma tabela separada para tags (`TagSchema`) para evitar redundância de strings de tag e permitir o gerenciamento centralizado de tags (descrições, sinônimos, etc.).
*   **Normalização na Criação/Associação:** Tags devem ser normalizadas (ex: minúsculas, sem espaços extras nas pontas) antes de serem salvas ou associadas para garantir consistência.
*   **Contagem de Uso:** O campo `usage_count` na `TagSchema` pode ser atualizado (atomicamente ou por um worker) sempre que uma tag é associada/desassociada de um servidor, facilitando a listagem de tags populares.
*   **Autorização:** A adição/remoção de tags a um servidor deve ser restrita ao proprietário do servidor ou administradores.

## 🛠️ 4. Casos de Uso Principais

*   **Proprietário Adiciona Tags a um Servidor:**
    *   Na página de edição do servidor, o proprietário digita \"PvP\", \"Survival\", \"Economy\".
    *   A UI chama `DeeperHub.ServerTags.add_tags_to_server(server_id, [\"PvP\", \"Survival\", \"Economy\"], current_user_id)`.
    *   O `ServerTagsService` normaliza as tags, encontra/cria as tags na tabela `Tag`, e cria as associações na `ServerTagLink`. O `usage_count` das tags é incrementado.
*   **Jogador Filtra Servidores por Tag:**
    *   Jogador seleciona a tag \"RPG\" na interface de busca.
    *   A UI/API chama `DeeperHub.Servers.list_servers(%{tags: [\"rpg\"]})`.
    *   O `DeeperHub.Servers` internamente chama `DeeperHub.ServerTags.list_servers_by_tags([\"rpg\"])` para obter os `server_ids` relevantes.
*   **Administrador Modera uma Tag:**
    *   Um admin edita uma tag \"mmorpg\" para adicionar uma descrição ou corrigir um erro de digitação.
    *   Chama `DeeperHub.ServerTags.update_tag(tag_id, %{description: \"Massively Multiplayer Online Role-Playing Game\"})`.

## 🌊 5. Fluxos Importantes

### Fluxo de Adicionar uma Tag a um Servidor

1.  **Solicitação:** `DeeperHub.ServerTags.add_tag_to_server(server_id, \"new_tag_name\", user_id)`.
2.  **`ServerTagsService.add_tag_to_server/3`:**
    *   Verifica se `user_id` tem permissão para modificar tags do `server_id` (via `DeeperHub.Auth/RBAC` e consulta ao proprietário do servidor).
    *   Normaliza `new_tag_name` (ex: para minúsculas, trim).
    *   **Encontra ou Cria a Tag:**
        *   Chama `Storage.get_tag_by_name(normalized_tag_name)`.
        *   Se não encontrada, chama `Storage.create_tag(%{name: normalized_tag_name})`.
        *   Se a criação falhar, retorna erro.
    *   Obtém o `tag_id`.
    *   Verifica se a associação `(server_id, tag_id)` já existe na `ServerTagLinkSchema`.
        *   Se sim, não faz nada ou atualiza `added_at` (dependendo da lógica).
        *   Se não:
            *   Cria uma nova entrada em `ServerTagLinkSchema` com `server_id`, `tag_id`, `added_by_user_id`.
            *   Incrementa `usage_count` na `TagSchema` para o `tag_id` (atomicamente).
            *   Publica evento `server_tag_added` no `Core.EventBus`.
            *   Invalida caches relevantes (ex: tags do servidor, listagem de servidores por tag).
    *   Retorna `{:ok, tag_struct}`.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.ServerTags`)

### 6.1. `DeeperHub.ServerTags.add_tags_to_server(server_id :: String.t(), tag_names :: list(String.t()), current_user_id :: String.t()) :: {:ok, list(Tag.t())} | {:error, term()}`

*   **Descrição:** Associa uma lista de tags a um servidor. Cria as tags se não existirem. Verifica permissão.
*   **Retorno:** Lista das structs `Tag` associadas, ou erro.

### 6.2. `DeeperHub.ServerTags.remove_tag_from_server(server_id :: String.t(), tag_name :: String.t(), current_user_id :: String.t()) :: :ok | {:error, term()}`

*   **Descrição:** Remove a associação de uma tag de um servidor. Verifica permissão. Decrementa `usage_count`.

### 6.3. `DeeperHub.ServerTags.list_tags_by_server(server_id :: String.t(), opts :: keyword()) :: {:ok, list(Tag.t())}`

*   **Descrição:** Lista todas as tags associadas a um servidor.
*   **`opts`:** `:limit`, `:sort_by` (ex: `:name`, `:usage_count`).

### 6.4. `DeeperHub.ServerTags.list_servers_by_tags(tag_names :: list(String.t()), opts :: keyword()) :: {:ok, list(Server.t()), Pagination.t()}`

*   **Descrição:** Lista servidores que possuem *todas* as tags especificadas (AND) ou *qualquer uma* (OR, configurável).
*   **`opts`:** `:match_type` (`:all` | `:any`), `:page`, `:per_page`, `:preload_servers_with`.

### 6.5. `DeeperHub.ServerTags.list_tags(opts :: keyword()) :: {:ok, list(Tag.t()), Pagination.t()}`

*   **Descrição:** Lista todas as tags únicas no sistema.
*   **`opts`:** `:sort_by` (`:name`, `:usage_count`), `:page`, `:per_page`, `:search_term`.

### 6.6. `DeeperHub.ServerTags.list_popular_tags(limit :: integer(), opts :: keyword()) :: {:ok, list(Tag.t())}`

*   **Descrição:** Lista as tags mais usadas.
*   **`opts`:** `:min_usage_count`.

### 6.7. `DeeperHub.ServerTags.create_tag(attrs :: map(), current_user_id :: String.t()) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}` (Admin)

*   **Descrição:** Cria uma nova tag globalmente (requer permissão de admin).
*   **`attrs`:** `%{name: String.t(), description: String.t() | nil}`.

### 6.8. `DeeperHub.ServerTags.suggest_tags(partial_name :: String.t(), limit :: integer()) :: {:ok, list(String.t())}` (Nova Sugestão)

*   **Descrição:** Sugere nomes de tags existentes com base em uma entrada parcial.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:server_tags, :max_tags_per_server]`** (Integer): Número máximo de tags que um servidor pode ter. (Padrão: `10`)
*   **`[:server_tags, :max_tag_length]`** (Integer): Comprimento máximo de uma string de tag. (Padrão: `25`)
*   **`[:server_tags, :min_tag_length]`** (Integer): Comprimento mínimo. (Padrão: `2`)
*   **`[:server_tags, :allowed_chars_regex]`** (String): Regex para caracteres permitidos em tags (ex: `^[a-zA-Z0-9\\-\\#\\+]+$`).
*   **`[:server_tags, :auto_lowercase_tags]`** (Boolean): Se as tags devem ser convertidas automaticamente para minúsculas. (Padrão: `true`)
*   **`[:server_tags, :cache, :popular_tags_ttl_seconds]`** (Integer): TTL para cache de tags populares. (Padrão: `3600`)
*   **`[:server_tags, :cache, :tags_by_server_ttl_seconds]`** (Integer): TTL para cache de tags por servidor. (Padrão: `600`)

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.Repo`: Para persistência.
*   `DeeperHub.Core.ConfigManager`, `Core.EventBus`, `Core.Logger`, `Core.Metrics`, `Core.Cache`.
*   `DeeperHub.Auth` e `DeeperHub.RBAC`: Para verificar permissões de proprietários/admins para modificar tags de um servidor.
*   `DeeperHub.Servers`: Para validar `server_id` e, potencialmente, para o `ServerTags` ser um submódulo dele.

### 8.2. Bibliotecas Externas

*   `Ecto`.

## 🤝 9. Como Usar / Integração

*   **Módulo `DeeperHub.Servers`:**
    *   Ao exibir detalhes de um servidor, chama `ServerTags.list_tags_by_server/1`.
    *   Ao listar servidores com filtro de tag, chama `ServerTags.list_servers_by_tags/2`.
*   **Interface de Gerenciamento de Servidor (UI/API):**
    *   Permite que proprietários chamem `ServerTags.add_tags_to_server/3` e `ServerTags.remove_tag_from_server/3`.
*   **Sistema de Busca:**
    *   Pode usar `ServerTags.list_servers_by_tags/2` como parte de uma busca facetada.
    *   Pode usar `ServerTags.suggest_tags/2` para autocomplete no campo de busca de tags.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar a criação de tags (com normalização e prevenção de duplicatas).
*   Testar a associação e desassociação de tags a servidores, incluindo verificação de permissão.
*   Testar a atualização do `usage_count`.
*   Testar as funções de listagem (`list_tags_by_server`, `list_servers_by_tags`, `list_popular_tags`) com diferentes cenários e filtros.
*   Testar a validação de formato e limites de tags.
*   Localização: `test/deeper_hub/server_tags/`.

### 10.2. Métricas

*   `deeper_hub.server_tags.tag.created.count`
*   `deeper_hub.server_tags.tag.associated_to_server.count` (tags: `server_id`, `tag_name`)
*   `deeper_hub.server_tags.tag.removed_from_server.count` (tags: `server_id`, `tag_name`)
*   `deeper_hub.server_tags.usage_count.updates.count` (tags: `tag_name`)
*   `deeper_hub.server_tags.cache.hit.count` (tags: `cache_type` (`popular`, `by_server`))
*   `deeper_hub.server_tags.cache.miss.count` (tags: `cache_type`)

### 10.3. Logs

*   **Nível INFO:** Nova tag criada, tag associada/removida de servidor.
*   **Nível WARNING:** Tentativa de adicionar tag inválida ou exceder limite de tags por servidor. Tentativa não autorizada de modificar tags.

### 10.4. Telemetria

*   `[:deeper_hub, :server_tags, :tag, :created | :updated | :deleted]`
    *   Metadados: `%{tag_id: id, name: name, admin_id: id}`
*   `[:deeper_hub, :server_tags, :association, :created | :deleted]`
    *   Metadados: `%{server_id: id, tag_id: id, user_id: id}`
*   `[:deeper_hub, :server_tags, :query, :list_by_server | :list_by_tags | :list_popular]`
    *   Metadados: `%{filters: map, result_count: count}`

## ❌ 11. Tratamento de Erros

*   Retornar `{:error, changeset}` para falhas de validação Ecto.
*   Retornar `{:error, :unauthorized}` para falhas de permissão.
*   Retornar `{:error, :limit_exceeded}` se tentar adicionar mais tags que o permitido.
*   Falhas ao interagir com o cache não devem impedir a operação principal, mas devem ser logadas.

## 🛡️ 12. Considerações de Segurança

*   **Validação de Entrada:** Validar rigorosamente o nome das tags para prevenir XSS se as tags forem exibidas diretamente sem escaping adicional (embora devam ser escapadas na renderização).
*   **Moderação de Tags:** Considerar um sistema de moderação ou lista negra para tags ofensivas ou inadequadas, especialmente se as tags puderem ser criadas livremente pelos usuários.
*   **Autorização:** Garantir que apenas usuários autorizados (proprietários de servidor, admins) possam adicionar/remover tags de um servidor.

## 🧑‍💻 13. Contribuição

*   Mantenha a lógica de normalização de tags consistente.
*   Garanta que o `usage_count` seja atualizado corretamente.
*   Pense na performance das queries de listagem, especialmente `list_servers_by_tags` que pode envolver joins complexos ou múltiplas queries.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um sistema de sugestão de tags baseado em IA/ML com base na descrição do servidor ou em tags de servidores similares.
*   [ ] Adicionar suporte para hierarquia de tags ou categorias de tags.
*   [ ] Permitir que administradores \"fixem\" ou \"promovam\" certas tags.
*   [ ] Criar um worker para recalcular `usage_count` periodicamente para garantir consistência, caso as atualizações atômicas se tornem um gargalo.
*   [ ] Interface administrativa para gerenciamento global de tags (merge de tags duplicadas/sinônimas, exclusão, edição de descrições).

---

*Última atualização: 2025-05-12*

---

Este módulo de tags é um bom exemplo de como uma funcionalidade aparentemente simples pode ter várias nuances e interações.

Agora, qual o próximo? Podemos seguir com outro \"submódulo\" do `DeeperHub.Servers`, como `ServerReviews` ou `ServerPackages`, ou voltar para um módulo Core ou de Segurança?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""continue"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Ok, vamos continuar com outro submódulo importante que interage com `DeeperHub.Servers`: o `DeeperHub.ServerReviews`. Este módulo lida com o feedback e avaliações dos usuários sobre os servidores.

---

