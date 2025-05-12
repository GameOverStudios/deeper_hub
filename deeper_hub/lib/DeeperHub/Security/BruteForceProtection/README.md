# Módulo: `DeeperHub.Security.BruteForceProtection` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Security.BruteForceProtection`

O módulo `DeeperHub.Security.BruteForceProtection` é responsável por detectar e mitigar ataques de força bruta contra o sistema DeeperHub. Ataques de força bruta ocorrem quando um invasor tenta adivinhar credenciais (como senhas) ou outros segredos através de um grande volume de tentativas.

Este módulo monitora tentativas falhas de acesso para identificadores específicos (como endereços IP, nomes de usuário ou emails), aplicando contramedidas como bloqueios temporários ou a exigência de desafios CAPTCHA para dificultar esses ataques e proteger as contas dos usuários. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Monitoramento de Tentativas Falhas:**
    *   Registrar tentativas de login falhas para diferentes identificadores (`record_failed_attempt/2`).
    *   Registrar tentativas de outras operações sensíveis que podem ser alvo de força bruta (ex: verificação de token de reset de senha).
*   **Aplicação de Contramedidas:**
    *   **Bloqueio Temporário:** Bloquear um identificador (IP, usuário) por um período configurável após um número excessivo de tentativas falhas (`is_blocked?/1`).
    *   **Requisição de CAPTCHA:** Exigir que o usuário resolva um CAPTCHA após um certo número de tentativas falhas, antes de permitir novas tentativas (`captcha_required?/1`).
*   **Gerenciamento de Estado de Tentativas:**
    *   Manter contadores de tentativas falhas por identificador e por tipo de operação.
    *   Resetar contadores após uma tentativa bem-sucedida (`record_successful_attempt/1`) ou após um período de inatividade.
*   **Configurabilidade de Políticas:**
    *   Permitir a configuração de limiares para bloqueio e CAPTCHA (número de tentativas, janela de tempo).
    *   Permitir a configuração da duração dos bloqueios.
*   **Limpeza de Dados Antigos:**
    *   Remover periodicamente registros de tentativas antigas e bloqueios expirados para manter a eficiência do sistema (via `CleanupWorker`).
*   **Observabilidade:**
    *   Fornecer estatísticas sobre tentativas bloqueadas, CAPTCHAs exigidos e identificadores monitorados (`get_statistics/0`).
    *   Registrar logs e métricas para atividades de força bruta.
