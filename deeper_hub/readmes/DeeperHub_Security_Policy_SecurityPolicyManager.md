# Módulo: `Deeper_Hub.Security.Policy.SecurityPolicyManager` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Security.Policy.SecurityPolicyManager`

O módulo `Deeper_Hub.Security.Policy.SecurityPolicyManager` atua como o **gerenciador centralizado para todas as políticas de segurança** dentro do sistema Deeper_Hub. Ele fornece uma interface unificada para definir, consultar e atualizar diversas políticas que governam o comportamento dos diferentes submódulos de segurança (ex: `RiskAssessment`, `BruteForceProtection`, `MFA`, `SessionPolicy`, etc.).

Uma característica chave deste módulo é a integração com o sistema de Controle de Acesso Baseado em Papéis (`Deeper_Hub.RBAC`), garantindo que apenas usuários autorizados (tipicamente administradores de segurança) possam visualizar e modificar configurações críticas de segurança. Todas as alterações de política são, idealmente, auditadas.

Este módulo abstrai o armazenamento subjacente das políticas (que pode ser o `Deeper_Hub.Core.ConfigManager` ou um armazenamento dedicado) e adiciona uma camada de validação, autorização e lógica de negócio específica para políticas de segurança. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Gerenciamento Centralizado de Políticas:**
    *   Servir como o ponto único de verdade para a configuração de todas as políticas de segurança.
*   **Definição e Atualização de Políticas:**
    *   Permitir a criação e atualização de políticas para diversas áreas (ex: `update_security_config/4`).
    *   Suportar políticas com diferentes escopos (global, por tipo de usuário, por tenant, etc.), se necessário.
*   **Consulta de Políticas:**
    *   Fornecer uma API para que outros módulos de segurança consultem as políticas relevantes para suas operações (`get_security_configs/2`).
    *   Obter políticas modificadas em relação aos valores padrão (`get_modified_configs/2`).
*   **Validação de Políticas:**
    *   Validar os valores das políticas antes de aplicá-los para garantir que são válidos e consistentes (via `Deeper_Hub.Security.Validation.SecurityInputValidation`).
*   **Autorização RBAC:**
    *   Integrar com `Deeper_Hub.RBAC` para garantir que apenas usuários com as permissões adequadas possam visualizar ou modificar políticas de segurança (via `Deeper_Hub.Security.Policy.SecurityPolicyAuthorization`).
*   **Redefinição para Padrões:**
    *   Permitir a redefinição de políticas para seus valores padrão de fábrica (`reset_security_config/3`).
*   **Auditoria de Mudanças de Política:**
    *   Integrar com `Deeper_Hub.Audit` para registrar todas as alterações nas políticas de segurança, incluindo quem fez a alteração, quando e qual foi a mudança.
*   **Notificação de Mudanças de Política (Opcional):**
    *   Publicar eventos no `Core.EventBus` quando políticas de segurança críticas são alteradas, permitindo que os sistemas relevantes recarreguem suas configurações.
*   **Interface para Diferentes Tipos de Política:**
    *   Gerenciar políticas para:
        *   Limiares de Risco (`RiskAssessment`).
        *   Pesos de Fatores de Risco (`RiskAssessment`).
        *   Regras de Ação de Risco (`RiskAssessment`).
        *   Limiares de Força Bruta (`BruteForceProtection`).
        *   Duração de Bloqueios (`BruteForceProtection`, `IPFirewallService`).
        *   Regras de MFA (`Deeper_Hub.MFA.MFAPolicyService`).
        *   Políticas de Sessão (`Deeper_Hub.SessionPolicy`).
        *   Configurações de Criptografia (ex: frequência de rotação de chaves).
        *   Listas de IPs/Domínios Permitidos/Bloqueados (`IPFirewallService`, `EmailValidator`).
        *   E outras configurações de segurança.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`Deeper_Hub.Security.Policy.SecurityPolicyManager` (Fachada Pública):**
    *   Ponto de entrada para gerenciamento de políticas.
    *   Delega para o `SecurityPolicyService` (ou GenServer interno).
