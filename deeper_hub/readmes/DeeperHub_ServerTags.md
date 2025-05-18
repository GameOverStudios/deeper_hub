# Módulo: `DeeperHub.ServerTags` 🏷️

## 📜 1. Visão Geral do Módulo `DeeperHub.ServerTags`

O módulo `DeeperHub.ServerTags` é responsável por gerenciar o sistema de tags (etiquetas) associadas aos servidores dentro da plataforma DeeperHub. As tags permitem categorizar e descrever servidores com palavras-chave, facilitando a descoberta, filtragem e organização dos servidores pelos usuários. Este módulo lida com a criação, atribuição e consulta de tags. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Gerenciamento de Definições de Tags (Opcional, pode ser via `DeeperHub.Lists`):**
    *   Se as tags forem um conjunto pré-definido ou curado, este módulo (ou `DeeperHub.Lists`) pode gerenciar o CRUD para as definições de tags (nome, descrição, categoria da tag).
    *   Se as tags forem \"folksonômicas\" (criadas livremente pelos usuários), o foco é na associação.
*   **Associação de Tags a Servidores:**
    *   Permitir que proprietários de servidores (ou administradores) associem tags relevantes aos seus servidores.
    *   Permitir a remoção de tags de um servidor.
*   **Listagem e Consulta de Tags:**
    *   Listar todas as tags associadas a um servidor específico.
    *   Listar todos os servidores associados a uma ou mais tags específicas.
    *   Sugerir tags populares ou relevantes durante a criação/edição de um servidor.
    *   Contar a popularidade das tags (quantos servidores usam cada tag).
*   **Validação e Moderação (Opcional):**
    *   Validar tags (ex: comprimento, caracteres permitidos).
    *   Moderar tags criadas por usuários para remover conteúdo inadequado ou spam.
*   **Busca por Tags:**
    *   Permitir que usuários busquem servidores utilizando tags como critério de filtro.

## 🏗️ 3. Arquitetura e Design

`DeeperHub.ServerTags` atuará como uma fachada para um serviço de lógica de negócio e componentes de persistência.

*   **Interface Pública (`DeeperHub.ServerTags.ServerTagsFacade` ou `DeeperHub.ServerTags`):** Funções como `add_tag_to_server/2`, `list_tags_for_server/1`, `list_servers_by_tag/1`.
*   **Serviço de Tags de Servidor (`DeeperHub.ServerTags.Services.TagService`):**
    *   Contém a lógica de negócio principal para associar tags a servidores, criar novas tags (se permitido), e consultar tags.
*   **Schemas Ecto:**
    *   `DeeperHub.ServerTags.Schema.Tag`: Define uma tag global (se as tags forem gerenciadas centralmente, como em `DeeperHub.Lists`). Campos: `id`, `name`, `slug`, `description`, `category`.
    *   `DeeperHub.ServerTags.Schema.ServerTagLink` (ou `ServerHasTag`): Tabela de junção para a relação muitos-para-muitos entre Servidores e Tags. Campos: `server_id`, `tag_id`.
    *   Alternativamente, se as tags forem simples strings diretamente no schema do Servidor (ex: um campo `tags :: {:array, :string}`), este módulo ainda assim gerenciaria a lógica de busca e sugestão. No entanto, ter uma entidade `Tag` separada é mais flexível.
*   **Cache (`DeeperHub.ServerTags.Cache` ou via `Core.Cache`):**
    *   Cache para tags populares ou tags frequentemente associadas a servidores.
*   **Integrações:**
    *   `DeeperHub.Core.Repo`: Para persistência.
    *   `DeeperHub.Servers`: Para associar tags a servidores e buscar servidores por tag.
    *   `DeeperHub.Accounts`: Para permissões de quem pode adicionar/remover tags.
    *   `DeeperHub.Lists` (Potencial): Se as definições de tag forem gerenciadas como um tipo de lista.

**Padrões de Design:**

