# Módulo: `Deeper_Hub.Security.DdosProtection` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Security.DdosProtection`

O módulo `Deeper_Hub.Security.DdosProtection` é projetado para proteger o sistema Deeper_Hub contra ataques de **Negação de Serviço Distribuída (DDoS)** e ataques de Negação de Serviço (DoS) mais simples. O objetivo desses ataques é sobrecarregar os recursos do servidor (CPU, memória, largura de banda, conexões de banco de dados) com um volume massivo de tráfego ilegítimo, tornando a aplicação indisponível para usuários legítimos.

Este módulo implementa várias estratégias para mitigar esses ataques, incluindo:
1.  **Limitação de Taxa (Rate Limiting) Agressiva:** Aplicar limites de taxa mais rigorosos baseados em IP e, potencialmente, em outros identificadores, para tráfego geral ou para endpoints específicos durante um ataque percebido.
2.  **Bloqueio de IPs:** Identificar e bloquear IPs que participam de um ataque.
3.  **Detecção de Padrões de Ataque:** Analisar padrões de tráfego para identificar características de ataques DDoS (ex: floods SYN, HTTP floods).
4.  **Modos de Proteção Avançada:** Capacidade de alternar para um modo de proteção mais restritivo durante um ataque.
5.  **Integração com Serviços Externos de Mitigação DDoS (Opcional):** Facilitar a integração com serviços como Cloudflare, AWS Shield, etc.

O foco é manter a disponibilidade do Deeper_Hub mesmo sob condições de tráfego anormais ou maliciosas. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Monitoramento de Tráfego em Tempo Real:**
    *   Analisar o volume, a origem e a natureza das requisições recebidas (`record_request/3`).
    *   Identificar picos anormais de tráfego ou padrões de requisição suspeitos indicativos de um ataque.
*   **Limitação de Taxa Dinâmica e Global:**
    *   Aplicar limites de taxa globais para IPs individuais para mitigar ataques de força bruta distribuídos em pequena escala ou abuso.
    *   Permitir a configuração de limites de taxa específicos para endpoints críticos ou frequentemente visados (`configure_rate_limit/3`).
    *   Utilizar `Deeper_Hub.API.RateLimiterFacade` como mecanismo subjacente, mas aplicar políticas mais agressivas ou dinâmicas sob suspeita de DDoS.
*   **Detecção e Bloqueio de IPs Atacantes:**
    *   Identificar endereços IP que excedem significativamente os limites de taxa estabelecidos ou que participam de padrões de ataque conhecidos.
    *   Bloquear esses IPs temporária ou permanentemente, integrando-se com `Deeper_Hub.Security.IPFirewallService` (`block_ip/3`, `unblock_ip/1`).
*   **Análise de Padrões de Ataque (via `PatternAnalyzer`):**
    *   Implementar (ou integrar com ferramentas que implementam) detecção para tipos comuns de ataques DDoS no nível da aplicação (ex: HTTP GET/POST floods, ataques a formulários de login/registro).
    *   Analisar User-Agents, referers, e outros cabeçalhos para identificar tráfego de bots.
*   **Modo de Proteção Avançada/Sob Ataque (`set_advanced_protection/2`):**
    *   Permitir a ativação manual ou automática de um modo de \"sob ataque\" que aplica regras mais estritas:
        *   Limites de taxa muito mais baixos para todos os IPs ou para IPs não autenticados.
        *   Desafios de JavaScript ou CAPTCHA para novos visitantes ou tráfego suspeito.
        *   Bloqueio de faixas de IPs suspeitas, de ASNs conhecidos por originar ataques, ou de geografias específicas.
        *   Possível \"lista cinza\" de IPs que passam por verificações mais rigorosas.
*   **Relatórios e Estatísticas (`get_statistics/1`):**
    *   Fornecer estatísticas sobre o volume de tráfego total, tráfego por IP/path, requisições bloqueadas/limitadas por taxa, e IPs atualmente bloqueados por políticas de DDoS.
*   **Integração com Serviços Externos de Mitigação DDoS (Opcional):**
    *   API para reportar IPs atacantes a serviços como Cloudflare, Akamai, AWS Shield.
    *   API para receber e aplicar listas de bloqueio de IPs desses serviços.
*   **Configurabilidade das Políticas:**
    *   Políticas de limitação de taxa, limiares para detecção de ataque, duração e escalonamento de bloqueios devem ser configuráveis via `Deeper_Hub.Security.Policy.SecurityPolicyManager`.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`Deeper_Hub.Security.DdosProtection` (Fachada Pública):**
    *   Ponto de entrada para funcionalidades de proteção DDoS.
    *   Delega para `DdosProtectionService`.