2.  **`Deeper_Hub.Security.Policy.SecurityPolicyService` (GenServer ou Módulo de Serviço):**
    *   **Responsabilidade:** Orquestra a lógica de gerenciamento de políticas.
    *   **Interações:**
        *   `SecurityPolicyAuthorization`: Para verificar permissões do usuário que está tentando modificar/visualizar.
        *   `Deeper_Hub.Security.Validation.SecurityInputValidation`: Para validar novos valores de política.
        *   `Deeper_Hub.Core.ConfigManager`: Como o *backend de armazenamento primário* para as políticas. O `SecurityPolicyManager` atua como uma camada de lógica de negócio e segurança sobre o `ConfigManager` para configurações especificamente de segurança.
        *   `Deeper_Hub.Audit`: Para registrar alterações.
        *   `Deeper_Hub.Core.EventBus` (opcional): Para notificar mudanças.
3.  **`Deeper_Hub.Security.Policy.SecurityPolicyAuthorization`:**
    *   **Responsabilidade:** Contém a lógica para verificar se um usuário tem permissão (via `Deeper_Hub.RBAC`) para acessar ou modificar uma determinada política ou área de política.
4.  **`Deeper_Hub.Security.Validation.SecurityInputValidation`:**
    *   Contém schemas e funções de validação específicas para diferentes tipos de políticas de segurança (ex: `validate_ip_firewall_config`, `validate_mfa_policy`).
5.  **`Deeper_Hub.Core.ConfigManager` (Backend de Armazenamento):**
    *   As políticas de segurança são, em última análise, configurações armazenadas e gerenciadas pelo `ConfigManager`. O `SecurityPolicyManager` garante que o acesso e a modificação dessas configurações específicas de segurança sigam um fluxo controlado.

### 3.2. Estrutura de Diretórios (Proposta)

```
security/policy/
├── security_policy_manager.ex          # Fachada Pública
├── security_policy_service.ex          # Lógica de Serviço (pode ser GenServer)
├── security_policy_authorization.ex    # Lógica de autorização RBAC
│
└── supervisor.ex                       # Supervisor (se SecurityPolicyService for GenServer)

security/validation/     # (Já existe, mas SecurityInputValidation é usado aqui)
└── security_input_validation.ex
```

### 3.3. Decisões de Design Importantes

*   **Camada de Abstração sobre `ConfigManager`:** Em vez de os módulos de segurança acessarem diretamente o `ConfigManager` para todas as suas configurações, eles podem passar pelo `SecurityPolicyManager` para obter configurações que são consideradas \"políticas de segurança\". Isso centraliza a lógica de autorização e validação específica de segurança.
*   **RBAC para Modificações:** Qualquer alteração em uma política de segurança deve ser estritamente controlada por permissões RBAC.
*   **Valores Padrão Robustos:** O sistema deve ter valores padrão seguros para todas as políticas, caso não sejam explicitamente configurados.
*   **Clareza na Nomenclatura das Chaves:** As chaves de configuração usadas para políticas de segurança no `ConfigManager` devem seguir um padrão claro (ex: `security.policy.brute_force.login.max_attempts`).

## 🛠️ 4. Casos de Uso Principais

*   **Administrador de Segurança Define Limite de Tentativas de Login:**
    *   Admin acessa a interface de gerenciamento de políticas.
    *   Tenta atualizar a política `brute_force.login.max_attempts` para `3`.
    *   A UI chama `SecurityPolicyManager.update_security_config(admin_user_id, \"security.policy.brute_force.login.max_attempts\", 3, opts)`.
    *   `SecurityPolicyAuthorization` verifica se `admin_user_id` tem permissão para alterar políticas de força bruta.
    *   `SecurityInputValidation` valida se `3` é um valor aceitável para essa política.
    *   `SecurityPolicyService` chama `Core.ConfigManager.set(\"security.policy.brute_force.login.max_attempts\", 3, ...)`.
    *   `Audit` registra a alteração.
