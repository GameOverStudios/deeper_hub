# Módulo: `DeeperHub.Security.DataMasking` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Security.DataMasking`

O módulo `DeeperHub.Security.DataMasking` é responsável por **mascarar (ou ofuscar) dados sensíveis** dentro do sistema DeeperHub. O objetivo é proteger informações confidenciais de serem expostas em logs, interfaces de usuário (especialmente para administradores ou suporte), relatórios ou qualquer outro local onde o dado completo não seja estritamente necessário.

Ele fornece funcionalidades para mascarar diferentes tipos de dados, como CPFs, números de cartão de crédito, emails, telefones, e também permite mascarar campos específicos dentro de estruturas de dados maiores (mapas). Este módulo ajuda a cumprir com regulamentações de privacidade (como LGPD/GDPR) e a reduzir o risco de vazamento de dados. 😊

*(Nota: A documentação original tinha `DeeperHub.Security.DataMasking.DataMaskingService` e `DataMaskingFacade`. Esta documentação consolida a fachada principal em `DeeperHub.Security.DataMasking` e a lógica no `DataMaskingService`.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Mascaramento de Tipos de Dados Específicos:**
    *   Mascarar números de CPF/CNPJ (`mask_cpf/2`).
    *   Mascarar números de cartão de crédito (`mask_credit_card/2`).
    *   Mascarar endereços de email (`mask_email/2`).
    *   Mascarar números de telefone (`mask_phone/2`).
    *   (Extensível) Mascarar outros tipos de documentos ou identificadores.
*   **Mascaramento Genérico de Strings:**
    *   Aplicar mascaramento a strings genéricas, mantendo uma porção visível (ex: primeiros/últimos N caracteres).
*   **Mascaramento de Dados em Estruturas (Mapas/Structs):**
    *   Mascarar valores de chaves específicas dentro de mapas ou structs (`mask_sensitive_map/3`).
    *   Suporte a mascaramento recursivo em estruturas aninhadas.
*   **Mascaramento para Logs (`mask_for_log/2`):**
    *   Uma função de conveniência para aplicar mascaramento a dados (strings ou mapas) antes de serem enviados para o `Core.Logger`.
    *   Identificar automaticamente e mascarar dados sensíveis comuns em strings de log.
*   **Configurabilidade de Padrões de Mascaramento:**
    *   Permitir a configuração de como cada tipo de dado é mascarado (ex: quantos dígitos do cartão de crédito manter visíveis, qual parte do email ofuscar).
    *   Definir o caractere de mascaramento (ex: `*`, `#`, `X`).
*   **Políticas de Mascaramento Contextuais (Opcional):**
    *   Permitir diferentes níveis ou estilos de mascaramento dependendo do contexto ou do papel do usuário que está visualizando os dados.
*   **Integração com `LogSanitizer` e `ResponseSanitizer`:**
    *   Este módulo pode ser usado internamente por `LogSanitizer` e `ResponseSanitizer` para aplicar as regras de mascaramento.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Security.DataMasking` (Fachada Pública):**
    *   Ponto de entrada para todas as operações de mascaramento.
    *   Delega para o `DataMaskingService`.
2.  **`DeeperHub.Security.DataMasking.Services.DataMaskingService` (Módulo Funcional):**
    *   **Responsabilidade:** Contém a lógica principal para aplicar as diferentes técnicas de mascaramento.
    *   Não gerencia estado, as regras de mascaramento são obtidas do `Core.ConfigManager` ou passadas como opções.
    *   Utiliza regex e coordenação de strings para realizar o mascaramento.
    *   **Interações:**
        *   `DeeperHub.Core.ConfigManager`: Para obter padrões de mascaramento padrão, caracteres de substituição, etc.
3.  **Configurações (via `DeeperHub.Core.ConfigManager` e `DeeperHub.Security.Policy.SecurityPolicyManager`):**
    *   Padrões de regex para identificar dados a serem mascarados (ex: regex para CPF, Cartão).
    *   Formatos de mascaramento (ex: `cpf_mask: \"###.***.***-##\"`).
    *   Lista de chaves sensíveis padrão para `mask_sensitive_map/3` e `mask_for_log/2`.

### 3.2. Estrutura de Diretórios (Proposta)

```
security/data_masking/
├── data_masking.ex                 # Fachada Pública
│
└── services/
    └── data_masking_service.ex     # Lógica principal de mascaramento
```
*(Este módulo tende a ser mais funcional e pode não necessitar de GenServers ou supervisores próprios, a menos que haja uma necessidade de gerenciar dinamicamente regras complexas de mascaramento com estado.)*

### 3.3. Decisões de Design Importantes

*   **Não Reversível:** O mascaramento é uma operação de mão única; os dados originais não devem ser recuperáveis a partir da versão mascarada.
*   **Equilíbrio entre Utilidade e Segurança:** O mascaramento deve ocultar informações suficientes para proteger a privacidade, mas ainda pode deixar partes visíveis para fins de identificação ou depuração (ex: últimos 4 dígitos do cartão).
*   **Consistência:** Os mesmos tipos de dados devem ser mascarados de forma consistente em toda a aplicação.
*   **Performance:** As funções de mascaramento devem ser eficientes, especialmente se aplicadas a grandes volumes de dados ou em caminhos críticos de log/resposta.

## 🛠️ 4. Casos de Uso Principais

*   **Exibição de Dados de Usuário em Painel de Suporte:**
    *   Um agente de suporte visualiza os detalhes de um usuário.
    *   Antes de exibir, o serviço chama `DataMasking.mask_cpf(user.cpf)`, `DataMasking.mask_email(user.email)`.
*   **Registro de Log de uma Transação:**
    *   O módulo financeiro vai logar os detalhes de uma transação.
    *   Chama `Core.Logger.info(\"Transação processada\", DataMasking.mask_for_log(transaction_details, sensitive_keys: [:credit_card_number, :cvv]))`.
*   **Resposta de API com Dados Parcialmente Sensíveis:**
    *   Uma API retorna informações de um pedido, incluindo os últimos 4 dígitos do cartão.
    *   O controller, antes de enviar a resposta, chama `DataMasking.mask_credit_card(full_card_number, visible_digits: 4, preserve_brand: true)`.

## 🌊 5. Fluxos Importantes

### Fluxo de Mascaramento de um Mapa de Dados para Log

1.  **Módulo Chamador:** Tem um mapa `data = %{user_id: 1, action: \"login\", details: %{ip: \"1.2.3.4\", password_attempt: \"secret123\"}}`.
2.  Prepara para logar: `Logger.info(\"Tentativa de Login\", DataMasking.mask_for_log(data, sensitive_keys: [:password_attempt]))`.
3.  **`DataMasking.mask_for_log/2` (Fachada):**
    *   Delega para `DataMaskingService.mask_sensitive_map(data, [:password_attempt], opts)`.
4.  **`DataMaskingService.mask_sensitive_map/3`:**
    *   Itera sobre as chaves do mapa.
    *   Se uma chave está na lista `sensitive_keys` (ou em uma lista padrão de chaves sensíveis configurada):
        *   Substitui seu valor por um placeholder (ex: `\"[REDACTED]\"` ou `\"[MASKED]\"`).
    *   Se um valor for um mapa aninhado e a opção recursiva estiver ativa, chama-se recursivamente.
    *   Se um valor for uma string e a opção de detectar padrões sensíveis em strings estiver ativa, pode chamar `mask_sensitive_data/2` nessa string.
5.  **Resultado:** O mapa mascarado é retornado (ex: `%{user_id: 1, action: \"login\", details: %{ip: \"1.2.3.4\", password_attempt: \"[REDACTED]\"}}`) e passado para o `Core.Logger`.

## 📡 6. API (Funções Públicas da Fachada)

*(Baseado na documentação original, com alguns refinamentos e adições)*

### 6.1. `DeeperHub.Security.DataMasking.mask_sensitive_data(text :: String.t(), opts :: keyword()) :: {:ok, String.t()} | {:error, term()}`

*   **Descrição:** Tenta identificar e mascarar automaticamente vários tipos de dados sensíveis (CPF, email, cartão, etc.) dentro de uma string de texto livre.
*   **`opts`:**
    *   `:types_to_mask` (list(atom)): Lista de tipos a procurar (ex: `[:cpf, :email, :credit_card]`). Se omitido, tenta todos os tipos configurados.
    *   `:mask_char` (String.t): Caractere a ser usado para mascaramento. (Padrão: `*`)
    *   `:custom_patterns` (map): Mapa de `{type_atom, regex}` para padrões de detecção customizados.
*   **Exemplo:**
    ```elixir
    text = \"Contato: joao@example.com, CPF: 123.456.789-00.\"
    {:ok, masked} = DataMasking.mask_sensitive_data(text)
    # masked poderia ser \"Contato: j***@e******.com, CPF: ***.***.***-00.\"
    ```

### 6.2. `DeeperHub.Security.DataMasking.mask_sensitive_map(data_map :: map(), sensitive_keys :: list(atom() | String.t()), opts :: keyword()) :: {:ok, map()} | {:error, term()}`

*   **Descrição:** Mascara os valores das chaves especificadas em `sensitive_keys` dentro de `data_map`.
*   **`opts`:**
    *   `:replacement_value` (String.t): Valor a ser usado para substituição. (Padrão: `\"[REDACTED]\"`)
    *   `:recursive` (boolean): Se deve aplicar o mascaramento a mapas aninhados. (Padrão: `true`)
    *   `:apply_type_specific_masking` (boolean): Se `true`, para chaves conhecidas (ex: `:email`, `:cpf`), tenta aplicar mascaramento específico do tipo em vez de apenas `replacement_value`. (Padrão: `false`)

### 6.3. Funções Específicas de Tipo:

*   **`DeeperHub.Security.DataMasking.mask_email(email :: String.t(), opts :: keyword()) :: {:ok, String.t()}`**
    *   `opts`: `:visible_prefix_chars` (int, Padrão: 1), `:visible_domain_chars` (int, Padrão: 0), `:preserve_domain_extension` (bool, Padrão: true).
    *   Ex: `j***@e******.com`
*   **`DeeperHub.Security.DataMasking.mask_cpf(cpf :: String.t(), opts :: keyword()) :: {:ok, String.t()}`**
    *   `opts`: `:visible_digits_start` (int, Padrão: 3), `:visible_digits_end` (int, Padrão: 2).
    *   Ex: `***.456.789-**` ou `123.***.***-00`.
*   **`DeeperHub.Security.DataMasking.mask_credit_card(card_number :: String.t(), opts :: keyword()) :: {:ok, String.t()}`**
    *   `opts`: `:visible_last_digits` (int, Padrão: 4), `:visible_first_digits` (int, Padrão: 0 ou 6 para preservar BIN).
    *   Ex: `****-****-****-3456`.
*   **`DeeperHub.Security.DataMasking.mask_phone(phone :: String.t(), opts :: keyword()) :: {:ok, String.t()}`**
    *   `opts`: `:visible_last_digits` (int, Padrão: 4), `:preserve_prefix_chars` (int, Padrão: 0, mas pode ser usado para DDD + código país).
    *   Ex: `(11) *****-4321`.

### 6.4. `DeeperHub.Security.DataMasking.mask_for_log(data :: String.t() | map(), opts :: keyword()) :: String.t() | map()`

*   **Descrição:** Função de conveniência que aplica `mask_sensitive_data/2` se `data` for string, ou `mask_sensitive_map/3` se for mapa. Usa uma lista padrão de `sensitive_keys` configurada para mapas.
*   **`opts`:** Pode encaminhar opções para as funções subjacentes.
    *   `:default_sensitive_keys_for_log` (list): Sobrescreve a lista padrão de chaves para mascarar em logs.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager` e/ou `DeeperHub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :data_masking, :enabled]`** (Boolean): Habilita/desabilita o mascaramento. (Padrão: `true`)
*   **`[:security, :data_masking, :default_mask_char]`** (String): Caractere padrão para mascaramento. (Padrão: `\"*\"`)
*   **`[:security, :data_masking, :default_redacted_placeholder]`** (String): Placeholder para campos de mapa totalmente redigidos. (Padrão: `\"[REDACTED]\"`)
*   **`[:security, :data_masking, :log_masking_sensitive_keys]`** (List de Strings/Atoms): Lista padrão de chaves a serem mascaradas por `mask_for_log/2` quando o input é um mapa.
    *   Ex: `[\"password\", \"token\", \"secret\", \"credit_card_number\", \"cvv\", \"api_key\"]`