2.  **`Deeper_Hub.Security.DdosProtection.Services.DdosProtectionService` (GenServer):**
    *   **Responsabilidade:** Processo central que monitora o tráfego, gerencia o estado de \"sob ataque\", aplica políticas dinâmicas de rate limiting e coordena o bloqueio de IPs.
    *   **Estado Interno (pode usar ETS para contadores de alta performance):**
        *   Contadores de requisições agregados (global, por path, por IP em períodos curtos).
        *   Estado atual do modo de proteção (normal, avançado/sob ataque).
        *   Limiares dinâmicos que podem ser ajustados.
    *   **Interações:**
        *   `Deeper_Hub.API.RateLimiterFacade` (ou um rate limiter interno específico para DDoS): Para a mecânica de contagem e limitação.
        *   `Deeper_Hub.Security.IPFirewallService`: Para efetuar o bloqueio/desbloqueio de IPs.
        *   `Deeper_Hub.Core.ConfigManager` / `SecurityPolicyManager`: Para obter políticas e limiares.
        *   `Deeper_Hub.Security.Monitoring`: Para registrar alertas de DDoS.
        *   `Deeper_Hub.Security.DdosProtection.PatternAnalyzer`: Para análises mais profundas.
3.  **`Deeper_Hub.Security.Plugs.DdosProtectionPlug` (Phoenix Plug):**
    *   **Responsabilidade:** Interceptar requisições HTTP muito cedo no pipeline.
    *   Registra a requisição (`DdosProtectionService.record_request/3`).
    *   Verifica se a requisição deve ser bloqueada ou limitada por taxa com base nas políticas de DDoS (`DdosProtectionService.check_request/3`).
    *   Deve ser posicionado após o `IPFirewallPlug` (para IPs já conhecidos como maus) mas antes de plugs mais custosos.
4.  **`Deeper_Hub.Security.DdosProtection.PatternAnalyzer` (Worker GenServer ou Módulo Funcional):**
    *   **Responsabilidade:** Analisar logs de tráfego ou um stream de eventos de requisição em background para identificar padrões de ataque mais sutis que a simples contagem de requisições por IP (ex: distribuição anômala de User-Agents, targeting de endpoints específicos por múltiplos IPs de forma coordenada).
    *   Pode usar regras ou modelos simples de ML.
5.  **Adaptadores para Serviços Externos de Mitigação (Opcional):**
    *   Módulos específicos para interagir com APIs de Cloudflare, AWS WAF/Shield, etc.

### 3.2. Estrutura de Diretórios (Proposta)