*   **Módulo `RiskAssessment` Consulta Limiar de Risco:**
    *   `RiskCalculatorService` precisa do limiar para classificar um score como `:high`.
    *   Chama `SecurityPolicyManager.get_security_configs(nil, %{config_key_prefix: \"security.policy.risk_assessment.thresholds\"})` ou diretamente `Core.ConfigManager.get(\"security.policy.risk_assessment.thresholds.high\", \"global\", 75)`. A primeira opção é preferível se houver lógica de autorização para *visualizar* certas políticas.
*   **Sistema Redefine Política de MFA para o Padrão:**
    *   Um administrador solicita a redefinição da política de MFA.
    *   A UI chama `SecurityPolicyManager.reset_security_config(admin_user_id, \"security.policy.mfa.default_method\", opts)`.

## 🌊 5. Fluxos Importantes

### Fluxo de Atualização de uma Política de Segurança

1.  **Interface (Admin UI/Console):** Um usuário administrador tenta modificar uma política (ex: aumentar o TTL da sessão).
2.  **Chamada à Fachada:** A interface chama `Deeper_Hub.Security.Policy.SecurityPolicyManager.update_security_config(admin_user_id, \"security.policy.session.max_duration_seconds\", 7200, %{reason: \"Policy review\"})`.
3.  **`SecurityPolicyService`:**
    *   Recebe a solicitação.
    *   Chama `SecurityPolicyAuthorization.authorize_config_change(admin_user_id, \"security.policy.session.max_duration_seconds\")`.
        *   **Falha na Autorização:** Retorna `{:error, :unauthorized}`.
    *   Se autorizado, chama `Deeper_Hub.Security.Validation.SecurityInputValidation.validate_security_policy(7200, :session_duration, opts)`.
        *   **Falha na Validação:** Retorna `{:error, :validation_failed, errors}`.
    *   Se validado, chama `Deeper_Hub.Core.ConfigManager.set(\"security.policy.session.max_duration_seconds\", 7200, %{scope: \"global\", description: \"Max session TTL\", created_by: admin_user_id})`.
    *   Se `ConfigManager.set` for bem-sucedido:
        *   Chama `Deeper_Hub.Audit.log_event(...)` para registrar a alteração da política.
        *   (Opcional) Publica um evento `config_changed` ou `security_policy_changed` no `Core.EventBus`.
        *   Retorna `{:ok, 7200}`.
    *   Se `ConfigManager.set` falhar, propaga o erro.

## 📡 6. API (Funções Públicas da Fachada `Deeper_Hub.Security.Policy.SecurityPolicyManager`)

### 6.1. `Deeper_Hub.Security.Policy.SecurityPolicyManager.get_security_configs(requesting_user_id :: String.t() | nil, opts :: keyword()) :: {:ok, map()} | {:error, :unauthorized | term()}`

*   **Descrição:** Obtém as configurações de segurança que o `requesting_user_id` tem permissão para visualizar. Se `requesting_user_id` for `nil` (sistema interno), pode retornar todas.
*   **`opts`:**
    *   `:policy_area` (atom | String.t | nil): Filtra por uma área específica de política (ex: `:brute_force`, `\"risk_assessment.thresholds\"`).
    *   `:keys_only` (boolean): Retorna apenas as chaves das políticas, não os valores.
*   **Retorno:** Um mapa onde as chaves são os nomes das políticas (ex: `\"security.mfa.required_for_admin\"`) e os valores são os valores das políticas.

### 6.2. `Deeper_Hub.Security.Policy.SecurityPolicyManager.update_security_config(admin_user_id :: String.t(), config_key :: String.t(), new_value :: term(), opts :: keyword()) :: {:ok, term()} | {:error, :unauthorized | :validation_failed | term()}`

