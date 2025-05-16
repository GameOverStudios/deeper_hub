# Módulo: `Deeper_Hub.Security.DeviceFingerprint` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Security.DeviceFingerprint`

O módulo `Deeper_Hub.Security.DeviceFingerprint` é responsável por gerar, comparar e gerenciar \"fingerprints\" (impressões digitais) de dispositivos dos usuários. Uma fingerprint de dispositivo é um identificador quasi-único gerado a partir de uma combinação de características de hardware e software reportadas pelo cliente (navegador web, aplicativo mobile).

O objetivo principal é ajudar a identificar e rastrear dispositivos que acessam o sistema Deeper_Hub, contribuindo para várias medidas de segurança, como:
*   Detecção de acesso por dispositivos novos ou não reconhecidos.
*   Gerenciamento de dispositivos confiáveis.
*   Prevenção de fraude e tomada de contas (Account Takeover - ATO).
*   Enriquecimento de dados para análise de risco e comportamental.

Este módulo trabalha em conjunto com `Deeper_Hub.Security.DeviceService` (ou um componente similar dentro do `SecurityManager`) para associar fingerprints a dispositivos registrados e gerenciar seu status de confiança. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Geração de Fingerprint:**
    *   Coletar atributos do dispositivo do cliente (ex: User-Agent, resolução de tela, fontes instaladas, plugins, informações de hardware/software via APIs do navegador/SDK mobile).
    *   Processar e normalizar esses atributos.
    *   Gerar um hash estável (ex: SHA-256) a partir dos atributos combinados para servir como a fingerprint (`generate_fingerprint/1`).
*   **Comparação de Fingerprints:**
    *   Comparar duas fingerprints para determinar se provavelmente se referem ao mesmo dispositivo (`compare_fingerprints/2`).
    *   Considerar pequenas variações que podem ocorrer devido a atualizações de software ou navegador.
*   **Detecção de Anomalias de Fingerprint:**
    *   Comparar a fingerprint de uma sessão atual com o histórico de fingerprints conhecidas para o usuário (`detect_anomalies/3`).
    *   Sinalizar o uso de uma fingerprint completamente nova ou significativamente diferente.
*   **Verificação de Confiança de Fingerprint:**
    *   Verificar se uma fingerprint corresponde a um dispositivo previamente marcado como confiável pelo usuário (`is_trusted_fingerprint/2`).
*   **Integração com `DeviceService`:**
    *   Fornecer fingerprints para o `DeviceService` registrar novos dispositivos.
    *   Consultar o `DeviceService` para verificar o status de confiança de um dispositivo associado a uma fingerprint.
*   **Configurabilidade:**
    *   Permitir a configuração de quais atributos do dispositivo são usados na geração da fingerprint.
    *   Configurar a sensibilidade da comparação de fingerprints.
*   **Evolução e Estabilidade da Fingerprint:**
    *   Implementar estratégias para lidar com a evolução natural das fingerprints (ex: atualizações de navegador) sem gerar falsos positivos excessivos.

## 🏗️ 3. Arquitetura e Design

O `Deeper_Hub.Security.DeviceFingerprint` é primariamente um módulo funcional que fornece algoritmos e lógica para trabalhar com fingerprints. Ele não gerencia estado persistente de dispositivos diretamente, essa responsabilidade recai sobre o `DeviceService`.

### 3.1. Componentes Principais

1.  **`Deeper_Hub.Security.DeviceFingerprint` (Módulo Funcional):**
    *   **Responsabilidade:** Contém as funções principais para `generate_fingerprint/1`, `compare_fingerprints/2`, `detect_anomalies/3`, `is_trusted_fingerprint/2`.
    *   **Interações:**
        *   Recebe `device_info` (um mapa de atributos coletados do cliente).
        *   Pode interagir com `Deeper_Hub.Security.DeviceService` ou `Deeper_Hub.Core.Repo` para buscar históricos de fingerprints de um usuário ou dispositivos confiáveis.