```
security/ddos_protection/
├── ddos_protection.ex                # Fachada Pública
│
├── services/
│   └── ddos_protection_service.ex    # GenServer principal com a lógica de DDoS
│
├── plug/                             # (Pode estar em deeper_hub_web/plugs)
│   └── ddos_protection_plug.ex
│
├── pattern_analyzer.ex               # Worker/Serviço para análise de padrões
│
├── external_mitigation/              # (Opcional) Adaptadores para serviços de terceiros
│   ├── cloudflare_adapter.ex
│   └── aws_shield_adapter.ex
│
├── supervisor.ex
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Performance é Chave:** O `DdosProtectionPlug` e as verificações iniciais no `DdosProtectionService` devem ser extremamente rápidos. Contadores em ETS são essenciais.
*   **Defesa em Camadas:** A proteção DDoS na aplicação é uma camada. Idealmente, há proteção na borda da rede (firewalls, provedor de hospedagem, CDN).
*   **Falsos Positivos:** Bloquear tráfego legítimo é um grande risco. O \"modo de proteção avançada\" deve ser ativado com cautela, e mecanismos para liberar IPs legítimos bloqueados erroneamente devem existir.
*   **Adaptabilidade:** Limiares e regras devem ser ajustáveis, possivelmente dinamicamente com base na carga observada ou em alertas.

## 🛠️ 4. Casos de Uso Principais

*   **HTTP GET Flood em `/search`:**
    *   Muitos IPs (ou um só) enviam um grande volume de GETs para `/search`.
    *   `DdosProtectionPlug` registra cada requisição.
    *   `DdosProtectionService` detecta que o limite de taxa para o path `/search` (ou para os IPs individuais) foi excedido.
    *   Os IPs atacantes são enviados para `IPFirewallService.block_ip/3`.
    *   O sistema pode entrar em \"modo avançado\", aplicando um desafio CAPTCHA para todas as requisições a `/search` de IPs não autenticados ou novos.
*   **Ataque de Login Distribuído (Credential Stuffing):**
    *   Muitos IPs diferentes tentam fazer login com credenciais variadas.
    *   `DdosProtectionService` pode não detectar por IP individual, mas o `PatternAnalyzer` (analisando logs de `BruteForceProtection` e tráfego de API) pode identificar um aumento anormal nas tentativas de login em geral.
    *   Isso pode disparar um alerta para `Security.Monitoring` ou ativar o modo de proteção avançada, que poderia impor um CAPTCHA global para login ou limites de taxa mais baixos por IP.
*   **Administrador Ativa Modo \"Sob Ataque\":**
    *   Monitoramento externo indica um ataque DDoS volumétrico.
    *   Administrador usa `Deeper_Hub.Console` para chamar `DdosProtection.set_advanced_protection(true, opts)`.
    *   Todas as novas requisições de IPs não reconhecidos passam por um desafio JavaScript ou são servidas com conteúdo estático de \"estamos sob ataque\", enquanto IPs conhecidos/autenticados podem ter acesso limitado.

## 🌊 5. Fluxos Importantes

### Fluxo de Mitigação de HTTP Flood por IP Único

1.  **Requisições Maliciosas:** Um IP (`1.2.3.4`) começa a enviar centenas de requisições por segundo para `/api/v1/data`.
2.  **`DdosProtectionPlug`:**
    *   Para cada requisição, chama `DdosProtectionService.record_and_check_request(\"1.2.3.4\", \"/api/v1/data\", context)`.
3.  **`DdosProtectionService`:**
    *   Incrementa o contador de requisições para `ip:1.2.3.4` e para `path:/api/v1/data`.
    *   Verifica se o contador para `ip:1.2.3.4` excedeu o limiar (ex: 100 reqs/minuto).
    *   **Limite Excedido:**
        *   Loga o evento.
        *   Incrementa métrica `ddos.ip_rate_limited`.
        *   Chama `Deeper_Hub.Security.IPFirewallService.block_ip(\"1.2.3.4\", \"DDoS rate limit exceeded on /api/v1/data\", 3600)`.
        *   Retorna `{:block, :ip_rate_limit_exceeded}` para o Plug.
4.  **`DdosProtectionPlug`:** Ao receber `{:block, ...}`, instrui a `conn` a retornar um `429 Too Many Requests` ou `403 Forbidden`.
5.  **Requisições Subsequentes de `1.2.3.4`:** Serão bloqueadas mais cedo pelo `IPFirewallPlug`.

## 📡 6. API (Funções Públicas da Fachada)

### 6.1. `Deeper_Hub.Security.DdosProtection.check_request_permitted?(ip_address :: String.t(), path :: String.t(), context :: map()) :: boolean()` (Nova Sugestão)

*   **Descrição:** Verifica se uma requisição deve ser permitida com base nas políticas de DDoS atuais. Retorna `true` se permitida, `false` se deve ser bloqueada ou limitada por taxa. Usado pelo Plug.
*   **`context`:** `%{method: \"GET\", headers: %{...}}`.

### 6.2. `Deeper_Hub.Security.DdosProtection.record_request_data(ip_address :: String.t(), path :: String.t(), context :: map(), response_status_code :: integer()) :: :ok` (Nova Sugestão)

*   **Descrição:** Registra dados sobre uma requisição processada para análise de padrões e para a mecânica de rate limiting. Chamado pelo Plug *após* a requisição ser processada pelo controller (para ter o status code).

### 6.3. `Deeper_Hub.Security.DdosProtection.report_suspicious_ip(ip_address :: String.t(), reason :: String.t(), evidence :: map() | nil) :: :ok`

*   **Descrição:** Permite que outros módulos (ex: `FraudDetection`, `IntrusionDetection`) reportem um IP como suspeito de atividade DDoS, podendo levar ao seu bloqueio.

### 6.4. `Deeper_Hub.Security.DdosProtection.set_protection_level(level :: :normal | :high_alert | :under_attack, opts :: keyword()) :: :ok` (Renomeado de `set_advanced_protection`)

*   **Descrição:** Define o nível de proteção global do sistema.
*   **`opts`:** Configurações específicas para o nível (ex: para `:under_attack`, `%{challenge_type: :js_challenge, global_ip_rate_limit: 5}`).

### 6.5. `Deeper_Hub.Security.DdosProtection.get_current_protection_level() :: {:ok, %{level: atom(), active_policies: map()}}` (Nova Sugestão)

*   **Descrição:** Retorna o nível de proteção atual e as políticas ativas.

### 6.6. `Deeper_Hub.Security.DdosProtection.get_traffic_statistics(opts :: keyword()) :: {:ok, map()}` (Renomeado de `get_statistics`)

*   **Descrição:** Obtém estatísticas de tráfego e mitigação.
*   **`opts`:** `:period` (`:last_minute`, `:last_hour`, `:last_day`), `:group_by` (`:ip`, `:path`).

## ⚙️ 7. Configuração

Via `Deeper_Hub.Core.ConfigManager` e `Deeper_Hub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :ddos, :enabled]`** (Boolean): Habilita o módulo.
*   **`[:security, :ddos, :default_policies, :normal_level]`** (Map): Configs de rate limit para IPs, paths, etc., em modo normal.
    *   Ex: `%{global_ip_limit: %{requests: 1000, window_seconds: 60}, path_limits: %{\"/api/search\" => %{requests: 60, window_seconds: 60}}}`
*   **`[:security, :ddos, :default_policies, :high_alert_level]`** (Map): Configs mais restritivas.
*   **`[:security, :ddos, :default_policies, :under_attack_level]`** (Map): Configs muito restritivas, possivelmente com `challenge_type: :js_challenge | :captcha`.
*   **`[:security, :ddos, :ip_block_on_ddos, :duration_seconds]`** (Integer): Duração padrão de bloqueio para IPs envolvidos em DDoS.
*   **`[:security, :ddos, :pattern_analyzer, :enabled]`** (Boolean).
*   **`[:security, :ddos, :pattern_analyzer, :log_analysis_interval_minutes]`** (Integer).
*   **`[:security, :ddos, :notification_thresholds, :global_rps]`** (Integer): Limiar de RPS global para notificar admins.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.ConfigManager`, `Core.Logger`, `Core.Metrics`, `Core.EventBus`.
*   `Deeper_Hub.Security.IPFirewallService`: Para efetuar bloqueios de IP.
*   `Deeper_Hub.API.RateLimiterFacade`: Como um dos mecanismos para implementar os limites de taxa.
*   `Deeper_Hub.Security.Monitoring`: Para enviar alertas de DDoS.
*   `Deeper_Hub.Security.CaptchaService` (ou um serviço de desafio genérico): Se desafios forem usados.

### 8.2. Bibliotecas Externas

*   Nenhuma específica para a lógica central. Adaptadores para serviços de mitigação externos teriam suas próprias dependências (ex: clientes HTTP).

## 🤝 9. Como Usar / Integração

*   **`DdosProtectionPlug`:** Adicionar ao pipeline global do Phoenix Router, bem no início.
    ```elixir
    pipeline :protect_all_the_things do
      plug Deeper_Hub.Security.Plugs.DdosProtectionPlug
      # ... outros plugs ...
    end
    scope \"/\", Deeper_HubWeb do
      pipe_through [:browser, :protect_all_the_things] # ou apenas :protect_all_the_things
      # ...
    end
    ```
*   **Alertas de Monitoramento Externo:** Um sistema de monitoramento externo pode chamar uma API administrativa (protegida) que por sua vez chama `DdosProtection.set_protection_level(:under_attack, ...)` se um ataque massivo for detectado na borda da rede.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Simular diferentes cenários de flood HTTP (single IP, multi IP, path específico) e verificar se o `DdosProtectionPlug` e o `DdosProtectionService` aplicam rate limiting e bloqueios corretamente.
*   Testar a transição entre diferentes níveis de proteção e se as políticas correspondentes são aplicadas.
*   Testar a lógica do `PatternAnalyzer` com logs de tráfego simulados.
*   Localização: `test/deeper_hub/security/ddos_protection/`.

### 10.2. Métricas

*   `deeper_hub.security.ddos.requests.total` (Contador, tags: `path`, `ip_country` (se disponível))
*   `deeper_hub.security.ddos.requests.rate_limited.count` (Contador, tags: `path`, `ip_address_masked`)
*   `deeper_hub.security.ddos.requests.blocked_by_ddos.count` (Contador, tags: `path`, `ip_address_masked`)
*   `deeper_hub.security.ddos.protection_level.gauge` (Gauge, valor: 0=normal, 1=high_alert, 2=under_attack)
*   `deeper_hub.security.ddos.active_ip_blocks_ddos.gauge` (Gauge)

### 10.3. Logs

*   **Nível INFO:** Mudança no nível de proteção.
*   **Nível WARNING:** IP sendo limitado por taxa devido a política de DDoS. IP bloqueado por política de DDoS. Padrão de ataque suspeito detectado pelo `PatternAnalyzer`.
*   **Nível ERROR:** Falha ao aplicar uma política de bloqueio.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :ddos, :request_analysis]`
    *   Metadados: `%{ip: ip, path: path, user_agent_ krótkie, result: :allowed | :rate_limited | :blocked, current_rps: rps}`
*   `[:deeper_hub, :security, :ddos, :ip_action_ddos]`
    *   Metadados: `%{ip: ip, action: :blocked | :unblocked_ddos, reason: reason, duration: dur}`
*   `[:deeper_hub, :security, :ddos, :protection_level_change]`
    *   Metadados: `%{old_level: level, new_level: level, trigger: :manual | :automatic}`

## ❌ 11. Tratamento de Erros

*   Falhas nos componentes de proteção DDoS (ex: ETS cheio, erro no `PatternAnalyzer`) não devem derrubar a aplicação. O sistema deve tentar operar em um modo seguro ou degradado.
*   Erros ao bloquear um IP via `IPFirewallService` devem ser logados, mas o rate limiting ainda deve funcionar se possível.

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Falsos Positivos:** A principal preocupação. Limites muito baixos ou detecção de padrões muito sensível podem bloquear tráfego legítimo. A capacidade de ajustar políticas e ter um modo \"monitor\" é importante.
*   **Bypass:** Atacantes podem tentar contornar a proteção baseada em IP usando proxies ou botnets grandes. A análise de padrões e a integração com `DeviceFingerprint` ou `BehavioralAnalysis` podem ajudar.
*   **Recursos do Próprio Módulo:** O monitoramento de tráfego e a manutenção de contadores podem consumir recursos. Otimizar o uso de ETS e amostrar dados para o `PatternAnalyzer` é importante.

## 🧑‍💻 13. Contribuição

*   Novas regras de detecção de padrões devem ser adicionadas ao `PatternAnalyzer` com testes rigorosos.
*   Ao integrar com serviços externos de mitigação, crie adaptadores claros e resilientes.
*   Políticas de rate limiting devem ser revisadas e ajustadas com base no tráfego observado e no perfil de risco da aplicação.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar desafios JavaScript mais leves antes de recorrer a CAPTCHAs completos para tráfego suspeito, mas não claramente malicioso.
*   [ ] Desenvolver um sistema de \"aprendizado\" para os limiares de rate limiting, permitindo que se ajustem dinamicamente à carga normal da aplicação.
*   [ ] Integração mais profunda com WAFs na borda para bloquear tráfego no nível da infraestrutura com base nas detecções da aplicação.
*   [ ] Análise de \"fingerprints de bot\" para identificar e bloquear tráfego automatizado malicioso de forma mais eficaz.
*   [ ] Permitir que usuários (especialmente clientes de API) solicitem aumento de limites de taxa mediante justificativa ou plano de assinatura.

---

*Última atualização: 2025-05-12*

---

Proteção DDoS é uma batalha contínua!

Agora que cobrimos várias camadas de segurança (`AdminAuth`, `CsrfProtection`, `SqlInjectionProtection`, `PathTraversalProtection`, `DdosProtection`), e também módulos Core (`EventBus`, `ConfigManager`, `Logger`, `Metrics`, `Cache`, `Repo`), talvez seja uma boa hora para um módulo de domínio, como `Deeper_Hub.Servers` ou `Deeper_Hub.Accounts` (que já começamos)? Ou prefere continuar com os módulos de segurança restantes, como `AtRestEncryptionService` ou `ResponseSanitizer`?"""),
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
                types.Part.from_text(text="""Entendido! Vamos continuar com os módulos de segurança, pois são a espinha dorsal da proteção do sistema.

Dado que já abordamos `AtRestEncryptionService` de forma implícita ao falar do `Core.EncryptionService` e `EncryptedType`, e `ResponseSanitizer` é conceitualmente similar ao `LogSanitizer` (focado em respostas HTTP), que tal detalharmos o `Deeper_Hub.Security.IntrusionDetection`? Este módulo atua como um sistema de alerta para atividades suspeitas que podem não ser fraude direta, mas indicam uma possível tentativa de comprometer o sistema.

---