*   **Descrição:** Atualiza o valor de uma política de segurança específica. Requer que `admin_user_id` tenha as permissões adequadas.
*   **`config_key`:** A chave completa da política no `ConfigManager` (ex: `\"security.brute_force.login.max_attempts\"`).
*   **`new_value`:** O novo valor para a política.
*   **`opts`:**
    *   `:reason` (String.t): Motivo da alteração, para auditoria.
    *   `:scope` (String.t): Escopo da configuração no ConfigManager. (Padrão: `\"global\"`)
*   **Retorno:** `{:ok, new_value_applied}` ou erro.

### 6.3. `Deeper_Hub.Security.Policy.SecurityPolicyManager.update_multiple_configs(admin_user_id :: String.t(), configs_map :: map(), opts :: keyword()) :: {:ok, updated_configs :: map()} | {:error, :unauthorized | :validation_failed | term()}`

*   **Descrição:** Atualiza múltiplas políticas de segurança em uma única operação transacional (se possível pelo `ConfigManager`).
*   **`configs_map`:** Mapa de `{config_key, new_value}`.

### 6.4. `Deeper_Hub.Security.Policy.SecurityPolicyManager.reset_security_config(admin_user_id :: String.t(), config_key :: String.t(), opts :: keyword()) :: {:ok, default_value :: term()} | {:error, :unauthorized | term()}`

*   **Descrição:** Redefine uma política de segurança para seu valor padrão do sistema.
*   **Retorno:** `{:ok, default_value_restored}` ou erro.

## ⚙️ 7. Configuração