*   **Fachada (Facade).**
*   **Serviço de Domínio.**

### 3.1. Componentes Principais

*   **`DeeperHub.ServerTags.ServerTagsFacade`:** Ponto de entrada.
*   **`DeeperHub.ServerTags.Services.TagService`:** Lógica de negócio.
*   **`DeeperHub.ServerTags.Schema.Tag`:** Schema da tag (se for uma entidade).
*   **`DeeperHub.ServerTags.Schema.ServerTagLink`:** Schema da associação.
*   **`DeeperHub.ServerTags.Supervisor`:** Supervisiona processos.

### 3.3. Decisões de Design Importantes

*   **Modelo de Tags:**
    *   **Tags Centralizadas/Curadas:** Tags são definidas por administradores (possivelmente usando `DeeperHub.Lists`), e proprietários de servidores escolhem a partir dessa lista. Vantagem: consistência, controle.
    *   **Folksonomia (Tags Livres):** Proprietários de servidores podem criar qualquer tag. Vantagem: flexibilidade, descoberta orgânica. Desvantagem: pode levar a inconsistências (ex: \"rpg\", \"role-playing-game\") e necessidade de moderação.
    *   **Híbrido:** Permitir tags livres mas com sugestões de tags existentes/populares e moderação.
*   **Armazenamento:** Se tags são entidades separadas com uma tabela de junção, ou um array de strings no schema do servidor. Entidades separadas são mais robustas para busca e gerenciamento.

## 🛠️ 4. Casos de Uso Principais

*   **Proprietário de Servidor Adiciona Tags:** Ao configurar seu servidor, o proprietário adiciona tags como \"RPG\", \"PvP\", \"Comunidade Amigável\".
*   **Usuário Filtra Servidores por Tag:** Um usuário busca por servidores e aplica o filtro \"RPG\" para ver apenas servidores com essa tag.
*   **Sistema Sugere Tags:** Ao criar um servidor, o sistema sugere tags populares ou relevantes com base na descrição do servidor.
*   **Administrador Modera Tags:** Um admin remove uma tag inadequada ou mescla tags duplicadas (ex: \"RPG\" e \"RolePlaying\").

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Adicionar uma Tag a um Servidor (com tags centralizadas):**

1.  Proprietário do servidor, através da UI/API, seleciona a tag \"RPG\" para adicionar ao seu servidor \"Mundo Fantástico\".
2.  `DeeperHub.API` (Controller) chama `DeeperHub.ServerTags.add_tag_to_server(server_id, \"RPG\")`.
3.  `ServerTagsFacade` delega para `DeeperHub.ServerTags.Services.TagService.add_tag/2`.
4.  `TagService`:
    *   Verifica se o usuário tem permissão para modificar as tags do servidor.
    *   Busca a tag \"RPG\" no `DeeperHub.Lists` (ou no `Schema.Tag` próprio). Se não existir e o sistema permitir criação dinâmica por usuários autorizados, cria a tag.
    *   Verifica se a associação entre \"Mundo Fantástico\" e \"RPG\" já existe na tabela `ServerTagLink`.
    *   Se não existir, cria um novo registro `ServerTagLink` e o persiste via `Core.Repo`.
    *   Invalida caches relevantes (ex: cache de tags do servidor \"Mundo Fantástico\").
    *   Publica um evento `ServerTagAddedEvent` no `Core.EventBus`.
5.  Retorna `{:ok, updated_server_tags_list}`.

## 📡 6. API (Se Aplicável)

### 6.1. `DeeperHub.ServerTags.add_tag_to_server/3`

*   **Descrição:** Associa uma tag a um servidor. Se a tag não existir e o sistema permitir, ela pode ser criada.
*   **`@spec`:** `add_tag_to_server(server_id :: String.t(), tag_name :: String.t(), opts :: Keyword.t()) :: {:ok, Tag.t() | list(Tag.t())} | {:error, reason}`
*   **Parâmetros:**
    *   `server_id` (String): O ID do servidor.
    *   `tag_name` (String): O nome da tag a ser adicionada (ex: \"RPG\", \"Minecraft\").
    *   `opts` (Keyword.t()): Opções adicionais.
        *   `created_by_user_id` (String): ID do usuário realizando a ação (para auditoria/permissão).
*   **Retorno:**
    *   `{:ok, tag_struct}`: Se uma nova tag foi criada e associada.
    *   `{:ok, list_of_tags_for_server}`: Retorna a lista atualizada de tags do servidor.
    *   `{:error, :server_not_found | :tag_creation_failed | :association_failed | :unauthorized | reason}`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    case DeeperHub.ServerTags.add_tag_to_server(\"server_123\", \"PvP Focused\", created_by_user_id: current_user.id) do
      {:ok, _updated_tags} -> Logger.info(\"Tag 'PvP Focused' adicionada ao servidor server_123.\")
      {:error, reason} -> Logger.error(\"Falha ao adicionar tag: #{inspect(reason)}\")
    end
    ```

### 6.2. `DeeperHub.ServerTags.list_tags_for_server/1`

*   **Descrição:** Lista todas as tags associadas a um servidor específico.
*   **`@spec`:** `list_tags_for_server(server_id :: String.t()) :: {:ok, list(Tag.t() | String.t())} | {:error, reason}`
    *   O retorno pode ser `list(Tag.t())` se tags forem entidades ou `list(String.t())` se forem apenas strings.
*   **Parâmetros:**
    *   `server_id` (String): O ID do servidor.
*   **Retorno:** Lista de tags associadas ao servidor.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    {:ok, server_tags} = DeeperHub.ServerTags.list_tags_for_server(\"server_123\")
    # server_tags => [%Tag{name: \"RPG\"}, %Tag{name: \"PvP Focused\"}]
    ```

### 6.3. `DeeperHub.ServerTags.list_servers_by_tag/2`

*   **Descrição:** Lista todos os servidores que possuem uma tag específica.
*   **`@spec`:** `list_servers_by_tag(tag_name :: String.t(), opts :: Keyword.t()) :: {:ok, list(Server.t())} | {:error, reason}`
*   **Parâmetros:**
    *   `tag_name` (String): O nome da tag.
    *   `opts` (Keyword.t()): Opções de paginação e ordenação.
*   **Retorno:** Lista de servidores que possuem a tag.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    {:ok, rpg_servers} = DeeperHub.ServerTags.list_servers_by_tag(\"RPG\", limit: 10)
    ```

*(Outras funções como `remove_tag_from_server/3`, `suggest_tags/1`, `list_popular_tags/1` seriam documentadas aqui).*

## ⚙️ 7. Configuração

*   **ConfigManager (`DeeperHub.Core.ConfigManager`):**
    *   `[:server_tags, :max_tags_per_server]`: Número máximo de tags que um servidor pode ter. (Padrão: `10`)
    *   `[:server_tags, :allow_user_created_tags]`: (Boolean) Se os usuários podem criar novas tags livremente ou devem escolher de uma lista predefinida. (Padrão: `true`)
    *   `[:server_tags, :moderation_required_for_new_tags]`: (Boolean) Se novas tags criadas por usuários requerem aprovação de admin. (Padrão: `false`)
    *   `[:server_tags, :tag_name_max_length]`: Comprimento máximo para o nome de uma tag. (Padrão: `50`)
    *   `[:server_tags, :tag_name_regex_validation]`: Regex para validar caracteres permitidos em nomes de tag.
    *   `[:server_tags, :cache_ttl_popular_tags_seconds]`: TTL para cache de tags populares.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.Repo`
*   `DeeperHub.Core.ConfigManager`
*   `DeeperHub.Core.Cache` (Opcional)
*   `DeeperHub.Servers` (para associação e busca)
*   `DeeperHub.Accounts` (para permissões)
*   `DeeperHub.Lists` (Se as definições de tags forem gerenciadas lá)
*   `DeeperHub.Core.Logger`, `DeeperHub.Core.Metrics`

### 8.2. Bibliotecas Externas

*   `Ecto`

## 🤝 9. Como Usar / Integração

*   **Módulo `Servers`:** Ao criar/editar um servidor, permite ao proprietário adicionar ou remover tags usando `ServerTags.add_tag_to_server/3` e `ServerTags.remove_tag_from_server/3`.
*   **Sistema de Busca:** Utiliza `ServerTags.list_servers_by_tag/2` para filtrar resultados de busca de servidores.
*   **UI:** Exibe tags na página de detalhes do servidor e permite clicar em tags para ver outros servidores com a mesma tag.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar a adição e remoção de tags de um servidor.
*   Testar a criação de novas tags (se permitido).
*   Testar a listagem de tags por servidor e de servidores por tag.
*   Testar validações de nome de tag e limites.
*   Localização: `test/deeper_hub/server_tags/`

### 10.2. Métricas

*   `deeper_hub.server_tags.tag.added_to_server.count` (Contador): Tags: `server_id`, `tag_name`.
*   `deeper_hub.server_tags.tag.removed_from_server.count` (Contador): Tags: `server_id`, `tag_name`.
*   `deeper_hub.server_tags.tag.created.count` (Contador): (Se usuários podem criar tags) Tags: `tag_name`.
*   `deeper_hub.server_tags.servers_by_tag_query.duration_ms` (Histograma): Tags: `tag_name`.

### 10.3. Logs

*   `Logger.info(\"Tag '#{tag_name}' adicionada ao servidor #{server_id} por user_id: #{uid}\", module: DeeperHub.ServerTags.Services.TagService)`
*   `Logger.warn(\"Tentativa de adicionar tag inválida '#{tag_name}' ao servidor #{server_id}\", module: DeeperHub.ServerTags.Services.TagService)`

### 10.4. Telemetria

*   `[:deeper_hub, :server_tags, :tag_added_to_server]`
*   `[:deeper_hub, :server_tags, :tag_removed_from_server]`
*   `[:deeper_hub, :server_tags, :tag_created]`

## ❌ 11. Tratamento de Erros

*   `{:error, :server_not_found}`
*   `{:error, :tag_not_found}` (se usando tags pré-definidas)
*   `{:error, :max_tags_reached}`
*   `{:error, :invalid_tag_name}`
*   `{:error, :unauthorized_action}`

## 🛡️ 12. Considerações de Segurança

*   **Validação de Nomes de Tag:** Se as tags são criadas por usuários, sanitizar e validar os nomes para prevenir XSS ou conteúdo ofensivo.
*   **Moderação:** Implementar um sistema de moderação se as tags forem geradas livremente para lidar com tags inapropriadas ou spam.
*   **Permissões:** Apenas usuários autorizados (donos de servidor, administradores) devem poder adicionar/remover tags.

## 🧑‍💻 13. Contribuição

*   Melhorar os algoritmos de sugestão de tags.
*   Integrar com sistemas de análise de texto para sugerir tags automaticamente com base na descrição do servidor.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Suporte para categorias de tags.
*   [ ] Permitir que usuários sigam tags para descobrir novos servidores.
*   [ ] Sistema de \"sinônimos\" de tags para agrupar tags semanticamente similares (ex: \"RPG\" e \"Role-playing\").
*   [ ] Interface de administração para gerenciar tags (mesclar, deletar, categorizar).
*   [ ] Ranking de popularidade de tags.

---

*Última atualização: YYYY-MM-DD*

---

Próximo é o `DeeperHub.ServerReviews`. Mesmo esquema: você já tem um, mas pediu um novo seguindo o padrão. Correto?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""Isso!!! Manda vê!"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Beleza! Vamos criar o README completo para `DeeperHub.ServerReviews`, que é uma parte crucial para a comunidade em torno dos servidores.

---