*   **Padrões específicos por tipo:**
    *   `[:security, :data_masking, :email, :visible_prefix_chars]` (Integer)
    *   `[:security, :data_masking, :cpf, :visible_digits_end]` (Integer)
    *   `[:security, :data_masking, :credit_card, :visible_last_digits]` (Integer)
    *   ... e assim por diante para outros tipos.
*   **`[:security, :data_masking, :auto_detect_patterns]`** (List de Maps): Configuração para `mask_sensitive_data/2`.
    *   Ex: `[%{type: :email, regex: ~r/.../, mask_function: &MyMaskers.email/1}, ...]`

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`: Para obter configurações de mascaramento.
*   `DeeperHub.Core.Logger`: Para logar se o mascaramento falhar ou se uma tentativa de logar dados não mascarados for detectada (se houver tal verificação).

### 8.2. Bibliotecas Externas

*   Nenhuma específica é estritamente necessária, mas bibliotecas de coordenação de string ou regex podem ser usadas internamente.

## 🤝 9. Como Usar / Integração

*   **Em Módulos de Logging (`DeeperHub.Security.LogSanitizer`):**
    *   O `LogSanitizer` chamaria `DataMasking.mask_for_log(metadata_map)` antes de passar os metadados para os backends de log.
*   **Em Módulos de API (`DeeperHub.Security.ResponseSanitizer`):**
    *   O `ResponseSanitizer` chamaria `DataMasking.mask_sensitive_map(api_response_body, configured_sensitive_keys_for_api)` antes de serializar para JSON.
*   **Em Interfaces de Usuário (ex: painel de admin mostrando dados de usuário):**
    *   O controller ou view helper chamaria as funções de mascaramento específicas antes de renderizar os dados.
    ```elixir
    # Em um controller/view
    def show_user_details(user) do
      masked_email = DeeperHub.Security.DataMasking.mask_email(user.email) |> elem(1)
      masked_cpf = DeeperHub.Security.DataMasking.mask_cpf(user.cpf) |> elem(1)
      # ... renderizar com dados mascarados
    end
    ```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar cada função de mascaramento específica (`mask_email`, `mask_cpf`, etc.) com vários formatos de entrada válidos e inválidos.
*   Testar `mask_sensitive_data` com strings contendo múltiplos tipos de dados sensíveis.
*   Testar `mask_sensitive_map` com mapas simples e aninhados, e diferentes `sensitive_keys`.
*   Testar o comportamento com diferentes configurações (ex: caracteres de mascaramento, número de dígitos visíveis).
*   Localização: `test/deeper_hub/security/data_masking/`.

### 10.2. Métricas

*   `deeper_hub.security.data_masking.fields_masked.count` (tags: `data_type` (`email`, `cpf`, `map_key`), `context` (`log`, `api_response`, `ui`))
*   `deeper_hub.security.data_masking.auto_detected_masked.count` (tags: `data_type`)

### 10.3. Logs

*   **Nível DEBUG:** Informações sobre quais campos foram mascarados em uma determinada chamada (útil durante o desenvolvimento e ajuste de regras).
*   **Nível WARNING:** Se uma função de mascaramento receber um tipo de dado inesperado ou se um padrão de regex configurado falhar ao compilar.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :data_masking, :data_masked]`
    *   Metadados: `%{data_type: type, characters_original: len, characters_masked: len, context: context_string}`

