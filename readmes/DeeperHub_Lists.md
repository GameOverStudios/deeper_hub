# Módulo: `DeeperHub.Lists` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Lists`

O módulo `DeeperHub.Lists` (originalmente `DeeperHub.Services.Lists`) serve como um **repositório centralizado para listas de dados de referência e enumerações** usadas em todo o sistema DeeperHub. Em vez de hardcodar essas listas em vários módulos ou ter múltiplas tabelas pequenas e isoladas, este módulo fornece uma maneira genérica de armazenar, gerenciar e consultar esses \"tipos\" ou \"categorias\".

Exemplos de listas que podem ser gerenciadas aqui:
*   Tipos de Conquistas (ex: 'Milestone', 'Event')
*   Categorias Gerais (ex: 'Gaming', 'Programming')
*   Tipos de Conteúdo (ex: 'Article', 'Video')
*   Engines de Jogos (ex: 'Unity', 'Unreal Engine')
*   Tipos de Feedback (ex: 'Bug Report', 'Feature Request')
*   Idiomas Suportados
*   Tipos de Rede de Servidor
*   Plataformas Suportadas
*   Status Comuns (ex: para tickets, servidores, etc., se não forem específicos demais para seus próprios módulos)
*   Tags Globais (se houver um sistema de tags que não seja específico apenas para servidores)