O próprio `SecurityPolicyManager` pode ter algumas configurações no `Core.ConfigManager`:
*   `[:security, :policy_manager, :default_policy_values_module]` (Module): Módulo que define os valores padrão de fábrica para todas as políticas de segurança. Isso é usado pela função `reset_security_config`.
*   `[:security, :policy_manager, :rbac_permissions, :view_policy_prefix]` (String): Prefixo da permissão RBAC necessária para visualizar políticas (ex: `\"security.policy.view.\"`).
*   `[:security, :policy_manager, :rbac_permissions, :edit_policy_prefix]` (String): Prefixo da permissão RBAC necessária para editar políticas (ex: `\"security.policy.edit.\"`).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.ConfigManager`: Como backend de armazenamento para as políticas.
*   `Deeper_Hub.Core.Logger`, `Core.Metrics`, `Core.EventBus`.
*   `Deeper_Hub.RBAC`: Para verificar permissões de acesso e modificação das políticas.
*   `Deeper_Hub.Security.Validation.SecurityInputValidation`: Para validar os valores das políticas.
*   `Deeper_Hub.Audit`: Para registrar alterações nas políticas.

### 8.2. Bibliotecas Externas

*   Nenhuma específica, além das usadas pelos módulos Core.

## 🤝 9. Como Usar / Integração

*   **Módulos de Segurança:** Em vez de chamarem `Core.ConfigManager.get/3` diretamente para suas configurações operacionais, os módulos como `BruteForceProtection`, `RiskAssessment`, etc., devem chamar `SecurityPolicyManager.get_security_configs/2` (ou uma função mais específica se criada) para obter suas políticas. Isso garante que a obtenção de políticas também possa, se necessário, passar por uma camada de lógica (embora para leitura, a autorização seja menos comum do que para escrita).
    ```elixir
    # Em BruteForceProtectionService
    defp get_login_max_attempts do
      # Poderia ser Core.ConfigManager.get(\"security.policy.brute_force.login.max_attempts\", \"global\", 5)
      # Ou, para centralizar lógica de políticas de segurança:
      case SecurityPolicyManager.get_security_configs(nil, policy_area: \"brute_force.login\") do
        {:ok, %{\"security.policy.brute_force.login.max_attempts\" => val}} -> val
        _ -> 5 # Fallback para um padrão seguro do código
      end
    end
    ```
*   **Interfaces de Administração:** Qualquer UI ou comando de console que permita a visualização ou modificação de políticas de segurança deve usar o `SecurityPolicyManager` para garantir que as verificações de autorização e validação sejam aplicadas.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar o acesso e modificação de políticas com diferentes papéis de usuário (com e sem permissão).
*   Testar a validação de diferentes tipos de valores de política.
*   Testar a redefinição de políticas para o padrão.
*   Verificar se as alterações são corretamente persistidas no `ConfigManager` e se os eventos de auditoria são gerados.
*   Localização: `test/deeper_hub/security/policy/`.

### 10.2. Métricas

*   `deeper_hub.security.policy_manager.configs.viewed.count` (tags: `requesting_user_role`, `policy_area`)
*   `deeper_hub.security.policy_manager.configs.updated.count` (tags: `admin_user_role`, `policy_key`, `status` (`success`, `unauthorized`, `validation_failed`))
*   `deeper_hub.security.policy_manager.configs.reset.count` (tags: `admin_user_role`, `policy_key`)

### 10.3. Logs

*   **Nível INFO:** Alterações de política bem-sucedidas (quem, o quê, quando, porquê).
*   **Nível WARNING:** Tentativas não autorizadas de visualizar ou modificar políticas. Falhas de validação ao tentar definir uma política.
*   **Nível ERROR:** Erros internos no `SecurityPolicyService`.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :policy_manager, :config_access, :start | :stop | :exception]`
    *   Metadados: `%{user_id: id, action: :view | :update | :reset, keys_accessed: list_of_keys, authorized: boolean}`
*   `[:deeper_hub, :security, :policy_manager, :config_validation, :stop]`
    *   Metadados: `%{key: key, value_provided: val, is_valid: boolean, errors: errors_if_any}`

## ❌ 11. Tratamento de Erros

*   Falhas de autorização devem retornar claramente `{:error, :unauthorized}`.
*   Falhas de validação devem retornar `{:error, :validation_failed, details}`.
*   Se o `ConfigManager` falhar ao persistir uma política, o erro deve ser propagado.

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Permissões RBAC:** A definição de quais papéis podem gerenciar quais políticas é a principal linha de defesa. Essas permissões devem ser o mais granulares possível (ex: um papel pode gerenciar políticas de MFA, outro pode gerenciar políticas de firewall).
*   **Auditoria Imutável:** Os logs de auditoria para alterações de política devem ser protegidos contra adulteração.
*   **Valores Padrão Seguros:** O sistema deve funcionar de forma segura mesmo se nenhuma política for explicitamente configurada, usando os padrões de fábrica.

## 🧑‍💻 13. Contribuição

*   Ao adicionar novas áreas de política de segurança, defina as permissões RBAC correspondentes em `SecurityPolicyAuthorization`.
*   Adicione funções de validação em `SecurityInputValidation` para os novos tipos de política.
*   Garanta que os valores padrão para novas políticas sejam seguros.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar uma UI administrativa para facilitar o gerenciamento visual das políticas de segurança.
*   [ ] Adicionar versionamento de políticas, permitindo rollback para configurações anteriores.
*   [ ] Permitir a importação/exportação de conjuntos de políticas (ex: para replicar configurações entre ambientes).
*   [ ] Introduzir \"perfis de política de segurança\" (ex: \"Alta Segurança\", \"Conveniência Equilibrada\") que administradores podem aplicar globalmente.
*   [ ] Adicionar validações mais complexas entre políticas (ex: garantir que o TTL da sessão não seja menor que o timeout de inatividade do MFA).

---

*Última atualização: 2025-05-11*

---

Este módulo age como um guardião para as configurações de segurança.

Agora, podemos ir para `Deeper_Hub.Security.IPFirewallService` (que foi referenciado aqui e é um consumidor de políticas), ou talvez detalhar o `Deeper_Hub.Core.Cache`?"""),
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
                types.Part.from_text(text="""Entendido! Vamos detalhar o `Deeper_Hub.Security.IPFirewallService`. Este serviço é uma linha de defesa importante, controlando o acesso à aplicação com base em endereços IP.

---