## ❌ 11. Tratamento de Erros

*   As funções de mascaramento devem ser robustas e não falhar se a entrada não corresponder exatamente ao formato esperado (ex: um CPF mal formatado). Nesses casos, elas podem optar por retornar a string original (com um log de aviso) ou aplicar um mascaramento mais genérico/completo.
*   Falhas em obter configurações (ex: padrões de regex) devem levar a um comportamento de mascaramento padrão seguro (ex: redigir completamente o campo).

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Eficácia do Mascaramento:** Garantir que os padrões de mascaramento realmente ocultem a informação sensível e não permitam inferência fácil dos dados originais.
*   **Não Mascarar Excessivamente:** Evitar mascarar tanta informação que os dados se tornem inúteis para o propósito pretendido (ex: depuração, identificação parcial).
*   **Performance:** Regexes complexas ou mascaramento recursivo em estruturas de dados muito grandes podem impactar a performance. Otimizar e testar o desempenho.

## 🧑‍💻 13. Contribuição

*   Ao adicionar suporte para mascarar novos tipos de dados, crie uma função específica e adicione-a aos mecanismos de detecção automática, se aplicável.
*   Mantenha os padrões de regex e as regras de mascaramento atualizados e bem testados.
*   Considere a internacionalização se estiver mascarando dados que variam significativamente por localidade (ex: formatos de telefone, números de identificação nacionais).

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar mascaramento diferencial: diferentes níveis de mascaramento para o mesmo dado dependendo do papel do usuário que o visualiza.
*   [ ] Adicionar suporte para \"tokenização\" ou \"criptografia format-preserving\" como alternativas mais avançadas ao mascaramento simples para certos casos de uso onde a reversibilidade controlada ou a manutenção do formato original são necessárias.
*   [ ] Permitir que as regras de mascaramento (especialmente para `mask_sensitive_map` e `mask_for_log`) sejam configuradas dinamicamente com mais granularidade através do `SecurityPolicyManager`.
*   [ ] Desenvolver ferramentas para ajudar a identificar automaticamente dados sensíveis no código que deveriam ser mascarados antes de logar/exibir.
*   [ ] Avaliar o uso de bibliotecas especializadas em detecção e mascaramento de PII se as necessidades se tornarem muito complexas.

---

*Última atualização: 2025-05-12*

---

O mascaramento de dados é um aspecto importante da proteção de dados e privacidade!

Para o próximo, podemos abordar `DeeperHub.Security.ResponseSanitizer` que é um consumidor natural do `DataMasking`, ou mudar para um módulo de infraestrutura como `DeeperHub.Core.BackgroundTaskManager`?"""),
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
                types.Part.from_text(text="""Perfeito! Vamos continuar com o `DeeperHub.Security.ResponseSanitizer`, que é um consumidor direto das funcionalidades do `DataMasking` e essencial para proteger dados em trânsito para o cliente.

---