O objetivo é fornecer consistência, facilitar a adição de novas opções e permitir que a UI popule seletores e filtros de forma dinâmica. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Gerenciamento CRUD de Itens de Lista Genéricos (`create_list_item/2`, `get_list_item/2`, `update_list_item/2`, `delete_list_item/1`):**
    *   Permitir que administradores criem novos itens para uma lista específica (ex: adicionar um novo \"Tipo de Conquista\").
    *   Cada item de lista teria um `list_type` (identificador da lista, ex: `:achievement_type`), um `value` (o valor real, ex: \"milestone\"), uma `label` (para exibição, ex: \"Marco Histórico\"), e opcionalmente `description`, `is_active`, `metadata` (JSONB para dados extras).
    *   Atualizar ou desativar/excluir itens de lista.
*   **Consulta de Itens de Lista:**
    *   Listar todos os itens para um `list_type` específico (`list_items_by_type/1`).
    *   Obter um item específico pelo seu valor ou ID dentro de um `list_type`.
    *   Filtrar itens por `is_active`.
*   **Validação de Dados:**
    *   Garantir que os valores e labels sejam únicos dentro de um `list_type`.
    *   Validar os campos ao criar/atualizar itens.
*   **Caching:**
    *   Cachear listas frequentemente acessadas para performance, já que esses dados de referência raramente mudam.
*   **Internacionalização de Labels (Opcional):**
    *   Se as `labels` precisarem ser traduzidas, este módulo pode integrar com `Core.Internationalization` ou armazenar traduções no campo `metadata`.
*   **Observabilidade e Auditoria:**
    *   Logar e auditar a criação/modificação de itens de lista, especialmente aqueles que afetam a lógica do sistema.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Lists` (Fachada Pública):**
    *   Ponto de entrada para todas as operações relacionadas a listas genéricas.
    *   Delega para o `ListsService`.
2.  **`DeeperHub.Lists.Services.ListsService` (ou `DefaultListsService`):**
    *   **Responsabilidade:** Orquestra a lógica de negócio para o gerenciamento de itens de lista.
    *   **Interações:**
        *   `DeeperHub.Core.Repo`: Para CRUD com `ListItemSchema`.
        *   `DeeperHub.Core.Cache`: Para cachear listas.
        *   `DeeperHub.Core.ConfigManager`: Para obter a lista de `list_type`s conhecidos ou configurações padrão.
        *   `DeeperHub.Audit`: Para auditar modificações.
3.  **`DeeperHub.Lists.Schemas.ListItemSchema` (Nova Sugestão, em vez de múltiplos schemas pequenos):**
    *   Um schema Ecto genérico para armazenar todos os itens de lista.
    *   Campos: `id`, `list_type` (string ou atom, indexado), `value` (string, indexado dentro do `list_type`), `label` (string), `description` (text, opcional), `metadata` (jsonb, opcional), `is_active` (boolean, default: true), `sort_order` (integer, opcional), `inserted_at`, `updated_at`.
    *   Índice único em `(list_type, value)`.
4.  **`DeeperHub.Lists.Storage` (ou lógica no `ListsService`):**
    *   Encapsula as queries Ecto para `ListItemSchema`.
5.  **`DeeperHub.Lists.CachedAdapter` (Opcional, da documentação original para outros serviços, mas aplicável aqui):**
    *   Camada de cache explícita se o `Core.Cache` genérico não for suficiente.

*(Os múltiplos schemas pequenos listados na documentação original como `AchievementType`, `Category`, `ContentType`, etc., seriam consolidados no `ListItemSchema` usando o campo `list_type` para diferenciá-los. Isso simplifica muito a manutenção e a adição de novas listas sem alterações de schema no DB.)*

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/lists/
├── lists.ex                          # Fachada Pública
│
├── services/
│   └── lists_service.ex              # Serviço principal
│
├── schemas/
│   └── list_item_schema.ex
│
├── storage.ex                        # (Opcional) Módulo de queries Ecto
├── cached_adapter.ex                 # (Opcional)
├── supervisor.ex                     # (Se houver GenServers, ex: para cache warming)
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Schema Genérico Único:** Usar um `ListItemSchema` com um campo `list_type` é mais escalável e flexível do que criar uma nova tabela para cada pequena lista de enumeração.
*   **`value` vs. `label`:** O `value` é o identificador programático (ex: `:bug_report`, `\"milestone_ach\") e a `label` é para exibição na UI (ex: \"Relatório de Bug\", \"Conquista de Marco\").
*   **Dados Estáticos vs. Gerenciados por Admin:** Decidir se essas listas são populadas via seeds no deploy (mais estático) ou gerenciadas dinamicamente por administradores através de uma UI. A abordagem com `ListItemSchema` facilita o gerenciamento dinâmico.
*   **Caching Agressivo:** Como esses dados de referência mudam raramente, eles são candidatos ideais para caching agressivo.

## 🛠️ 4. Casos de Uso Principais

*   **Popular um Dropdown na UI para Seleção de Categoria de Suporte:**
    *   Frontend/API chama `DeeperHub.Lists.list_items_by_type(:support_ticket_category, %{is_active: true, sort_by: :label_asc})`.
    *   A lista de `%{value: \"technical_issue\", label: \"Problema Técnico\"}, ...` é usada para renderizar o dropdown.
*   **Administrador Adiciona um Novo \"Tipo de Recompensa\":**
    *   Admin usa uma interface de gerenciamento.
    *   API chama `DeeperHub.Lists.create_list_item(%{list_type: :reward_type, value: \"exclusive_skin\", label: \"Skin Exclusiva\", description: \"Desbloqueia uma skin rara para o avatar.\"}, admin_user_id)`.
*   **Sistema Valida um `event_type` Fornecido pelo Usuário:**
    *   Ao criar um `ServerEvent`, o `ServerEventsService` verifica se o `event_type` fornecido é um valor válido.
    *   Chama `DeeperHub.Lists.get_list_item_by_value(:server_event_type, user_provided_event_type)`. Se retornar `nil` ou inativo, o tipo é inválido.

## 🌊 5. Fluxos Importantes

### Fluxo de Adição de um Novo Item de Lista por um Administrador

1.  **Administrador (UI):** Seleciona a lista (ex: \"Tipos de Feedback\"), preenche `value` (\"interface_bug\") e `label` (\"Bug de Interface\").
2.  **Controller API (Admin):** Valida permissões. Chama `DeeperHub.Lists.create_list_item(admin_user_id, %{list_type: :feedback_type, value: \"interface_bug\", label: \"Bug de Interface\"})`.
3.  **`ListsService.create_list_item/2`:**
    *   Valida os atributos (ex: `list_type` é conhecido, `value` é único para esse `list_type`).
    *   Cria um `ListItemSchema` changeset.
    *   Se válido, `Core.Repo.insert(changeset)`.
    *   Se sucesso:
        *   Publica evento `list_item.created` no `Core.EventBus`.
        *   Invalida o cache para `:feedback_type`.
        *   Audita a ação.
        *   Retorna `{:ok, list_item_struct}`.
    *   Se falha, retorna erro.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.Lists`)

### 6.1. Gerenciamento de Itens (Principalmente Admin)

*   **`DeeperHub.Lists.create_list_item(admin_user_id :: String.t(), attrs :: map()) :: {:ok, ListItem.t()} | {:error, Ecto.Changeset.t()}`**
    *   `attrs`: `%{list_type: atom() | String.t(), value: String.t(), label: String.t(), description: String.t() | nil, metadata: map() | nil, is_active: boolean() | true, sort_order: integer() | nil}`.
*   **`DeeperHub.Lists.update_list_item(admin_user_id :: String.t(), list_item_id :: String.t(), attrs :: map()) :: {:ok, ListItem.t()} | {:error, Ecto.Changeset.t() | :unauthorized}`**
*   **`DeeperHub.Lists.delete_list_item(admin_user_id :: String.t(), list_item_id :: String.t()) :: :ok | {:error, :unauthorized | :not_found | :in_use}`**
    *   Pode impedir a exclusão se o item estiver em uso por outras entidades, preferindo desativar (`is_active: false`).

### 6.2. Consulta de Itens (Público/Sistema)

*   **`DeeperHub.Lists.list_items_by_type(list_type :: atom() | String.t(), opts :: keyword()) :: {:ok, list(ListItem.t())}`**
    *   `opts`: `:is_active` (boolean, Padrão: `true`), `:sort_by` (`:label`, `:value`, `:sort_order`), `:sort_order_direction` (`:asc`, `:desc`).
*   **`DeeperHub.Lists.get_list_item_by_value(list_type :: atom() | String.t(), item_value :: String.t(), opts :: keyword()) :: {:ok, ListItem.t() | nil}`**
    *   `opts`: `:is_active` (boolean, Padrão: `true`).
*   **`DeeperHub.Lists.get_list_item_label(list_type :: atom() | String.t(), item_value :: String.t(), default_label :: String.t() | nil) :: String.t() | nil` (Nova Sugestão)**
    *   Função de conveniência para obter rapidamente a `label` de um `value`.
*   **`DeeperHub.Lists.get_all_list_types() :: {:ok, list(atom() | String.t())}` (Nova Sugestão)**
    *   Retorna todos os `list_type`s distintos definidos no sistema.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:lists, :predefined_list_types]`** (List de Atoms/Strings): Uma lista de todos os `list_type`s que são conhecidos pelo sistema. Pode ser usado para validação ou para popular UIs de administração.
    *   Ex: `[:achievement_type, :category, :content_type, :engine, :feedback_type, :language, :network_type, :platform, :server_status, :tag_category, :support_ticket_priority]`
*   **`[:lists, :cache, :list_items_ttl_seconds]`** (Integer): TTL para cache de listas de itens. (Padrão: `3600` ou mais, pois mudam raramente).
*   **`[:lists, :allow_dynamic_list_types]`** (Boolean): Se `false`, apenas `list_type`s definidos em `predefined_list_types` podem ser criados. (Padrão: `false` para maior controle).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.Repo`, `Core.ConfigManager`, `Core.EventBus`, `Core.Logger`, `Core.Metrics`, `Core.Cache`.
*   `DeeperHub.Auth`/`RBAC`: Para permissões de administração das listas.
*   `DeeperHub.Audit`: Para auditar modificações.
*   `DeeperHub.Core.Internationalization` (Opcional): Se as `labels` forem traduzidas.

### 8.2. Bibliotecas Externas

*   `Ecto`.

## 🤝 9. Como Usar / Integração

*   **Validação de Entrada:** Módulos de serviço usam `get_list_item_by_value/3` para validar se um valor fornecido pelo usuário para um campo de \"tipo\" é uma opção válida e ativa.
    ```elixir
    # Em DeeperHub.Support.Services.SupportService
    def create_ticket(attrs) do
      case DeeperHub.Lists.get_list_item_by_value(:support_ticket_priority, attrs[:priority_value]) do
        {:ok, nil} -> {:error, %{priority: \"Prioridade inválida\"}}
        {:ok, _priority_item} -> # Prossiga com a criação
        # ...
      end
    end
    ```
*   **Popular Dropdowns em UIs:** A UI busca os itens de uma lista via API para preencher campos `<select>`.
*   **Seed de Dados:** O arquivo `priv/repo/seeds.exs` pode usar `DeeperHub.Lists.create_list_item/2` para popular as listas iniciais durante o setup do banco de dados.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar CRUD para `ListItemSchema`.
*   Testar a unicidade de `value` dentro de um `list_type`.
*   Testar as funções de listagem com filtros (`:is_active`).
*   Testar a lógica de cache.
*   Localização: `test/deeper_hub/lists/`.

### 10.2. Métricas

*   `deeper_hub.lists.items.created.count` (tags: `list_type`)
*   `deeper_hub.lists.items.updated.count` (tags: `list_type`)
*   `deeper_hub.lists.cache.hit.count` (tags: `list_type`)
*   `deeper_hub.lists.cache.miss.count` (tags: `list_type`)

### 10.3. Logs

*   **Nível INFO:** Novo item de lista criado/atualizado/desativado. Cache de lista invalidado.
*   **Nível WARNING:** Tentativa de criar item para um `list_type` não permitido (se `allow_dynamic_list_types` for `false`).
*   **Nível ERROR:** Falha ao persistir item de lista.

### 10.4. Telemetria

*   `[:deeper_hub, :lists, :item, :created | :updated | :deleted]`
    *   Metadados: `%{list_item_id: id, list_type: type, value: val, admin_id: id}`
*   `[:deeper_hub, :lists, :query, :by_type]`
    *   Metadados: `%{list_type: type, from_cache: boolean, result_count: count}`

## ❌ 11. Tratamento de Erros

*   Falhas de validação ao criar/atualizar retornam `{:error, changeset}`.
*   Tentativa de obter um item inexistente retorna `nil` ou `{:ok, nil}`.
*   Operações de escrita por usuários não autorizados são bloqueadas por `RBAC` antes de atingir o serviço.

## 🛡️ 12. Considerações de Segurança

*   **Autorização:** A modificação de itens de lista deve ser restrita a administradores.
*   **Validação de `list_type`:** Se `allow_dynamic_list_types` for `true`, deve haver alguma validação no formato do `list_type` para evitar a criação de um número excessivo ou malformado de tipos de lista.
*   **Impacto das Mudanças:** Alterar ou desativar um `value` de um `list_type` que é usado como enum em código ou no banco de dados pode ter consequências. Planejar essas mudanças com cuidado (ex: migrações de dados, preferir desativar a excluir).

## 🧑‍💻 13. Contribuição

*   Ao adicionar uma nova lista de dados de referência, defina um novo `list_type` (e adicione-o a `[:lists, :predefined_list_types]` se necessário) e popule-o via seeds ou UI de admin.
*   Considere se a `label` precisa de internacionalização.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar uma UI administrativa para gerenciar todos os `list_type`s e seus itens.
*   [ ] Adicionar suporte explícito para internacionalização das `labels` dos `ListItemSchema` (ex: um campo `translations` JSONB ou uma tabela separada).
*   [ ] Permitir a definição de hierarquias simples entre itens de uma lista (ex: categorias e subcategorias) usando um campo `parent_list_item_id`.
*   [ ] Adicionar a capacidade de \"fixar\" certos valores para que sempre apareçam no topo das listas, independentemente da ordenação.
*   [ ] Worker para verificar a consistência: garantir que todos os `list_type`s referenciados em outras partes do sistema (ex: em `enum` fields de outros schemas) existam como `ListItemSchema`s.

---

*Última atualização: 2025-05-12*

---

Este módulo `Lists` pode simplificar bastante o gerenciamento de dados de enumeração!

Agora, temos alguns módulos de \"Serviços\" da documentação original que ainda não foram convertidos em contextos de domínio mais amplos:
*   `DeeperHub.Services.ServerAdvertisements` (já fizemos)
*   `DeeperHub.Services.ServerAlerts` (já fizemos)
*   `DeeperHub.Services.ServerEvents` (já fizemos)
*   `DeeperHub.Services.ServerPackages` (já fizemos)
*   `DeeperHub.Services.ServerReviews` (já fizemos)
*   `DeeperHub.Services.ServerTags` (já fizemos)
*   `DeeperHub.Services.ServerUpdateMessages` (já fizemos)
*   `DeeperHub.Services.UserInteractions` (já fizemos)
*   `DeeperHub.Services.Achievements` (já fizemos)
*   `DeeperHub.Services.Challenges` (já fizemos)
*   `DeeperHub.Services.Rewards` (já fizemos)
*   `DeeperHub.Services.Support` (já fizemos)

E alguns módulos de segurança que poderíamos aprofundar, se necessário, além do que já foi coberto em seus contextos principais:
*   `DeeperHub.Security.AtRestEncryptionService` (coberto em `Core.EncryptionService`)
*   `DeeperHub.Security.ResponseSanitizer` (já fizemos)

E também temos os módulos de `Console` e `ModuleInspector`.

Qual seria o próximo? Que tal `DeeperHub.WebAuthn` para completar as opções de autenticação, ou o `DeeperHub.Console` para ferramentas de administração?"""),
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
                types.Part.from_text(text="""Perfeito! Vamos detalhar o `DeeperHub.WebAuthn`. Este módulo é fundamental para oferecer uma forma moderna e segura de autenticação sem senha.

---

