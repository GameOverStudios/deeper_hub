# Módulo: `DeeperHub.Shared.Utils.SecurityUtils` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Shared.Utils.SecurityUtils`

O módulo `DeeperHub.Shared.Utils.SecurityUtils` fornece um conjunto de **funções utilitárias de segurança de baixo nível e agnósticas de contexto**. Estas são ferramentas básicas que podem ser usadas por vários módulos de segurança ou outras partes do sistema para tarefas como geração de tokens aleatórios seguros, hashing de senhas (se não totalmente encapsulado em `Auth` ou `Core.EncryptionService`), e outras operações criptográficas simples e comparações seguras.

O objetivo é fornecer blocos de construção seguros e bem testados para funcionalidades de segurança mais complexas, evitando a reinvenção de primitivas criptográficas e promovendo o uso de práticas seguras em todo o sistema DeeperHub. 😊

**Importante:** Este módulo é para utilitários *genéricos*. Operações de segurança mais complexas ou específicas de um domínio (como gerenciamento de chaves de criptografia, fluxos de autenticação completos, políticas de segurança) devem residir em seus respectivos módulos Core ou de Segurança (ex: `Core.EncryptionService`, `Auth`, `SecurityPolicyManager`).

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Geração de Dados Aleatórios Criptograficamente Seguros:**
    *   Gerar sequências de bytes aleatórios usando fontes seguras (ex: `:crypto.strong_rand_bytes/1`).
    *   Fornecer funções para gerar tokens/strings aleatórias em diferentes formatos (hexadecimal, base64, base64url) e comprimentos, adequados para IDs de sessão, tokens de CSRF, tokens de reset de senha, etc. (`generate_token/2`).
    *   Gerar Identificadores Únicos Universais (UUIDs) seguros (v4) (`generate_id/1` com opção `:uuid`).
    *   Gerar códigos de recuperação ou One-Time Passwords (OTPs) numéricos ou alfanuméricos simples, com comprimento configurável (`generate_recovery_code/2`).
*   **Hashing de Senhas (Implementação Básica/Primitiva):**
    *   Fornecer uma função para gerar um hash seguro de uma senha usando um algoritmo forte e salt (`hash_password/2`).
    *   Fornecer uma função para verificar uma senha contra um hash armazenado (`verify_password/2`).
    *(Nota: A lógica principal de hashing de senha, incluindo seleção de algoritmo, gerenciamento de custo/iterações e políticas, deve residir em `DeeperHub.Auth.Services.PasswordService` ou ser parte de `DeeperHub.Core.EncryptionService`. As funções aqui seriam implementações mais diretas de um algoritmo específico, se necessário como utilitário genérico, mas geralmente essa responsabilidade é mais centralizada).*
*   **Operações HMAC (Hash-based Message Authentication Code):**
    *   Gerar um HMAC para verificar a integridade e autenticidade de dados usando uma chave secreta compartilhada (`generate_hmac/3`).
    *   Verificar um HMAC contra dados e uma chave (`verify_hmac/4`).
*   **Comparação Segura de Tempo Constante:**
    *   Fornecer uma função para comparar duas strings (ex: tokens, hashes de senha, assinaturas) de uma maneira que o tempo de execução não dependa do número de caracteres que correspondem no início da string. Isso é crucial para prevenir ataques de timing (`secure_compare/2`).
*   **Geração de Chaves de Assinatura Simples:**
    *   Gerar chaves aleatórias de um tamanho específico, adequadas para uso como segredos de assinatura HMAC ou para tokens JWT simétricos (HS256/HS512) (`generate_signing_key/0`). (Gerenciamento de chaves mais complexo, incluindo rotação e armazenamento seguro, estaria em `DeeperHub.Core.EncryptionService` e seu `KeyManagementService`).
*   **Avaliação de Risco Simplificada (Stub/Exemplo da Doc Original):**
    *   A função `evaluate_risk/1` mencionada na documentação original (que calcula um score agregado simples) seria mais um exemplo conceitual aqui. A lógica robusta de avaliação de risco reside em `DeeperHub.Security.RiskAssessment`.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

