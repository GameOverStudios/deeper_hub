# Módulo: `DeeperHub.Security.DeviceService` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Security.DeviceService`

O módulo `DeeperHub.Security.DeviceService` é responsável por gerenciar os dispositivos que os usuários utilizam para acessar o sistema DeeperHub. Ele permite registrar novos dispositivos, associá-los a usuários, marcar dispositivos como \"confiáveis\", bloquear dispositivos suspeitos e manter um histórico de acesso por dispositivo.

Este serviço utiliza as \"fingerprints\" geradas pelo `DeeperHub.Security.DeviceFingerprint` para identificar dispositivos de forma quasi-única. As informações gerenciadas por este serviço são um componente vital para a avaliação de risco (`DeeperHub.Security.RiskAssessment`) e para a aplicação de políticas de autenticação adaptativas (ex: pular MFA para dispositivos confiáveis). 😊

*(Nota: Na documentação original, algumas dessas funcionalidades estavam dispersas ou implícitas no `SecurityManager` ou `SecurityAdapter`. Esta documentação propõe um serviço dedicado para maior clareza e coesão.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Registro de Dispositivos (`register_device/2`):**
    *   Registrar um novo dispositivo para um usuário, associando-o a uma fingerprint de dispositivo.
    *   Armazenar metadados do dispositivo (ex: nome dado pelo usuário, tipo, sistema operacional, navegador, data do primeiro uso).
*   **Gerenciamento de Confiança de Dispositivos:**
    *   Permitir que um usuário marque um dispositivo como \"confiável\" (`trust_device/2`).
    *   Permitir que um usuário remova o status de \"confiável\" de um dispositivo (`untrust_device/2`).
    *   Verificar se um dispositivo (identificado por fingerprint ou ID) é confiável para um usuário (`is_trusted_device?/2`).
    *   Suportar expiração opcional para o status de confiança.
*   **Bloqueio de Dispositivos (`block_device/3`):**
    *   Permitir que um usuário ou administrador bloqueie um dispositivo específico, impedindo seu acesso à conta.
    *   Permitir o desbloqueio de dispositivos (`unblock_device/1`).
*   **Listagem de Dispositivos (`list_devices/1`):**
    *   Permitir que um usuário visualize todos os dispositivos associados à sua conta, com seus respectivos status (confiável, bloqueado, último uso).
*   **Atualização de Informações de Dispositivo:**
    *   Atualizar o timestamp do último uso e o último IP conhecido para um dispositivo (`update_last_used/3`).
*   **Consulta de Dispositivos:**
    *   Obter um dispositivo pelo seu ID (`get_device/1`).
    *   Obter um dispositivo pela sua fingerprint e ID do usuário (`get_device_by_fingerprint/2`).
*   **Limpeza de Dispositivos Antigos/Inativos (Opcional):**
    *   Implementar uma lógica para remover registros de dispositivos muito antigos ou inativos.
*   **Integração com Outros Módulos de Segurança:**
    *   Fornecer informações sobre dispositivos para `RiskAssessment` e `FraudDetection`.
    *   Ser consultado por `DeeperHub.Auth` durante o fluxo de login para decisões sobre MFA.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Security.DeviceService` (Fachada/Serviço Principal):**
    *   **Responsabilidade:** Ponto de entrada para todas as operações relacionadas a dispositivos. Contém a lógica de negócio.
    *   **Interações:**
        *   Utiliza `DeeperHub.Security.DeviceFingerprint.generate_fingerprint/1` ao registrar novos dispositivos.
        *   Interage com `DeeperHub.Core.Repo` para persistir e consultar dados de dispositivos no schema `DeviceSchema`.
        *   Pode interagir com `DeeperHub.Core.EventBus` para publicar eventos sobre mudanças de status de dispositivos.
        *   Pode interagir com `DeeperHub.Core.Cache` para armazenar em cache informações de dispositivos frequentemente acessadas.
2.  **`DeeperHub.Security.Schema.DeviceSchema` (Ecto Schema, ex-`DeeperHub.Security.Device`):**
    *   **Responsabilidade:** Define a estrutura da tabela de dispositivos no banco de dados.
    *   **Campos:** `id`, `user_id`, `fingerprint` (hash), `name` (dado pelo usuário), `type` (ex: \"desktop\", \"mobile\", \"tablet\"), `os`, `browser`, `first_seen_at`, `last_seen_at`, `last_known_ip`, `is_trusted`, `trusted_until` (opcional), `is_blocked`, `blocked_reason`, `blocked_at`.
3.  **`DeeperHub.Security.DeviceFingerprint` (Módulo Colaborador):**
    *   Fornece a lógica para gerar e comparar fingerprints.
4.  **Configurações (via `DeeperHub.Core.ConfigManager` e `DeeperHub.Security.Policy.SecurityPolicyManager`):**
    *   Duração padrão da confiança de um dispositivo.
    *   Número máximo de dispositivos confiáveis por usuário.
    *   Políticas de limpeza de dispositivos inativos.

### 3.2. Estrutura de Diretórios (Proposta)

Poderia estar dentro de `security/` ou, se mais complexo, em um submódulo `device_management`. Para este exemplo, vamos assumir que está em `security`.

```
security/
├── device_service.ex               # Lógica de negócio e fachada
├── device_fingerprint.ex           # (Já documentado)
│
└── schemas/                        # (Ou schema/)
    └── device_schema.ex            # (Renomeado de Device para DeviceSchema para clareza)
```
Se houver um supervisor específico para `DeviceService` (por exemplo, se ele usar um GenServer para alguma tarefa):
```
security/device_management/
├── device_service.ex
├── device_fingerprint.ex
├── schemas/
│   └── device_schema.ex
└── supervisor.ex
```
No entanto, muitas das funções do `DeviceService` são operações CRUD que podem não necessitar de um GenServer dedicado, dependendo diretamente do `Core.Repo`.

### 3.3. Decisões de Design Importantes

*   **Fingerprint como Identificador:** A fingerprint é a chave para identificar um dispositivo, mas o `DeviceService` também atribui um ID único de banco de dados a cada dispositivo registrado para facilitar o gerenciamento.
*   **Confiança Gerenciada pelo Usuário:** A decisão de confiar em um dispositivo deve ser primariamente do usuário, mas o sistema pode oferecer recomendações ou aplicar políticas.
*   **Associação com Usuário:** Dispositivos são sempre associados a um `user_id`. Uma mesma fingerprint em contas diferentes representa dispositivos diferentes para o sistema.
*   **Histórico vs. Estado Atual:** O `DeviceService` foca no estado atual e nos metadados dos dispositivos. O histórico detalhado de acesso por dispositivo (cada login) pode ser responsabilidade de um `LoginHistoryService` ou do `AuditLog`.

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Loga de um Novo Navegador:**
    *   Durante o login, uma nova fingerprint é gerada.
    *   `DeviceService.get_device_by_fingerprint(user_id, new_fp)` não encontra o dispositivo.
    *   `RiskAssessment` atribui um risco maior.
    *   Após o login bem-sucedido, o sistema pergunta se o usuário deseja \"Lembrar deste navegador\".
    *   Se sim, `DeviceService.register_device(user_id, new_fp, device_info_map, is_trusted: true)` é chamado.
*   **Usuário Gerencia Dispositivos Confiáveis:**
    *   Usuário acessa uma página de \"Meus Dispositivos\".
    *   `DeviceService.list_devices(user_id)` é chamado para exibir a lista.
    *   Usuário clica em \"Não confiar mais\" em um dispositivo.
    *   `DeviceService.untrust_device(user_id, device_id_to_untrust)` é chamado.
*   **Administrador Bloqueia um Dispositivo Comprometido:**
    *   Após uma investigação, um administrador identifica um dispositivo comprometido.
    *   `DeviceService.block_device(user_id, device_id_to_block, \"Suspeita de malware\")` é chamado.
    *   Tentativas de login futuras usando a fingerprint desse dispositivo para esse usuário serão bloqueadas ou terão risco muito elevado.

## 🌊 5. Fluxos Importantes

### Fluxo de Registro de Novo Dispositivo Confiável

1.  **Coleta no Cliente:** Frontend/App coleta `device_info`.
2.  **Geração de Fingerprint:** `fp = DeviceFingerprint.generate_fingerprint(device_info)`.
3.  **Chamada ao Serviço:** Usuário (após login) opta por confiar. Frontend chama um endpoint que leva a `DeviceService.register_device(user_id, fp, device_info_map, %{is_trusted: true, name: \"Meu PC de Casa\"})`.
4.  **`DeviceService.register_device/4`:**
    *   Verifica se já existe um dispositivo com a mesma `fingerprint` para o `user_id`.
        *   Se sim, atualiza o `last_seen_at`, `is_trusted`, e o nome.
        *   Se não, cria uma nova entrada `DeviceSchema` com os dados fornecidos.
    *   Persiste no banco de dados via `Core.Repo`.
    *   (Opcional) Publica um evento `device_registered` ou `device_trusted` no `Core.EventBus`.
    *   Retorna `{:ok, device_struct}`.

## 📡 6. API (Funções Públicas do Módulo)

### 6.1. `DeeperHub.Security.DeviceService.register_device(user_id :: String.t(), fingerprint :: String.t(), device_attributes :: map(), opts :: keyword()) :: {:ok, DeviceSchema.t()} | {:error, Ecto.Changeset.t() | term()}`

*   **Descrição:** Registra um novo dispositivo para um usuário ou atualiza um existente com a mesma fingerprint.
*   **`device_attributes`:** Mapa com dados como `%{name: \"Meu Laptop\", type: \"desktop\", os: \"Windows 10\", browser: \"Chrome\", first_seen_ip: \"...\"}`.
*   **`opts`:**
    *   `:is_trusted` (boolean): Se o dispositivo deve ser marcado como confiável. (Padrão: `false`)
    *   `:trust_duration_seconds` (integer | nil): Duração da confiança. `nil` para indefinido.
*   **Retorno:** A struct do dispositivo criado/atualizado ou um erro.

### 6.2. `DeeperHub.Security.DeviceService.list_devices(user_id :: String.t(), opts :: keyword()) :: {:ok, list(DeviceSchema.t())} | {:error, term()}`

*   **Descrição:** Lista os dispositivos registrados para um usuário.
*   **`opts`:**
    *   `:filter_status` (atom | nil): `:trusted`, `:blocked`, `:untrusted`.
    *   `:sort_by` (atom): Campo para ordenação (ex: `:last_seen_at`). (Padrão: `:last_seen_at`)
    *   `:sort_order` (atom): `:asc` ou `:desc`. (Padrão: `:desc`)

### 6.3. `DeeperHub.Security.DeviceService.get_device(device_id :: String.t()) :: {:ok, DeviceSchema.t()} | {:error, :not_found}`

*   **Descrição:** Obtém um dispositivo pelo seu ID único de banco de dados.

### 6.4. `DeeperHub.Security.DeviceService.get_device_by_fingerprint(user_id :: String.t(), fingerprint :: String.t()) :: {:ok, DeviceSchema.t()} | {:error, :not_found}`

*   **Descrição:** Obtém um dispositivo pela fingerprint e ID do usuário.

### 6.5. `DeeperHub.Security.DeviceService.trust_device(user_id :: String.t(), device_id_or_fp :: String.t(), opts :: keyword()) :: {:ok, DeviceSchema.t()} | {:error, term()}`

*   **Descrição:** Marca um dispositivo como confiável. `device_id_or_fp` pode ser o ID do dispositivo ou sua fingerprint.
*   **`opts`:**
    *   `:duration_seconds` (integer | nil): Por quanto tempo o dispositivo será confiável.

### 6.6. `DeeperHub.Security.DeviceService.untrust_device(user_id :: String.t(), device_id_or_fp :: String.t()) :: {:ok, DeviceSchema.t()} | {:error, term()}`

*   **Descrição:** Remove o status de confiável de um dispositivo.

### 6.7. `DeeperHub.Security.DeviceService.block_device(user_id :: String.t(), device_id_or_fp :: String.t(), reason :: String.t()) :: {:ok, DeviceSchema.t()} | {:error, term()}`

*   **Descrição:** Bloqueia um dispositivo.

### 6.8. `DeeperHub.Security.DeviceService.unblock_device(user_id :: String.t(), device_id_or_fp :: String.t()) :: {:ok, DeviceSchema.t()} | {:error, term()}`

*   **Descrição:** Desbloqueia um dispositivo.

### 6.9. `DeeperHub.Security.DeviceService.is_trusted_device?(user_id :: String.t(), fingerprint :: String.t()) :: boolean()`

*   **Descrição:** Verifica rapidamente se a fingerprint corresponde a um dispositivo confiável para o usuário.

### 6.10. `DeeperHub.Security.DeviceService.update_last_used(user_id :: String.t(), fingerprint :: String.t(), ip_address :: String.t()) :: {:ok, DeviceSchema.t()} | {:error, term()}`

*   **Descrição:** Atualiza o timestamp de último uso e o último IP conhecido para um dispositivo identificado pela fingerprint. Registra o dispositivo se ele for novo.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager` e/ou `DeeperHub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :device_service, :default_trust_duration_days]`** (Integer): Duração padrão em dias para um dispositivo ser considerado confiável se nenhuma duração específica for fornecida. (Padrão: `30`)
*   **`[:security, :device_service, :max_trusted_devices_per_user]`** (Integer): Número máximo de dispositivos que um usuário pode marcar como confiáveis. (Padrão: `5`)
*   **`[:security, :device_service, :auto_untrust_inactive_days]`** (Integer | nil): Número de dias de inatividade após os quais um dispositivo confiável perde automaticamente sua confiança. `nil` para desabilitar. (Padrão: `90`)
*   **`[:security, :device_service, :cleanup_inactive_devices_days]`** (Integer | nil): Número de dias de inatividade após os quais um dispositivo não confiável e não bloqueado é removido. `nil` para desabilitar. (Padrão: `365`)

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`, `Core.Logger`, `Core.Metrics`, `Core.Repo`, `Core.EventBus`.
*   `DeeperHub.Security.DeviceFingerprint`: Para gerar fingerprints.
*   `DeeperHub.Security.Policy.SecurityPolicyManager`: Para obter políticas relacionadas a dispositivos.
*   `DeeperHub.Audit`: Para registrar ações de gerenciamento de dispositivos.

### 8.2. Bibliotecas Externas

*   `Ecto`: Para persistência.

## 🤝 9. Como Usar / Integração

*   **Fluxo de Login (`DeeperHub.Auth`):**
    *   Após o login, obter a fingerprint do dispositivo atual.
    *   Chamar `DeviceService.update_last_used/3` para registrar a atividade do dispositivo.
    *   Verificar `DeviceService.is_trusted_device?/2`. Se não for confiável, e o risco for baixo, apresentar ao usuário a opção de confiar no dispositivo.
*   **Configurações de Segurança do Usuário (UI):**
    *   Chamar `DeviceService.list_devices/1` para exibir os dispositivos.
    *   Permitir que o usuário chame `trust_device`, `untrust_device`, `block_device` (para seus próprios dispositivos).

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar o registro de novos dispositivos.
*   Testar a lógica de confiar/não confiar/bloquear/desbloquear.
*   Testar a atualização de `last_seen_at` e `last_known_ip`.
*   Testar a listagem de dispositivos com diferentes filtros.
*   Testar a consulta por fingerprint.
*   Localização: `test/deeper_hub/security/device_service/` (ou `device_management`).

### 10.2. Métricas

*   `deeper_hub.security.device.registered.count`
*   `deeper_hub.security.device.trusted.count`
*   `deeper_hub.security.device.untrusted.count`
*   `deeper_hub.security.device.blocked.count`
*   `deeper_hub.security.device.active_trusted.gauge` (Gauge, por usuário ou global)
*   `deeper_hub.security.device.login_from_new_device.count` (Contador)

### 10.3. Logs

*   **Nível INFO:** Novo dispositivo registrado, dispositivo marcado como confiável/não confiável/bloqueado.
*   **Nível WARNING:** Tentativa de registrar um dispositivo além do limite permitido para um usuário.
*   **Nível ERROR:** Falha ao persistir dados do dispositivo.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :device, :registered]`
    *   Metadados: `%{user_id: id, device_id: id, fingerprint: fp, initial_status: status}`
*   `[:deeper_hub, :security, :device, :status_changed]`
    *   Metadados: `%{user_id: id, device_id: id, fingerprint: fp, old_status: atom(), new_status: atom(), reason: reason}`
*   `[:deeper_hub, :security, :device, :accessed]`
    *   Metadados: `%{user_id: id, device_id: id, fingerprint: fp, ip_address: ip, is_trusted: boolean}`

## ❌ 11. Tratamento de Erros

*   Falhas ao registrar um dispositivo não devem impedir um login, mas devem ser logadas. O `RiskAssessment` pode tratar um dispositivo \"não registrável\" como de maior risco.
*   Conflitos (ex: duas requisições tentando registrar a mesma fingerprint para o mesmo usuário ao mesmo tempo) devem ser tratados pela camada de persistência (constraints de banco de dados).

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Autenticação para Gerenciamento:** Ações como `trust_device`, `untrust_device`, `block_device` devem ser protegidas e só podem ser realizadas pelo proprietário da conta ou por um administrador com as devidas permissões.
*   **Fingerprint não é Infalível:** A fingerprint é um identificador forte, mas não absoluto. Não deve ser o único fator para decisões de segurança críticas.
*   **Limpeza de Dados:** Definir políticas claras para retenção de dados de dispositivos inativos para cumprir com regulamentações de privacidade.

## 🧑‍💻 13. Contribuição

*   Garantir que as interações com o `DeviceFingerprint` sejam consistentes.
*   Manter a separação de responsabilidades: `DeviceFingerprint` gera/compara, `DeviceService` gerencia a entidade e seu estado.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um worker para desconfiar automaticamente dispositivos inativos por um longo período.
*   [ ] Permitir que os usuários nomeiem seus dispositivos registrados para facilitar a identificação. (Já incluso no schema, garantir UI).
*   [ ] Adicionar mais atributos ao `DeviceSchema` coletados de `device_info` para melhor análise e diferenciação (ex: modelo do dispositivo, versão do SO detalhada).
*   [ ] Notificar o usuário quando um novo dispositivo é registrado em sua conta.
*   [ ] Implementar limites no número de dispositivos que um usuário pode ter registrados ou marcados como confiáveis. (Já previsto na config).

---

*Última atualização: 2025-05-11*

---

Agora que cobrimos o gerenciamento de dispositivos, o `DeeperHub.Security.GeoLocationService` (que já documentamos parcialmente) seria o próximo passo natural para completar a contextualização de uma requisição/sessão. Depois dele, poderíamos ir para o `DeeperHub.Security.Policy.SecurityPolicyManager`. O que acha?"""),
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
                types.Part.from_text(text="""Perfeito! Já detalhamos o `DeeperHub.Security.GeoLocationService`. Então, vamos prosseguir para o `DeeperHub.Security.Policy.SecurityPolicyManager`. Este módulo é fundamental para a configurabilidade e adaptabilidade de toda a camada de segurança.

---