*   **Integração:**
    *   Integrar-se com módulos de autenticação (`DeeperHub.Auth`) e recuperação de conta (`DeeperHub.Recovery`) para registrar tentativas.
    *   Integrar-se com um serviço de CAPTCHA (se aplicável, pode ser um serviço externo ou um módulo interno simples).

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Security.BruteForceProtection` (Fachada Pública):**
    *   Ponto de entrada para registrar tentativas e verificar o status de proteção.
    *   Delega chamadas para o `BruteForceProtectionService`.
2.  **`DeeperHub.Security.BruteForceProtection.Services.BruteForceProtectionService` (GenServer):**
    *   **Responsabilidade:** O coração do sistema, gerenciando o estado das tentativas e bloqueios.
    *   **Estado Interno (geralmente em ETS para performance):**
        *   Tabela de contadores de tentativas falhas (ex: `{identifier, operation_type} -> {count, last_attempt_timestamp}`).
        *   Tabela de identificadores bloqueados (ex: `{identifier} -> {blocked_until_timestamp, reason}`).
        *   Tabela de identificadores que requerem CAPTCHA (ex: `{identifier} -> captcha_required_until_timestamp`).
    *   **Interações:** Recebe chamadas da fachada, aplica lógicas de incremento de contador, bloqueio, verificação de CAPTCHA. Dispara a limpeza periódica.
3.  **`DeeperHub.Security.BruteForceProtection.Workers.CleanupWorker` (GenServer):**
    *   **Responsabilidade:** Executar periodicamente a limpeza de dados de tentativas antigas e bloqueios expirados nas tabelas ETS (ou outro storage).
4.  **Configurações (via `DeeperHub.Core.ConfigManager` e `DeeperHub.Security.Policy.SecurityPolicyManager`):**
    *   Limiares de tentativas.
    *   Janelas de tempo para contagem.
    *   Duração de bloqueios.
    *   Configurações de CAPTCHA.
5.  **`DeeperHub.Security.BruteForceProtection.Telemetry` (ou `MetricsReporter`):**
    *   Para registrar métricas sobre a atividade de proteção.

### 3.2. Estrutura de Diretórios (Proposta)

```
security/brute_force_protection/
├── brute_force_protection.ex             # Fachada Pública
│
├── services/
│   └── brute_force_protection_service.ex # GenServer principal
│
├── workers/
│   └── cleanup_worker.ex                 # Worker para limpeza
│
├── supervisor.ex
└── telemetry.ex                          # (ou MetricsReporter.ex)
```
*(Os módulos `BruteForceProtectionAdapter` e `BruteForceProtectionBehaviour` da documentação original podem ser consolidados se houver apenas uma implementação principal, como o `BruteForceProtectionService` GenServer.)*

### 3.3. Decisões de Design Importantes

*   **Armazenamento em Memória (ETS) para Performance:** Contadores de tentativas e bloqueios de curto prazo são frequentemente armazenados em ETS para acesso rápido e para evitar sobrecarga no banco de dados principal. Bloqueios mais longos ou persistentes podem envolver o DB.
*   **Identificadores Flexíveis:** O sistema deve ser capaz de rastrear tentativas por diferentes tipos de identificadores (IP, username, email, ID de sessão, etc.), dependendo do contexto da operação.
*   **Escalabilidade do CAPTCHA:** Se CAPTCHAs forem usados, a integração deve ser com um serviço de CAPTCHA robusto ou um mecanismo que não seja facilmente contornável.
*   **Políticas Granulares:** Idealmente, as políticas de proteção (limiares, durações) podem ser configuradas por tipo de operação (ex: login vs. reset de senha).

## 🛠️ 4. Casos de Uso Principais

*   **Múltiplas Tentativas de Login Falhas por um IP:**
    *   `DeeperHub.Auth` registra cada tentativa falha via `BruteForceProtection.record_failed_attempt(\"ip:1.2.3.4\", %{operation: :login})`.
    *   Após `N` falhas, `BruteForceProtectionService` marca o IP como requerendo CAPTCHA.
    *   Após `M` falhas (com ou sem CAPTCHA), o IP é temporariamente bloqueado.
    *   Requisições subsequentes desse IP para o endpoint de login são rejeitadas com 429 ou 403.
*   **Tentativas de Adivinhar Código de Reset de Senha:**
    *   `DeeperHub.Recovery` registra cada tentativa falha de verificação de token de reset para um `user_id` ou `token_id`.
    *   Após algumas falhas, o `user_id` pode ser temporariamente impedido de tentar mais verificações de token.
*   **Usuário Legítimo Esquece Senha e Excede Tentativas:**
    *   O usuário é informado sobre o bloqueio temporário e/ou a necessidade de CAPTCHA.
    *   Após o período de bloqueio, ou resolvendo o CAPTCHA, o usuário pode tentar novamente.
    *   Um login bem-sucedido reseta os contadores de falha para aquele identificador/operação.

## 🌊 5. Fluxos Importantes

### Fluxo de Registro de Tentativa Falha e Bloqueio

1.  **Operação Falha:** Um módulo (ex: `AuthService`) detecta uma tentativa falha de uma operação sensível (ex: login).
2.  **Registro:** O módulo chama `DeeperHub.Security.BruteForceProtection.record_failed_attempt(identifier, %{operation_type: :login, username_attempted: \"foo\"})`.
    *   `identifier` pode ser `ip:<ip_address>`, `user:<user_id>`, `email:<email_address>`.
3.  **`BruteForceProtectionService` (GenServer):**
    *   Recebe o registro.
    *   Incrementa o contador de falhas para o `identifier` e `operation_type` em sua tabela ETS.
    *   Verifica se o número de falhas dentro da janela de tempo configurada excede o limiar para CAPTCHA.
        *   Se sim, marca o `identifier` como `captcha_required` com um timestamp de expiração.
    *   Verifica se o número de falhas excede o limiar para bloqueio.
        *   Se sim, adiciona o `identifier` à lista de bloqueados com um timestamp de `blocked_until`. Loga o bloqueio e emite um evento/métrica.
4.  **Resposta:** Retorna `:ok` para o chamador.

### Fluxo de Verificação de Tentativa (`check_attempt/2`)

1.  **Antes da Operação:** Um módulo (ex: Plug de Autenticação) chama `DeeperHub.Security.BruteForceProtection.check_attempt(identifier, %{operation_type: :login})` antes de processar uma operação.
2.  **`BruteForceProtectionService` (GenServer):**
    *   Verifica se o `identifier` está na lista de bloqueados.
        *   Se sim, e o bloqueio ainda está ativo, retorna `{:ok, :blocked}`.
    *   Verifica se o `identifier` está marcado como `captcha_required`.
        *   Se sim, e ainda ativo, retorna `{:ok, :captcha_required}`.
    *   Caso contrário, retorna `{:ok, :allowed}`.

## 📡 6. API (Funções Públicas da Fachada)

*(A documentação original já tem uma boa base para estas funções. Vamos refinar e adicionar.)*

### 6.1. `DeeperHub.Security.BruteForceProtection.record_failed_attempt(identifier :: String.t(), context :: map()) :: :ok | {:error, term()}`

*   **Descrição:** Registra uma tentativa falha para um identificador. Incrementa contadores e aplica políticas de CAPTCHA/bloqueio.
*   **`identifier`:** String que identifica a origem da tentativa (ex: `\"ip:1.2.3.4\"`, `\"user_id:abc\"`, `\"email:user@example.com\"`).
*   **`context`:** Mapa com informações adicionais.
    *   `:operation_type` (atom, obrigatório): Tipo da operação que falhou (ex: `:login`, `:password_reset_verify`, `:mfa_verify`).
    *   Outros dados relevantes (ex: `:username_attempted`).
*   **Retorno:** `:ok`. Lança exceção em caso de erro interno grave.

### 6.2. `DeeperHub.Security.BruteForceProtection.record_successful_attempt(identifier :: String.t(), context :: map()) :: :ok`

*   **Descrição:** Registra uma tentativa bem-sucedida, o que geralmente reseta os contadores de falha para o `identifier` e `operation_type` específicos.
*   **`identifier`:** Mesmo formato de `record_failed_attempt/2`.
*   **`context`:**
    *   `:operation_type` (atom, obrigatório): Tipo da operação bem-sucedida.

### 6.3. `DeeperHub.Security.BruteForceProtection.check_attempt(identifier :: String.t(), context :: map()) :: {:ok, :allowed | :captcha_required | :blocked} | {:error, term()}`

*   **Descrição:** Verifica o status de proteção para um identificador antes de permitir uma operação.
*   **Retorno:**
    *   `{:ok, :allowed}`: A tentativa é permitida.
    *   `{:ok, :captcha_required}`: Um CAPTCHA deve ser resolvido antes de prosseguir.
    *   `{:ok, :blocked}`: A tentativa está bloqueada temporariamente.
*   **Exemplo:**
    ```elixir
    case BruteForceProtection.check_attempt(\"ip:\" <> conn.remote_ip, %{operation_type: :login}) do
      {:ok, :allowed} -> # Prosseguir
      {:ok, :captcha_required} -> # Redirecionar para CAPTCHA
      {:ok, :blocked} -> # Retornar 429 Too Many Requests
      {:error, _} -> # Logar erro, talvez permitir com cautela
    end
    ```

### 6.4. `DeeperHub.Security.BruteForceProtection.is_blocked?(identifier :: String.t(), context :: map() | nil) :: boolean()`

*   **Descrição:** Retorna `true` se o identificador estiver atualmente bloqueado para o tipo de operação no contexto (se fornecido), `false` caso contrário.

### 6.5. `DeeperHub.Security.BruteForceProtection.captcha_required?(identifier :: String.t(), context :: map() | nil) :: boolean()`

*   **Descrição:** Retorna `true` se um CAPTCHA for necessário para o identificador e tipo de operação.

### 6.6. `DeeperHub.Security.BruteForceProtection.clear_attempts(identifier :: String.t(), context :: map() | nil) :: :ok`

*   **Descrição:** Limpa manualmente todos os contadores de falha e status de CAPTCHA/bloqueio para um identificador (e tipo de operação, se `context` fornecido). Usado por administradores ou após recuperação de conta bem-sucedida.

## ⚙️ 7. Configuração

Configurações gerenciadas pelo `DeeperHub.Core.ConfigManager` e/ou `DeeperHub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :brute_force, :enabled]`** (Boolean): Habilita/desabilita o módulo. (Padrão: `true`)
*   **`[:security, :brute_force, :policies]`** (List de Maps): Lista de políticas. Cada política define:
    *   `:operation_type` (Atom): A qual operação esta política se aplica (ex: `:login`, `:password_reset`, `:all_failed_auth`).
    *   `:identifier_types` (List de Atoms): Quais tipos de identificadores esta política rastreia (ex: `[:ip, :user_id]`).
    *   `:captcha_threshold` (Integer): Número de falhas para exigir CAPTCHA.
    *   `:captcha_window_seconds` (Integer): Janela de tempo para contar falhas para CAPTCHA.
    *   `:block_threshold` (Integer): Número de falhas para bloquear.
    *   `:block_window_seconds` (Integer): Janela de tempo para contar falhas para bloqueio.
    *   `:block_duration_seconds` (Integer): Duração do bloqueio.
    *   `:block_increment_factor` (Float, opcional): Fator para aumentar a duração do bloqueio em bloqueios subsequentes. (Padrão: `1.0`)
    *   `:max_block_duration_seconds` (Integer, opcional): Duração máxima de um bloqueio.
*   **`[:security, :brute_force, :cleanup_worker, :interval_minutes]`** (Integer): Intervalo para o `CleanupWorker`. (Padrão: `60`)
*   **`[:security, :brute_force, :cleanup_worker, :attempt_retention_days]`** (Integer): Por quantos dias manter registros de tentativas. (Padrão: `7`)
*   **`[:security, :captcha, :service_module]`** (Module, opcional): Módulo do serviço de CAPTCHA a ser usado (se aplicável).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`: Para obter políticas e configurações.
*   `DeeperHub.Core.Logger`: Para logging.
*   `DeeperHub.Core.Metrics`: Para registrar métricas.
*   `DeeperHub.Core.EventBus` (opcional): Para publicar eventos de bloqueio ou atividade suspeita.
*   `DeeperHub.Security.Policy.SecurityPolicyManager`: Para uma interface mais rica sobre as políticas.
*   Um serviço de CAPTCHA (se integrado).

### 8.2. Bibliotecas Externas

*   Nenhuma dependência externa direta é estritamente necessária para a lógica central, que pode ser implementada com ETS.

## 🤝 9. Como Usar / Integração

**Integrando com o fluxo de login em `DeeperHub.Auth.Services.LoginService`:**
```elixir
def authenticate(email, password, context_info) do
  ip_identifier = \"ip:#{context_info.ip_address}\"
  email_identifier = \"email:#{email}\"

  # Verificar antes de tentar autenticar
  case BruteForceProtection.check_attempt(ip_identifier, %{operation_type: :login}) do
    {:ok, :blocked} -> {:error, :ip_blocked}
    {:ok, :captcha_required} -> {:error, :captcha_required_for_ip}
    {:ok, :allowed} ->
      # Tentar autenticar...
      case do_authenticate(email, password) do
        {:ok, user} ->
          BruteForceProtection.record_successful_attempt(ip_identifier, %{operation_type: :login})
          BruteForceProtection.record_successful_attempt(email_identifier, %{operation_type: :login})
          BruteForceProtection.record_successful_attempt(\"user_id:#{user.id}\", %{operation_type: :login})
          {:ok, user}
        {:error, :invalid_credentials} ->
          BruteForceProtection.record_failed_attempt(ip_identifier, %{operation_type: :login, email_attempted: email})
          BruteForceProtection.record_failed_attempt(email_identifier, %{operation_type: :login})
          # Se o usuário existir, também registrar falha para user_id
          # if user = Accounts.get_user_by_email(email), do: BruteForceProtection.record_failed_attempt(\"user_id:#{user.id}\", ...)
          {:error, :invalid_credentials}
      end
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar se os contadores de falha são incrementados corretamente.
*   Testar se o status `captcha_required` é definido após o limiar.
*   Testar se o status `blocked` é definido após o limiar e pela duração correta.
*   Testar se `record_successful_attempt` reseta os contadores.
*   Testar o `CleanupWorker` para remoção de entradas expiradas.
*   Localização: `test/deeper_hub/security/brute_force_protection/`.

### 10.2. Métricas

*   `deeper_hub.security.brute_force.failed_attempts.count` (tags: `identifier_type`, `operation_type`)
*   `deeper_hub.security.brute_force.captcha_required.count` (tags: `identifier_type`, `operation_type`)
*   `deeper_hub.security.brute_force.identifier_blocked.count` (tags: `identifier_type`, `operation_type`)
*   `deeper_hub.security.brute_force.active_blocks.gauge` (Gauge)
*   `deeper_hub.security.brute_force.cleanup.duration_ms` (Histograma)
*   `deeper_hub.security.brute_force.cleanup.items_removed.count` (Contador)

### 10.3. Logs

*   **Nível INFO:** Registro de tentativas bem-sucedidas que resetam contadores. Execução do `CleanupWorker`.
*   **Nível WARNING:** Identificador atinge limiar de CAPTCHA. Identificador é bloqueado.
*   **Nível ERROR:** Erros internos no `BruteForceProtectionService`.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :brute_force, :attempt_recorded]`
    *   Metadados: `%{identifier: id, operation_type: type, outcome: :success | :failure}`
*   `[:deeper_hub, :security, :brute_force, :status_changed]`
    *   Metadados: `%{identifier: id, operation_type: type, old_status: atom(), new_status: atom(), reason: reason, duration_seconds: dur}` (para :blocked ou :captcha_required)
*   `[:deeper_hub, :security, :brute_force, :cleanup_run]`
    *   Medições: `%{duration: native_time, items_removed: count}`

## ❌ 11. Tratamento de Erros

*   O serviço deve ser resiliente. Falhas internas no `BruteForceProtectionService` não devem impedir o fluxo principal da aplicação (ex: um login legítimo não deve falhar se o serviço de brute force estiver com problemas, mas um log de erro crítico deve ser gerado).
*   A limpeza de dados deve ser robusta para não remover bloqueios ativos indevidamente.

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Proteção do Storage:** Se ETS for usado, ele é limitado ao nó. Se um armazenamento distribuído for usado para os contadores/bloqueios, ele deve ser protegido.
*   **Falsos Positivos:** Políticas muito agressivas podem bloquear usuários legítimos, especialmente em cenários de IP compartilhado (NAT, VPNs). A configuração de `identifier_types` e a opção de whitelisting de IPs (gerenciado por `IpFirewallService`) são importantes.
*   **Evasão:** Invasores podem tentar rotacionar IPs. Rastrear por outros identificadores (`user_id`, `email`) em conjunto com o IP pode ser mais eficaz.
*   **Ataques de Negação de Serviço ao Módulo:** Um grande volume de tentativas falhas pode sobrecarregar o GenServer se não houver otimizações ou se o processamento de cada tentativa for muito custoso.

## 🧑‍💻 13. Contribuição

*   Ao integrar com novas operações sensíveis, certifique-se de chamar `record_failed_attempt` e `record_successful_attempt` apropriadamente.
*   Defina políticas claras e testadas para cada `operation_type`.
*   Considere o impacto na experiência do usuário ao definir limiares e durações de bloqueio.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar \"listas brancas\" (allowlists) para identificadores que nunca devem ser bloqueados por força bruta.
*   [ ] Suporte para bloqueios progressivos (duração aumenta a cada bloqueio subsequente).
*   [ ] Integração mais profunda com análise comportamental para detectar se as tentativas falhas são de um usuário legítimo ou de um bot.
*   [ ] Permitir que administradores visualizem e gerenciem bloqueios ativos e contadores através de uma interface.
*   [ ] Adicionar opção para \"desafios\" mais avançados que CAPTCHA para certos níveis de suspeita.
*   [ ] Considerar o uso de um backend de armazenamento mais persistente e distribuído (ex: Redis) para os contadores e bloqueios, especialmente em ambientes clusterizados.

---

*Última atualização: 2025-05-11*

---

Próximo! Que tal `DeeperHub.Security.RiskAssessment` para vermos como os riscos são calculados?"""),
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
                types.Part.from_text(text="""Ótimo! Vamos detalhar o `DeeperHub.Security.RiskAssessment`. Este módulo é fundamental para uma abordagem de segurança adaptativa e baseada em contexto.

---