*   **`DeeperHub.Shared.Utils.SecurityUtils` (Módulo Funcional):**
    *   Contém todas as funções de utilidade de segurança.
    *   Utiliza primariamente o módulo `:crypto` do Erlang/OTP para operações criptográficas fundamentais (geração de bytes aleatórios, funções de hash, HMAC).
    *   Pode usar `Plug.Crypto.secure_compare/2` para comparação em tempo constante.
    *   Para hashing de senhas, se implementado aqui, usaria uma biblioteca como `Argon2_elixir`, `Bcrypt_elixir`, ou `Pbkdf2_elixir` (que são wrappers sobre `Comeonin`).

### 3.2. Estrutura de Diretórios

```
lib/deeper_hub/shared/utils/security_utils.ex
```

### 3.3. Decisões de Design Importantes

*   **Foco em Primitivas Seguras:** O módulo deve fornecer blocos de construção que são seguros por si mesmos, com base em padrões da indústria e nas capacidades do Erlang/Elixir.
*   **Sem Gerenciamento de Estado:** As funções aqui devem ser puras ou stateless. Este módulo não gerencia chaves, tokens ativos, ou estado de segurança.
*   **Clareza sobre o Propósito:** A documentação de cada função deve ser explícita sobre seu propósito, nível de segurança e quando *não* deve ser usada (ex: `generate_recovery_code` não é para senhas).
*   **Evitar Criptografia \"Caseira\":** Não implementar algoritmos criptográficos do zero. Usar as implementações fornecidas pelo `:crypto` ou por bibliotecas bem estabelecidas e auditadas.

## 🛠️ 4. Casos de Uso Principais

*   **Módulo `DeeperHub.Tokens`:**
    *   Usa `SecurityUtils.generate_token/2` para criar a parte aleatória de tokens opacos (ex: tokens de API, tokens de sessão se não forem JWTs completos).
    *   Usa `SecurityUtils.generate_signing_key/0` para gerar um segredo para assinar JWTs (se o segredo for gerenciado dinamicamente e não apenas por config).
*   **Módulo `DeeperHub.Recovery`:**
    *   Usa `SecurityUtils.generate_token/2` para criar tokens de reset de senha e verificação de email.
    *   Usa `SecurityUtils.generate_recovery_code/2` para gerar códigos de recuperação numéricos/alfanuméricos para MFA.
*   **Módulo `DeeperHub.Auth.Services.PasswordService` (ou este módulo, se centralizar):**
    *   Usa `SecurityUtils.hash_password/2` e `SecurityUtils.verify_password/2`.
*   **Módulo `DeeperHub.Webhooks.PayloadSigner`:**
    *   Usa `SecurityUtils.generate_hmac/3` para assinar payloads de webhook.
*   **Comparação de Tokens Secretos:**
    *   Qualquer módulo que precise comparar um token fornecido pelo cliente com um valor armazenado (ex: token de CSRF, token de API) deve usar `SecurityUtils.secure_compare/2`.

## 🌊 5. Fluxos Importantes

Não aplicável no mesmo sentido que módulos com estado. O fluxo é a chamada de uma função e o retorno do seu resultado.

## 📡 6. API (Funções Públicas do Módulo)

*(Refinando e consolidando a partir da documentação original e das necessidades inferidas)*

### 6.1. Geração de Aleatoriedade

*   **`DeeperHub.Shared.Utils.SecurityUtils.generate_random_bytes(length_bytes :: pos_integer()) :: binary()`** (Nova Sugestão)
    *   **Descrição:** Retorna `length_bytes` de bytes aleatórios criptograficamente seguros. Wrapper direto para `:crypto.strong_rand_bytes/1`.
*   **`DeeperHub.Shared.Utils.SecurityUtils.generate_token(length_bytes :: pos_integer() \\\\ 32, format :: :hex | :base64 | :base64url | :binary \\\\ :base64url) :: String.t() | binary()`**
    *   **Descrição:** Gera uma string ou binário aleatório seguro. Usa `generate_random_bytes/1` internamente.