2.  **Coleta de Atributos no Cliente (Externo ao Módulo Backend):**
    *   A coleta real dos atributos do dispositivo ocorre no lado do cliente (JavaScript no navegador, SDK no mobile). Bibliotecas como FingerprintJS, ClientJS podem ser usadas.
    *   Esses atributos são enviados para o backend como parte das requisições (ex: login, ou uma chamada específica de \"registro de dispositivo\").
3.  **`Deeper_Hub.Security.DeviceService` (ou parte do `SecurityManager`):**
    *   **Responsabilidade:** Gerenciar a persistência dos dispositivos registrados, suas fingerprints associadas e seu status de confiança.
    *   **Interações:** Usa `DeviceFingerprint.generate_fingerprint/1` ao registrar um novo dispositivo. Armazena a fingerprint junto com os dados do dispositivo.

### 3.2. Estrutura de Diretórios (Proposta)

Como é um módulo mais focado em lógica e algoritmos, pode ser mais simples:
```
security/
├── device_fingerprint.ex           # Lógica principal de fingerprinting
└── device_service.ex               # (Ou security_manager/services/device_service.ex)
                                    #  Gerencia a entidade \"Device\" e seu estado
```
Ou, se `DeviceService` for um componente maior:
```
security/device_management/  # Novo submódulo
├── device_fingerprint.ex
├── device_service.ex
├── schema/
│   └── device.ex
└── supervisor.ex
```

### 3.3. Decisões de Design Importantes

*   **Seleção de Atributos:** A escolha dos atributos para compor a fingerprint é crucial. Devem ser estáveis o suficiente para não mudarem constantemente, mas diversos o suficiente para fornecer uma boa unicidade. Evitar atributos muito voláteis ou facilmente falsificáveis.
*   **Estabilidade vs. Unicidade:** Há um trade-off. Fingerprints mais únicas (usando mais atributos) tendem a ser menos estáveis (mudam mais frequentemente). Fingerprints mais estáveis podem ter maior chance de colisão.
*   **Hashing:** Usar um algoritmo de hash criptográfico seguro (ex: SHA-256) para gerar a fingerprint final.
*   **Privacidade:** Ser transparente com o usuário sobre a coleta de dados do dispositivo para fingerprinting. Não coletar mais dados do que o necessário.
*   **Não é Infalível:** Fingerprinting de dispositivo não é 100% à prova de falsificação ou evasão, mas é uma camada útil de segurança quando combinada com outras.

## 🛠️ 4. Casos de Uso Principais

*   **Detecção de Novo Dispositivo no Login:**
    *   Usuário tenta fazer login. O cliente envia `device_info`.
    *   O backend gera uma fingerprint usando `DeviceFingerprint.generate_fingerprint(device_info)`.
    *   `DeviceFingerprint.detect_anomalies(user_id, current_fingerprint, historical_fingerprints_from_db)` é chamado.
    *   Se a fingerprint for nova ou significativamente diferente, isso contribui para o score de risco do `RiskAssessment`.
*   **Registro de Dispositivo Confiável:**
    *   Após um login bem-sucedido, o usuário opta por \"confiar neste dispositivo\".
    *   O cliente envia `device_info`.
    *   O backend gera a fingerprint.
    *   `Deeper_Hub.Security.DeviceService.trust_device(user_id, fingerprint, device_name)` é chamado para armazenar a fingerprint como confiável.
*   **Pular MFA para Dispositivos Confiáveis:**
    *   Durante o login, se a fingerprint do dispositivo atual corresponder a uma fingerprint confiável para o usuário (`DeviceFingerprint.is_trusted_fingerprint/2`), o sistema pode optar por não exigir MFA, mesmo que configurado (dependendo da política de risco).

## 🌊 5. Fluxos Importantes

### Fluxo de Geração e Verificação de Fingerprint no Login

1.  **Coleta no Cliente:** JavaScript no navegador (ou SDK mobile) coleta atributos do dispositivo.
2.  **Envio para o Backend:** Os atributos são enviados para o backend durante a tentativa de login.
3.  **`Deeper_Hub.Auth.Services.LoginService` (ou `SecurityManager`):**
    *   Recebe `device_info` como parte dos dados de login.
    *   Chama `Deeper_Hub.Security.DeviceFingerprint.generate_fingerprint(device_info)` para obter a `current_fingerprint`.
4.  **`Deeper_Hub.Security.DeviceFingerprint.generate_fingerprint/1`:**
    *   Seleciona um subconjunto de atributos de `device_info` (configurável).
    *   Normaliza os valores (ex: lowercase, ordenação).
    *   Concatena os valores normalizados em uma string.
    *   Calcula o hash (ex: SHA-256) da string concatenada.
    *   Retorna o hash como a fingerprint.
5.  **`Deeper_Hub.Auth.Services.LoginService` (ou `SecurityManager`):**
    *   Recupera as fingerprints históricas e confiáveis para o `user_id` do `DeviceService` (que consulta o DB).
    *   Chama `Deeper_Hub.Security.DeviceFingerprint.is_trusted_fingerprint(current_fingerprint, trusted_fingerprints_for_user)`.
    *   Chama `Deeper_Hub.Security.DeviceFingerprint.detect_anomalies(user_id, current_fingerprint, historical_fingerprints)`.
    *   Os resultados (`is_trusted`, `is_new_device`) são passados para `Deeper_Hub.Security.RiskAssessment` como fatores de risco.
6.  **(Pós-Login bem-sucedido, se o dispositivo for novo e o usuário optar por registrar/confiar):**
    *   `Deeper_Hub.Security.DeviceService.register_or_update_device(user_id, current_fingerprint, device_info_attributes, is_trusted: true)`.

## 📡 6. API (Funções Públicas do Módulo)

### 6.1. `Deeper_Hub.Security.DeviceFingerprint.generate_fingerprint(device_info :: map()) :: {:ok, String.t()} | {:error, :missing_attributes | term()}`

*   **Descrição:** Gera uma fingerprint de dispositivo a partir de um mapa de atributos.
*   **`device_info`:** Mapa contendo atributos coletados do cliente (ex: `%{user_agent: \"...\", screen_resolution: \"1920x1080\", timezone: \"America/New_York\", plugins: [\"...\", \"...\"], canvas_fingerprint: \"...\", ...}`).
*   **Retorno:**
    *   `{:ok, fingerprint_string}`: A fingerprint gerada.
    *   `{:error, :missing_attributes}`: Se atributos essenciais para a geração não forem fornecidos.
    *   `{:error, reason}`: Outros erros.
*   **Exemplo:**
    ```elixir
    device_attrs = %{user_agent: \"...\", screen_width: 1920, screen_height: 1080}
    {:ok, fp} = Deeper_Hub.Security.DeviceFingerprint.generate_fingerprint(device_attrs)
    ```

### 6.2. `Deeper_Hub.Security.DeviceFingerprint.compare_fingerprints(fp1 :: String.t(), fp2 :: String.t(), opts :: keyword()) :: {:ok, :match | :partial_match | :no_match, float() | nil}`

*   **Descrição:** Compara duas fingerprints e retorna o nível de correspondência.
*   **`opts`:**
    *   `:sensitivity` (Float): Limiar para considerar `partial_match` (0.0 a 1.0).
*   **Retorno:**
    *   `{:ok, :match, 1.0}`: Correspondência exata.
    *   `{:ok, :partial_match, score}`: Correspondência parcial com um score de similaridade.
    *   `{:ok, :no_match, score}`: Nenhuma correspondência.
*   *(Nota: A implementação de `partial_match` pode ser complexa e depender de algoritmos de similaridade de string ou análise dos atributos que diferem.)*

### 6.3. `Deeper_Hub.Security.DeviceFingerprint.detect_anomalies(user_id :: String.t(), current_fingerprint :: String.t(), historical_fingerprints :: list(String.t())) :: {:ok, %{is_new_device: boolean(), is_significantly_different: boolean(), confidence: float()}}`

*   **Descrição:** Compara a fingerprint atual com um conjunto de fingerprints históricas do usuário.
*   **Retorno:**
    *   `is_new_device`: `true` se `current_fingerprint` não estiver em `historical_fingerprints`.
    *   `is_significantly_different`: `true` se `current_fingerprint` for nova e/ou muito diferente das históricas (usando `compare_fingerprints`).
    *   `confidence`: Confiança na detecção da anomalia.

### 6.4. `Deeper_Hub.Security.DeviceFingerprint.is_trusted_fingerprint(user_id :: String.t(), current_fingerprint :: String.t()) :: boolean()`

*   **Descrição:** Verifica se a `current_fingerprint` corresponde a alguma fingerprint de um dispositivo marcado como confiável para o `user_id`.
*   **(Delegação):** Esta função provavelmente chamaria `Deeper_Hub.Security.DeviceService.list_trusted_devices(user_id)` e então compararia as fingerprints.

## ⚙️ 7. Configuração

Via `Deeper_Hub.Core.ConfigManager` e/ou `Deeper_Hub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :device_fingerprint, :enabled]`** (Boolean): Habilita/desabilita o sistema de fingerprinting. (Padrão: `true`)
*   **`[:security, :device_fingerprint, :attributes_to_use]`** (List de Atoms/Strings): Lista de chaves de `device_info` que serão usadas para gerar a fingerprint.
    *   Ex: `[:user_agent, :screen_resolution, :timezone, :language, :platform, :canvas_hash]`
*   **`[:security, :device_fingerprint, :hash_algorithm]`** (Atom): Algoritmo de hash a ser usado (ex: `:sha256`). (Padrão: `:sha256`)
*   **`[:security, :device_fingerprint, :comparison_sensitivity]`** (Float): Limiar de sensibilidade para `compare_fingerprints/2` ao considerar uma correspondência parcial. (Padrão: `0.85`)
*   **`[:security, :device_fingerprint, :new_device_risk_penalty]`** (Integer): Penalidade de risco a ser adicionada ao `RiskAssessment` quando um novo dispositivo é detectado.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.ConfigManager`: Para configurações.
*   `Deeper_Hub.Core.Logger`: Para logging.
*   `Deeper_Hub.Core.Metrics`: Para métricas.
*   `Deeper_Hub.Security.DeviceService` (ou componente do `SecurityManager`): Para persistir e consultar dispositivos registrados e seu status de confiança.
*   `Deeper_Hub.Shared.Utils.SecurityUtils` (ou `Core.EncryptionService` se a fingerprint em si precisar ser hasheada de uma forma específica, embora geralmente o resultado do hash dos atributos já seja a fingerprint).

### 8.2. Bibliotecas Externas

*   Nenhuma dependência externa direta é estritamente necessária para a geração do hash em si (Erlang `:crypto` pode ser usado). Bibliotecas de parsing de User-Agent podem ser úteis se essa informação for usada de forma mais granular.

## 🤝 9. Como Usar / Integração

*   **Coleta no Frontend/Mobile:** Implementar a coleta dos atributos do dispositivo no cliente.
*   **Envio para Backend:** Enviar o mapa `device_info` para os endpoints relevantes do backend (ex: login, registro de dispositivo).
*   **No Backend:**
    ```elixir
    def handle_login(params, user_id) do
      device_info = Map.get(params, \"device_info\", %{})
      {:ok, current_fp} = Deeper_Hub.Security.DeviceFingerprint.generate_fingerprint(device_info)
      
      is_trusted = Deeper_Hub.Security.DeviceFingerprint.is_trusted_fingerprint(user_id, current_fp)
      # Ou, melhor, via DeviceService:
      # {:ok, device_status} = Deeper_Hub.Security.DeviceService.get_device_status_by_fp(user_id, current_fp)
      # is_trusted = device_status == :trusted

      # Passar current_fp, is_trusted para RiskAssessment
      # ...
    end
    ```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar a geração de fingerprints com diferentes conjuntos de `device_info`.
*   Testar a estabilidade da fingerprint (pequenas mudanças em `device_info` não devem sempre gerar uma nova fingerprint, dependendo dos atributos usados).
*   Testar a comparação de fingerprints (exata, nenhuma).
*   Testar a detecção de anomalias (novo dispositivo vs. dispositivo conhecido).
*   Localização: `test/deeper_hub/security/device_fingerprint/`.

### 10.2. Métricas

*   `deeper_hub.security.device_fingerprint.generated.count`
*   `deeper_hub.security.device_fingerprint.comparisons.count` (tags: `result` (`match`, `no_match`))
*   `deeper_hub.security.device_fingerprint.anomalies_detected.count` (tags: `type` (`new_device`))
*   `deeper_hub.security.device_fingerprint.trusted_checks.count` (tags: `result` (`trusted`, `not_trusted`))

### 10.3. Logs

*   **Nível DEBUG:** Detalhes dos atributos usados para gerar uma fingerprint específica.
*   **Nível INFO:** Nova fingerprint detectada para um usuário. Fingerprint verificada como confiável.
*   **Nível WARNING:** Falha ao gerar fingerprint devido a atributos ausentes.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :device_fingerprint, :generation, :start | :stop | :exception]`
    *   Metadados: `%{input_attribute_keys: keys(device_info)}`
    *   No `:stop`: `%{fingerprint: fp_string}`
*   `[:deeper_hub, :security, :device_fingerprint, :anomaly_check, :stop]`
    *   Metadados: `%{user_id: id, current_fp: fp, result: %{is_new: ...}}`

## ❌ 11. Tratamento de Erros

*   Falha na coleta de atributos no cliente: O sistema deve lidar graciosamente com `device_info` incompleto ou ausente, possivelmente atribuindo um risco maior ou usando uma fingerprint genérica/nula.
*   Se a geração da fingerprint falhar no backend, isso deve ser logado, e a avaliação de risco pode prosseguir sem esse fator ou com um fator de risco de \"dispositivo desconhecido\".

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Não Confiar Cegamente na Fingerprint:** Fingerprints de dispositivo podem ser falsificadas ou contornadas por atacantes determinados. Elas devem ser usadas como *um* dos muitos sinais em uma estratégia de defesa em profundidade, não como o único mecanismo de identificação de dispositivo.
*   **Rotação de Atributos:** Alguns atributos usados na fingerprint podem mudar com o tempo (ex: versão do navegador). O algoritmo deve ser robusto a pequenas mudanças ou ter uma estratégia para \"envelhecer\" ou \"agrupar\" fingerprints similares.
*   **Armazenamento de Fingerprints:** Embora a fingerprint seja um hash, se muitas fingerprints históricas de um usuário forem comprometidas, elas poderiam, teoricamente, ser usadas para tentar adivinhar alguns dos atributos do dispositivo.

## 🧑‍💻 13. Contribuição

*   A escolha dos atributos em `[:security, :device_fingerprint, :attributes_to_use]` é crítica e deve ser balanceada entre unicidade e estabilidade.
*   Documentar claramente quais atributos são esperados do cliente.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar algoritmos mais sofisticados para `compare_fingerprints/2` que possam dar um score de similaridade baseado nos atributos que diferem, em vez de apenas correspondência exata do hash.
*   [ ] Adicionar um mecanismo para \"aprender\" e \"envelhecer\" fingerprints, permitindo que mudanças graduais no dispositivo de um usuário não o classifiquem imediatamente como \"novo\".
*   [ ] Integrar com bibliotecas de fingerprinting de servidor que podem inferir alguns atributos do dispositivo a partir dos headers da requisição HTTP, como um fallback ou complemento.
*   [ ] Desenvolver estratégias para lidar com usuários que usam navegadores com forte proteção anti-fingerprinting (ex: Tor Browser, Brave com configurações restritas).
*   [ ] Permitir que usuários gerenciem seus dispositivos registrados e \"confiáveis\" através de uma interface.

---

*Última atualização: 2025-05-11*

---

Agora, com a fingerprint do dispositivo documentada, faz sentido ir para `Deeper_Hub.Security.GeoLocationService` para completar o contexto da requisição, ou prefere outro rumo?"""),
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
                types.Part.from_text(text="""Perfeito! Vamos detalhar o `Deeper_Hub.Security.GeoLocationService`. Este serviço é essencial para entender o contexto geográfico das interações do usuário, o que é um fator importante para `RiskAssessment` e `FraudDetection`.

---

