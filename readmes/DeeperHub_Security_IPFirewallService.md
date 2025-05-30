# Módulo: `DeeperHub.Security.IPFirewallService` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Security.IPFirewallService`

O módulo `DeeperHub.Security.IPFirewallService` é responsável por gerenciar e aplicar regras de firewall baseadas em endereços IP para o sistema DeeperHub. Ele permite a criação de listas de permissão (allowlists) e listas de bloqueio (blocklists) de IPs, controlando quais endereços podem ou não acessar a aplicação ou partes dela.

Este serviço é crucial para mitigar ameaças como tráfego malicioso conhecido, ataques de bots, e para restringir o acesso a recursos sensíveis apenas a redes confiáveis. Ele trabalha em conjunto com o `DeeperHub.Security.Cache.SecurityCache` para performance e com o `DeeperHub.Security.Policy.SecurityPolicyManager` para configurações. 😊

*(Nota: A documentação original mencionava `DeeperHub.Security.Config.IPFirewallConfig` e `DeeperHub.Security.Services.IpFirewallService` e `DeeperHub.Security.Plugs.IPFirewallPlug`. Esta documentação consolida a lógica de serviço em `IPFirewallService` e a configuração via `SecurityPolicyManager` ou `Core.ConfigManager`.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Gerenciamento de Listas de Bloqueio (Blocklists):**
    *   Permitir o bloqueio de endereços IP específicos ou ranges CIDR (`block_ip/4`).
    *   Suportar bloqueios temporários (com expiração) e permanentes.
    *   Manter um registro do motivo e da origem do bloqueio.
*   **Gerenciamento de Listas de Permissão (Allowlists/Whitelists):**
    *   Permitir a adição de IPs ou ranges CIDR que sempre terão acesso, mesmo que outras regras os bloqueiem (`allow_ip/4`).
    *   Suportar permissões temporárias e permanentes.
*   **Verificação de IP:**
    *   Verificar se um determinado endereço IP está bloqueado (`is_blocked?/1`).
    *   Verificar se um determinado endereço IP está explicitamente permitido (`is_allowed?/1`).
*   **Aplicação de Regras:**
    *   Fornecer uma interface para que Plugs (como `IPFirewallPlug`) ou outros módulos verifiquem o status de um IP e tomem ações (permitir/negar acesso).
    *   A lógica de precedência (ex: allowlist sobrepõe blocklist) deve ser clara.
*   **Limpeza de Entradas Expiradas:**
    *   Remover automaticamente bloqueios e permissões temporárias que expiraram (pode ser via TTL do cache ou um worker de limpeza).
*   **Integração com Cache:**
    *   Utilizar `DeeperHub.Security.Cache.SecurityCache` para armazenar listas de bloqueio/permissão para acesso rápido e eficiente.
*   **Configurabilidade:**
    *   Carregar listas iniciais de IPs bloqueados/permitidos de arquivos de configuração ou do `SecurityPolicyManager`.
    *   Configurar durações padrão para bloqueios/permissões temporárias.
*   **Observabilidade:**
    *   Registrar métricas sobre o número de IPs bloqueados/permitidos, e o número de requisições bloqueadas/permitidas pelo firewall.
    *   Logar ações de bloqueio, permissão e verificações significativas.
*   **Auditoria:**
    *   Integrar com `DeeperHub.Audit` para registrar quem adicionou/removeu IPs das listas e por quê.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Security.IPFirewallService` (Fachada/Serviço Principal):**
    *   **Responsabilidade:** Ponto de entrada para todas as operações de gerenciamento de firewall de IP. Contém a lógica de negócio principal.
    *   **Interações:**
        *   `DeeperHub.Security.Cache.SecurityCache`: Para ler e escrever o status de bloqueio/permissão de IPs.
        *   `DeeperHub.Core.Repo` (via `DeeperHub.Security.Schema.IPBlock` e `IPAllow`): Para persistir bloqueios/permissões permanentes ou para recuperação do cache após reinício.
        *   `DeeperHub.Security.Policy.SecurityPolicyManager` ou `Core.ConfigManager`: Para obter configurações como durações padrão, listas iniciais.
        *   `DeeperHub.Audit`: Para registrar modificações nas listas.
        *   `DeeperHub.Core.EventBus` (opcional): Para publicar eventos sobre IPs bloqueados/desbloqueados.
2.  **`DeeperHub.Security.Cache.SecurityCache`:**
    *   **Responsabilidade:** Armazenar em cache (provavelmente ETS) os IPs bloqueados e permitidos com seus TTLs para verificação de alta performance. As chaves podem ser prefixadas (ex: `\"ip_firewall:blocked:<ip_address>\"`).
3.  **`DeeperHub.Security.Schema.IPBlock` e `DeeperHub.Security.Schema.IPAllow` (Ecto Schemas):**
    *   **Responsabilidade:** Definem a estrutura para persistir bloqueios e permissões permanentes ou de longa duração no banco de dados.
4.  **`DeeperHub.Security.Plugs.IPFirewallPlug` (Phoenix Plug):**
    *   **Responsabilidade:** Integrar com o pipeline de requisições web para verificar cada requisição recebida contra o `IPFirewallService`.
    *   **Interações:** Chama `IPFirewallService.is_blocked?/1` e `is_allowed?/1`.
5.  **Configurações (via `Core.ConfigManager` / `SecurityPolicyManager`):**
    *   Listas de IPs permanentemente bloqueados/permitidos.
    *   Duração padrão para bloqueios/permissões temporárias.
    *   Intervalo de limpeza do cache (se não for puramente baseado em TTL).

### 3.2. Estrutura de Diretórios (Proposta)

Dentro de `security/`:
```
├── ip_firewall_service.ex            # Lógica de Serviço Principal (pode ser GenServer para tarefas como carregar do DB para ETS)
│
├── config/                           # (Onde IPFirewallConfig residia)
│   └── (As funções de config agora seriam parte do SecurityPolicyManager ou Core.ConfigManager)
│
├── schemas/                          # (Pode estar em um diretório de schemas de segurança global)
│   ├── ip_block.ex
│   └── ip_allow.ex
│
└── plugs/                            # (Se o Plug for específico deste módulo e não em _web)
    └── ip_firewall_plug.ex
```
O `SecurityCache` já está em `security/cache/`.

### 3.3. Decisões de Design Importantes

*   **Performance da Verificação:** A verificação `is_blocked?/is_allowed?` deve ser extremamente rápida, pois será chamada em cada requisição. Daí a importância do cache em memória (ETS).
*   **Persistência vs. Cache:**
    *   Bloqueios/permissões temporários (ex: por algumas horas) podem residir apenas no cache ETS com TTL.
    *   Bloqueios/permissões permanentes ou de longa duração devem ser persistidos no banco de dados e carregados no cache ETS na inicialização ou sob demanda.
*   **Granularidade:** Suporte para IPs individuais e ranges CIDR.
*   **Precedência:** Definir claramente a ordem de verificação (ex: Allowlist tem precedência sobre Blocklist).
*   **Gerenciamento:** Deve haver uma forma (API, Console) para administradores gerenciarem as listas.

## 🛠️ 4. Casos de Uso Principais

*   **Requisição de IP Bloqueado:**
    *   `IPFirewallPlug` intercepta uma requisição.
    *   Chama `IPFirewallService.is_blocked?(\"1.2.3.4\")`.
    *   Serviço verifica no cache. Se bloqueado, o Plug retorna uma resposta 403 Forbidden.
*   **Administrador Bloqueia um IP Permanentemente:**
    *   Admin usa o `DeeperHub.Console` ou UI para bloquear um IP.
    *   Chama `IPFirewallService.block_ip(\"5.6.7.8\", \"Fonte de ataque conhecido\", nil, %{admin_id: \"admin1\"})`.
    *   Serviço persiste no DB, atualiza o cache e audita a ação.
*   **Serviço de Detecção de Intrusão Bloqueia IP Temporariamente:**
    *   `DeeperHub.Security.IntrusionDetection` detecta atividade suspeita.
    *   Chama `IPFirewallService.block_ip(\"9.10.11.12\", \"Múltiplas tentativas de SQLi\", 3600)`.
    *   Serviço adiciona ao cache com TTL de 1 hora.
*   **Adicionar Rede Corporativa à Allowlist:**
    *   Admin configura `IPFirewallService.allow_ip(\"192.168.1.0/24\", \"Rede Interna\", nil)`.
    *   Requisições dessa rede bypassarão outras verificações de blocklist.

## 🌊 5. Fluxos Importantes

### Fluxo de Verificação de IP pelo `IPFirewallPlug`

1.  **Requisição Entra:** Chega uma nova requisição HTTP.
2.  **`IPFirewallPlug.call/2`:**
    *   Extrai o IP do cliente da `conn`.
    *   Chama `DeeperHub.Security.IPFirewallService.is_allowed?(client_ip)`.
    *   **Se Permitido (`true`):** A requisição prossegue no pipeline.
    *   **Se Não Permitido ou Erro:** Chama `DeeperHub.Security.IPFirewallService.is_blocked?(client_ip)`.
        *   **Se Bloqueado (`true`):**
            *   Loga a tentativa de acesso bloqueada.
            *   Incrementa métrica `requests_blocked_by_firewall`.
            *   Retorna uma resposta `403 Forbidden` e interrompe (`halt`) a `conn`.
        *   **Se Não Bloqueado ou Erro na Verificação de Bloqueio:** A requisição prossegue (ou trata o erro de verificação como um \"permitir com aviso\").
3.  **Requisição Prossegue:** Se não bloqueado/explicitamente permitido, continua para os próximos plugs.

### Fluxo de Bloqueio de IP (Permanente)

1.  **Solicitação de Bloqueio:** Administrador chama `IPFirewallService.block_ip(ip, reason, nil, metadata)`.
2.  **`IPFirewallService`:**
    *   Valida o formato do IP e os parâmetros.
    *   Cria/Atualiza um registro `IPBlock` no banco de dados (via `Core.Repo`).
    *   Se a persistência for bem-sucedida:
        *   Atualiza o `SecurityCache` adicionando o IP à lista de bloqueados (sem TTL se o bloqueio for permanente).
        *   Registra a ação no `DeeperHub.Audit`.
        *   (Opcional) Publica um evento `ip_blocked` no `Core.EventBus`.
    *   Retorna `{:ok, block_info}` ou `{:error, reason}`.

## 📡 6. API (Funções Públicas do Módulo)

### 6.1. `DeeperHub.Security.IPFirewallService.is_blocked?(ip_address :: String.t()) :: boolean()`

*   **Descrição:** Verifica se um IP está atualmente na blocklist (considerando TTLs de bloqueios temporários).
*   **Retorno:** `true` se bloqueado, `false` caso contrário.

### 6.2. `DeeperHub.Security.IPFirewallService.is_allowed?(ip_address :: String.t()) :: boolean()`

*   **Descrição:** Verifica se um IP está atualmente na allowlist (considerando TTLs).

### 6.3. `DeeperHub.Security.IPFirewallService.block_ip(ip_address :: String.t(), reason :: String.t(), duration_seconds :: integer() | nil, metadata :: map() | nil) :: {:ok, IPBlock.t()} | {:error, Ecto.Changeset.t() | term()}`

*   **Descrição:** Adiciona um IP à blocklist.
*   **`duration_seconds`:** `nil` para permanente, ou número de segundos para bloqueio temporário.
*   **`metadata`:** Ex: `%{blocked_by: \"admin_user_id\", ticket_ref: \"SUP-123\"}`.
*   **Retorno:** Struct `IPBlock` salva ou erro.

### 6.4. `DeeperHub.Security.IPFirewallService.allow_ip(ip_address :: String.t(), reason :: String.t(), duration_seconds :: integer() | nil, metadata :: map() | nil) :: {:ok, IPAllow.t()} | {:error, Ecto.Changeset.t() | term()}`

*   **Descrição:** Adiciona um IP à allowlist.
*   **Retorno:** Struct `IPAllow` salva ou erro.

### 6.5. `DeeperHub.Security.IPFirewallService.unblock_ip(ip_address :: String.t(), metadata :: map() | nil) :: :ok | {:error, :not_found | term()}`

*   **Descrição:** Remove um IP da blocklist (e do cache).
*   **`metadata`:** Ex: `%{unblocked_by: \"admin_user_id\"}`.

### 6.6. `DeeperHub.Security.IPFirewallService.disallow_ip(ip_address :: String.t(), metadata :: map() | nil) :: :ok | {:error, :not_found | term()}`

*   **Descrição:** Remove um IP da allowlist (e do cache).

### 6.7. `DeeperHub.Security.IPFirewallService.list_blocked_ips(opts :: keyword()) :: {:ok, list(IPBlock.t())}`

*   **Descrição:** Lista IPs bloqueados (primariamente do banco de dados para gerenciamento).
*   **`opts`:** `:include_expired` (boolean), `:limit`, `:offset`.

### 6.8. `DeeperHub.Security.IPFirewallService.list_allowed_ips(opts :: keyword()) :: {:ok, list(IPAllow.t())}`

*   **Descrição:** Lista IPs permitidos.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager` e/ou `DeeperHub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :ip_firewall, :enabled]`** (Boolean): Habilita/desabilita o firewall de IP. (Padrão: `true`)
*   **`[:security, :ip_firewall, :default_block_duration_seconds]`** (Integer): Duração padrão para bloqueios temporários. (Padrão: `3600` - 1 hora)
*   **`[:security, :ip_firewall, :default_allow_duration_seconds]`** (Integer): Duração padrão para permissões temporárias.
*   **`[:security, :ip_firewall, :permanent_blocked_ips]`** (List de Strings/CIDR): Lista de IPs/ranges permanentemente bloqueados carregados na inicialização.
*   **`[:security, :ip_firewall, :permanent_allowed_ips]`** (List de Strings/CIDR): Lista de IPs/ranges permanentemente permitidos.
*   **`[:security, :ip_firewall, :cache_load_on_startup]`** (Boolean): Se deve carregar as listas permanentes do DB para o cache ETS na inicialização. (Padrão: `true`)
*   **`[:security, :ip_firewall, :cleanup_interval_minutes]`** (Integer): Intervalo para o worker que remove entradas expiradas do *banco de dados* (o cache ETS lida com seus próprios TTLs). (Padrão: `1440` - 24 horas)
*   **`[:security, :ip_firewall, :plug, :mode]`** (Atom): Modo de operação do `IPFirewallPlug` (`:enforce` ou `:monitor`). (Padrão: `:enforce`)
*   **`[:security, :ip_firewall, :plug, :whitelist_paths]`** (List de Strings/Regex): Caminhos que devem ignorar a verificação do firewall.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`, `Core.Logger`, `Core.Metrics`, `Core.Repo`.
*   `DeeperHub.Security.Cache.SecurityCache`: Para caching de IPs.
*   `DeeperHub.Security.Policy.SecurityPolicyManager`: Para obter políticas.
*   `DeeperHub.Audit`: Para registrar alterações.
*   `DeeperHub.Shared.Utils.ValidationUtils` (ou similar): Para validar formatos de IP/CIDR.

### 8.2. Bibliotecas Externas

*   `Ecto`: Para persistência de regras permanentes.
*   Pode usar bibliotecas para coordenação de CIDR se não for feito manualmente.

## 🤝 9. Como Usar / Integração

*   **Plug no Pipeline Phoenix:**
    ```elixir
    # Em lib/deeper_hub_web/router.ex
    pipeline :api do
      plug DeeperHub.Security.Plugs.IPFirewallPlug, mode: :enforce # ou :monitor
      # ... outros plugs ...
    end
    ```
*   **Verificação Programática:**
    ```elixir
    if DeeperHub.Security.IPFirewallService.is_blocked?(client_ip) do
      # Lógica para lidar com IP bloqueado
    end
    ```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar bloqueio e permissão de IPs/CIDRs (temporários e permanentes).
*   Testar a lógica de expiração de entradas no cache e (se aplicável) no DB.
*   Testar a precedência (allowlist > blocklist).
*   Testar o `IPFirewallPlug` em modo `:enforce` e `:monitor`.
*   Testar a carga de listas iniciais.
*   Localização: `test/deeper_hub/security/ip_firewall_service/`.

### 10.2. Métricas

*   `deeper_hub.security.ip_firewall.requests_checked.count`
*   `deeper_hub.security.ip_firewall.requests_blocked.count` (tags: `reason`)
*   `deeper_hub.security.ip_firewall.requests_allowed_by_whitelist.count`
*   `deeper_hub.security.ip_firewall.blocked_ips.gauge` (Gauge): Número de IPs atualmente na blocklist (cache).
*   `deeper_hub.security.ip_firewall.allowed_ips.gauge` (Gauge): Número de IPs atualmente na allowlist (cache).
*   `deeper_hub.security.ip_firewall.db_cleanup.items_removed.count`

### 10.3. Logs

*   **Nível INFO:** IP adicionado/removido da allowlist/blocklist (com motivo e quem fez).
*   **Nível WARNING:** Requisição bloqueada pelo firewall (com IP e path).
*   **Nível ERROR:** Falha ao persistir/remover regra no banco de dados. Erro ao carregar listas iniciais.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :ip_firewall, :ip_check]`
    *   Metadados: `%{ip_address: ip, result: :allowed | :blocked | :whitelisted, path: path}`
*   `[:deeper_hub, :security, :ip_firewall, :list_modified]`
    *   Metadados: `%{list_type: :blocklist | :allowlist, action: :added | :removed, ip_address: ip, reason: reason, duration_seconds: dur, admin_id: id}`

## ❌ 11. Tratamento de Erros

*   **Falha no Cache:** Se o `SecurityCache` estiver indisponível, o serviço pode tentar consultar o banco de dados diretamente para regras permanentes, mas isso terá impacto na performance. Deve logar criticamente.
*   **Falha no Banco de Dados:** Falhas ao persistir regras permanentes devem ser logadas e, possivelmente, tentar novamente. A operação no cache pode ser feita de forma otimista.

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Autorização para Modificar Listas:** As funções `block_ip`, `allow_ip`, etc., devem ser protegidas e só acessíveis por administradores ou sistemas automatizados autorizados (ex: IDS).
*   **Prevenção de Auto-Bloqueio:** Cuidado para não bloquear IPs de sistemas essenciais ou de administradores, a menos que intencional. A allowlist pode ajudar aqui.
*   **Tamanho das Listas:** Listas de bloqueio/permissão muito grandes podem impactar a performance da inicialização e do cache, mesmo com ETS. Considere limites ou estratégias de paginação para gerenciamento.

## 🧑‍💻 13. Contribuição

*   Ao adicionar novas fontes de IPs para bloqueio/permissão (ex: feeds de threat intelligence), integre-as de forma que atualizem o `IPFirewallService`.
*   Garanta que os motivos para bloqueio/permissão sejam claros e auditáveis.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Suporte para regras de firewall mais complexas (ex: por país, ASN, não apenas IP). Isso começaria a sobrepor com WAFs.
*   [ ] Integração com feeds de reputação de IP externos para popular dinamicamente a blocklist.
*   [ ] UI administrativa para gerenciamento fácil das listas de IP.
*   [ ] Permitir que as políticas de `SecurityPolicyManager` definam diferentes perfis de firewall (ex: \"agressivo\", \"moderado\") que ajustam automaticamente durações e limiares.
*   [ ] Adicionar um modo \"monitor\" mais granular, que loga o que *seria* bloqueado mas ainda permite a requisição (além do plug global).

---

*Última atualização: 2025-05-11*

---

Este cobre o Firewall de IP! Agora, o `DeeperHub.Security.Policy.SecurityPolicyManager` que acabamos de referenciar bastante seria um bom próximo passo para ver como essas configurações são gerenciadas, ou prefere focar em outro aspecto da segurança como `DDoSProtection` ou `CSRFProtection`?"""),
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
                types.Part.from_text(text="""Ok, já detalhamos o `DeeperHub.Security.Policy.SecurityPolicyManager`.

Dado que já cobrimos vários componentes de segurança importantes (`FraudDetection`, `BruteForceProtection`, `IPFirewallService`, `DeviceFingerprint`, `GeoLocationService`, `BehavioralAnalysis`, `RiskAssessment`, `SecurityPolicyManager`), podemos agora focar em outras camadas de proteção que são comuns em aplicações web.

Vamos detalhar o `DeeperHub.Security.CsrfProtection`.

---