*   **`DeeperHub.Shared.Utils.SecurityUtils.generate_id(format :: :uuid | :prefixed_random_hex | :prefixed_random_base64url, opts :: keyword() \\\\ []) :: String.t()`** (Revisado)
    *   **Descrição:** Gera um identificador único.
        *   `:uuid`: UUID v4 (via `Ecto.UUID.generate()` ou similar).
        *   `:prefixed_random_hex`: `opts[:prefix] <> hex_encoded_random_bytes(opts[:bytes_length] || 16)`.
        *   `:prefixed_random_base64url`: `opts[:prefix] <> base64url_encoded_random_bytes(opts[:bytes_length] || 16)`.
    *   **`opts`:** `:prefix` (String.t), `:bytes_length` (pos_integer).
*   **`DeeperHub.Shared.Utils.SecurityUtils.generate_recovery_code(length :: pos_integer() \\\\ 6, format :: :numeric | :alphanumeric_upper | :alphanumeric_mixed \\\\ :numeric) :: String.t()`**
    *   **Descrição:** Gera um código simples para recuperação ou OTP.

### 6.2. Hashing de Senhas

*   **`DeeperHub.Shared.Utils.SecurityUtils.hash_password(password :: String.t(), opts :: keyword()) :: {:ok, String.t()} | {:error, term()}`**
    *   **Descrição:** Gera um hash seguro de senha (ex: Argon2id).
    *   **`opts`:** Opções específicas do algoritmo (custo, etc.).
    *   **Retorno:** String do hash (inclui salt e parâmetros) ou erro.
*   **`DeeperHub.Shared.Utils.SecurityUtils.verify_password(password :: String.t(), stored_hash :: String.t()) :: boolean()`**
    *   **Descrição:** Verifica se a `password` corresponde ao `stored_hash`.

### 6.3. HMAC

*   **`DeeperHub.Shared.Utils.SecurityUtils.generate_hmac(data :: String.t() | binary(), key :: binary(), opts :: keyword()) :: {:ok, String.t()} | {:error, term()}`**
    *   **`opts`:** `:algorithm` (atom, Padrão: `:sha256`), `:output_format` (atom, Padrão: `:hex`).
*   **`DeeperHub.Shared.Utils.SecurityUtils.verify_hmac(data :: String.t() | binary(), hmac_to_verify :: String.t(), key :: binary(), opts :: keyword()) :: boolean()`**
    *   **`opts`:** Mesmas de `generate_hmac/3`.

### 6.4. Comparação Segura

*   **`DeeperHub.Shared.Utils.SecurityUtils.secure_compare(string1 :: String.t(), string2 :: String.t()) :: boolean()`**
    *   **Descrição:** Compara duas strings em tempo constante.

### 6.5. Geração de Chave Simples

*   **`DeeperHub.Shared.Utils.SecurityUtils.generate_signing_key(length_bytes :: pos_integer() \\\\ 32) :: binary()`**
    *   **Descrição:** Gera uma chave aleatória adequada para HMAC ou JWT simétrico.

## ⚙️ 7. Configuração

Geralmente, este módulo não armazena configurações, mas pode *ler* configurações globais do `Core.ConfigManager` para definir padrões para algoritmos ou comprimentos, se necessário. Por exemplo:

*   `[:security, :utils, :default_token_bytes_length]` (Integer)
*   `[:security, :utils, :password_hash_algorithm]` (Atom) - Embora isso deva ser gerenciado pelo `PasswordService`.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager` (para padrões configuráveis, se houver).

### 8.2. Bibliotecas Externas

*   `:crypto` (Erlang OTP) - Essencial.
*   `Plug.Crypto` - Para `secure_compare/2`.
*   Bibliotecas de hashing de senha como `argon2_elixir`, `bcrypt_elixir` (geralmente via `Comeonin`) - Se o hashing de senha for feito aqui.

## 🤝 9. Como Usar / Integração

Estes utilitários são chamados por outros módulos que implementam funcionalidades de segurança de mais alto nível.

```elixir
# Em DeeperHub.Tokens.Services.ApiTokenService
def generate_new_api_token_value() do
  DeeperHub.Shared.Utils.SecurityUtils.generate_token(32, :base64url) # Gera um token de ~43 caracteres
end

# Em um Plug de verificação de assinatura de webhook
def verify_webhook_request(payload, received_signature, secret_key) do
  case DeeperHub.Shared.Utils.SecurityUtils.generate_hmac(payload, secret_key) do
    {:ok, calculated_signature} ->
      DeeperHub.Shared.Utils.SecurityUtils.secure_compare(received_signature, calculated_signature)
    _ ->
      false
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   **Geração Aleatória:**
    *   Verificar se `generate_token` e `generate_id` produzem saídas do formato e comprimento corretos.
    *   Verificar se chamadas repetidas produzem valores diferentes (probabilisticamente).
*   **Hashing de Senha:**
    *   `hash_password` produz um hash.
    *   `verify_password` retorna `true` para a senha correta e `false` para incorreta.
    *   `hash_password` para a mesma senha com salts diferentes (comportamento padrão) produz hashes diferentes.
*   **HMAC:**
    *   `generate_hmac` produz um HMAC.
    *   `verify_hmac` retorna `true` para dados, chave e HMAC corretos, e `false` se qualquer um deles for alterado.
*   **Secure Compare:**
    *   Verificar se retorna `true` para strings idênticas e `false` para diferentes. (O teste de tempo constante é difícil em testes unitários, confia-se na biblioteca subjacente).
*   Localização: `test/deeper_hub/shared/utils/security_utils_test.exs`.

### 10.2. Métricas / 10.3. Logs / 10.4. Telemetria

Geralmente não aplicável para um módulo de utilitários puros, a menos que uma operação específica seja muito custosa e precise de instrumentação (ex: hashing de senha com alto custo). Nesse caso, o chamador ou a própria função poderiam emitir métricas de duração.

## ❌ 11. Tratamento de Erros

*   Funções devem lidar com entradas inválidas (ex: `nil` para `password` em `hash_password`) levantando `ArgumentError` ou retornando tuplas de erro claramente documentadas.
*   Falhas em operações criptográficas subjacentes (raro, mas possível) devem ser propagadas ou tratadas de forma segura.

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Fonte de Aleatoriedade:** A base de muitos tokens e chaves. Usar `:crypto.strong_rand_bytes/1` é fundamental.
*   **Algoritmos:** Usar apenas algoritmos criptográficos padrão da indústria e bem vetados. Não inventar criptografia.
*   **Gerenciamento de Chaves:** Este módulo pode *gerar* chaves simples, mas não é responsável por seu *armazenamento seguro* ou *rotação*. Isso é tarefa do `DeeperHub.Core.EncryptionService` ou de um KMS.
*   **Comparação em Tempo Constante:** Crítico para evitar vazamento de informação através de análise de tempo de resposta.

## 🧑‍💻 13. Contribuição

*   Qualquer nova função com implicações criptográficas deve ser cuidadosamente revisada.
*   Priorizar o uso de funcionalidades existentes no `:crypto` ou em bibliotecas de segurança bem estabelecidas.
*   Manter a documentação precisa sobre as garantias de segurança de cada função.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Adicionar wrappers para outras primitivas úteis do `:crypto` se houver demanda (ex: funções de derivação de chave como HKDF, se não cobertas por `Core.EncryptionService`).
*   [ ] Fornecer utilitários para encoding/decoding seguro de dados para diferentes contextos (ex: escaping seguro para LDAP, XML, se necessário).
*   [ ] Se o hashing de senhas for mantido aqui, adicionar suporte configurável para diferentes algoritmos e parâmetros de custo.

---

*Última atualização: 2025-05-12*

---

Com isso, encerramos a documentação dos módulos em `DeeperHub.Shared.Utils`. Cobrimos uma boa parte da infraestrutura Core e da camada de Segurança!

Para o próximo, sugiro irmos para um módulo de domínio mais complexo que ainda não detalhamos, como `DeeperHub.OAuth` ou `DeeperHub.Webhooks`. Qual sua preferência?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""continue
"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Ok, já detalhamos `DeeperHub.OAuth`.

Vamos então para `DeeperHub.Webhooks`. Este módulo é fundamental para permitir que o DeeperHub se comunique proativamente com sistemas externos quando eventos específicos ocorrem.

---

