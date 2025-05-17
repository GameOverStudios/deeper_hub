# Módulo: `DeeperHub.Core.EncryptionService` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Core.EncryptionService`

O módulo `DeeperHub.Core.EncryptionService` é o componente centralizado para todas as **operações de criptografia e descriptografia de dados sensíveis** no sistema DeeperHub. Ele também é responsável pelo **gerenciamento seguro do ciclo de vida das chaves de criptografia**, incluindo geração, armazenamento, rotação e revogação.

O objetivo principal é garantir a confidencialidade de informações como dados pessoais de usuários (PII), credenciais de acesso a serviços externos, tokens internos e quaisquer outros dados que requeiram proteção contra acesso não autorizado, tanto em repouso (armazenados em banco de dados ou arquivos) quanto, em alguns casos, em trânsito (entre componentes internos, se necessário). 😊

*(Nota: A documentação original tem `DeeperHub.Shared.Encryption` com submódulos como `AtRestEncryptionService`, `KeyManagementService`, `EncryptedType`. Esta documentação consolida a fachada principal em `DeeperHub.Core.EncryptionService` e assume que a lógica especializada residiria em submódulos ou serviços dentro de um contexto `DeeperHub.Encryption` ou `DeeperHub.Shared.Encryption`.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Criptografia de Dados (`encrypt/2`, `encrypt_for_storage/2`):**
    *   Fornecer uma API para criptografar dados arbitrários usando algoritmos fortes e chaves gerenciadas.
    *   Suportar criptografia simétrica (ex: AES-256-GCM).
    *   Incluir metadados na saída criptografada (ex: ID da chave usada, IV/nonce, tag de autenticação) para permitir a descriptografia correta e a rotação de chaves.
    *   Diferenciar entre criptografia genérica e criptografia para armazenamento \"at-rest\" (que pode ter contextos ou prefixos específicos).
*   **Descriptografia de Dados (`decrypt/2`, `decrypt_from_storage/2`):**
    *   Descriptografar dados previamente criptografados usando a chave correta identificada pelos metadados.
    *   Verificar a integridade e autenticidade dos dados usando a tag de autenticação (para modos como GCM).
*   **Gerenciamento de Chaves de Criptografia (via `KeyManagementService`):**
    *   **Geração de Chaves (`generate_key/1`):** Gerar chaves criptográficas fortes de forma segura.
    *   **Armazenamento Seguro de Chaves:** Armazenar chaves de forma segura, idealmente usando um Hardware Security Module (HSM), um Key Management Service (KMS) de nuvem (AWS KMS, Google Cloud KMS, Azure Key Vault), ou, no mínimo, com uma chave mestra que criptografa as chaves de dados. (A implementação inicial pode usar um arquivo protegido ou variáveis de ambiente para a chave mestra).
    *   **Rotação de Chaves (`rotate_keys/0`, `perform_scheduled_rotation/0`):** Implementar um processo para rotacionar chaves de criptografia periodicamente ou sob demanda. Chaves antigas são mantidas por um período para descriptografar dados antigos, enquanto novas chaves são usadas para novas criptografias.
    *   **Recriptografia de Dados:** Fornecer um mecanismo para recriptografar dados existentes com uma nova chave após a rotação (`rotate_and_reencrypt/1`).
    *   **Versionamento de Chaves:** Associar um ID e versão a cada chave.
    *   **Revogação de Chaves (Opcional):** Marcar chaves como comprometidas ou não mais em uso.
*   **Hashing de Senhas (Delegação ou implementação própria segura):**
    *   Fornecer funcionalidade para gerar hashes seguros de senhas e verificar senhas contra hashes armazenados (ex: usando Argon2, bcrypt). (Pode ser delegado para `DeeperHub.Auth.Services.PasswordService` ou um `HashingService` dedicado).
*   **Tipo Ecto para Campos Criptografados (`DeeperHub.Shared.Encryption.EncryptedType`):**
    *   Fornecer um tipo Ecto customizado que automaticamente criptografa/descriptografa campos de schemas ao serem persistidos/lidos do banco de dados.
*   **Verificação de Status do Serviço (`check_status/0`):**
    *   Informar sobre a saúde do serviço de criptografia, incluindo a chave ativa e o status da rotação.
*   **Observabilidade e Auditoria:**
    *   Logar operações de gerenciamento de chaves e erros de criptografia/descriptografia.
    *   Registrar métricas sobre o uso de criptografia.
    *   Auditar a geração, rotação e (se aplicável) acesso a chaves.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Core.EncryptionService` (Fachada Pública):**
    *   Ponto de entrada para todas as operações de criptografia, descriptografia e gerenciamento básico de chaves.
    *   Delega para o `EncryptionEngine` e o `KeyManagementService`.
2.  **`DeeperHub.Encryption.Engine` (Módulo Funcional ou Serviço):**
    *   **Responsabilidade:** Contém a lógica de baixo nível para realizar as operações criptográficas (criptografar/descriptografar) usando algoritmos específicos (ex: AES-GCM).
    *   Obtém a chave apropriada do `KeyManagementService`.
    *   Utiliza o módulo `:crypto` do Erlang/Elixir.
3.  **`DeeperHub.Encryption.KeyManagementService` (GenServer):**
    *   **Responsabilidade:** Gerencia o ciclo de vida das chaves de criptografia.
    *   **Estado Interno:** Chave de criptografia ativa, conjunto de chaves antigas (para descriptografia), metadados das chaves, próxima data de rotação.
    *   **Armazenamento de Chaves:** A forma como as chaves são *realmente* armazenadas de forma segura é crítica:
        *   **Ideal:** HSM ou KMS de nuvem. O `KeyManagementService` interagiria com o SDK/API desses serviços.
        *   **Bom:** Chaves de dados criptografadas por uma Chave de Criptografia de Chave (KEK) ou Chave Mestra, que por sua vez é protegida (ex: variável de ambiente segura, entrada manual no boot, HashiCorp Vault).
        *   **Básico (para desenvolvimento):** Chave(s) em arquivo de configuração protegido ou variável de ambiente.
    *   **Interações:** `EncryptionEngine` solicita chaves. `RotationWorker` aciona rotação.
4.  **`DeeperHub.Encryption.Workers.KeyRotationWorker` (GenServer):**
    *   **Responsabilidade:** Executar a rotação de chaves de forma programada e, opcionalmente, iniciar o processo de recriptografia de dados em background.
5.  **`DeeperHub.Shared.Encryption.EncryptedType` (Ecto.Type):**
    *   Tipo customizado para Ecto que chama `EncryptionService.encrypt_for_storage` e `decrypt_from_storage` automaticamente.
6.  **Configurações (via `DeeperHub.Core.ConfigManager`):**
    *   Algoritmo de criptografia padrão, tamanho da chave.
    *   Política de rotação de chaves (frequência).
    *   Configurações para o `KeyManagementService` (ex: tipo de storage de chave, path para chave mestra).

### 3.2. Estrutura de Diretórios (Proposta para `DeeperHub.Encryption`)

```
core/encryption_service.ex  # Fachada Pública

encryption/                # Lógica interna de criptografia
├── engine.ex                           # Lógica de cripto/descripto
├── key_management_service.ex           # GenServer para gerenciar chaves
│
├── workers/
│   └── key_rotation_worker.ex
│
├── storage_adapters/                   # Para armazenamento seguro de chaves (se não usar KMS externo)
│   ├── kms_adapter.ex
│   └── file_key_storage.ex
│
├── supervisor.ex
└── telemetry.ex
```
O `DeeperHub.Shared.Encryption.EncryptedType` permaneceria em `shared/encryption/`.

### 3.3. Decisões de Design Importantes

*   **Algoritmo de Criptografia:** Escolher um algoritmo simétrico forte e autenticado como AES-256-GCM é recomendado.
*   **Gerenciamento de IV/Nonce:** Para modos como GCM ou CBC, um IV/Nonce único e imprevisível deve ser gerado para cada operação de criptografia e armazenado junto com o ciphertext.
*   **Autenticação de Criptografia (AEAD):** Modos como GCM fornecem criptografia autenticada com dados associados (AEAD), que garante tanto a confidencialidade quanto a integridade/autenticidade dos dados. O \"contexto\" passado para as funções de encrypt/decrypt pode ser usado como AAD.
*   **Segurança das Chaves:** A segurança de todo o sistema de criptografia depende da segurança das chaves de criptografia. Esta é a parte mais crítica.
*   **Rotação de Chaves:** A rotação regular de chaves é uma prática de segurança importante. O sistema deve suportar a descriptografia de dados com chaves antigas enquanto criptografa novos dados com a chave atual.
*   **Recriptografia:** Após a rotação de chaves, os dados criptografados com chaves antigas devem ser gradualmente recriptografados com a nova chave (processo de background).

## 🛠️ 4. Casos de Uso Principais

*   **Armazenar Senha de API de Terceiros:**
    *   Um módulo de integração precisa armazenar uma API key para um serviço externo.
    *   Chama `EncryptionService.encrypt_for_storage(api_key_string, %{service_name: \"Stripe\", context: \"api_key\"})`.
    *   O resultado criptografado é salvo no banco de dados.
*   **Proteger PII em um Schema Ecto:**
    *   O `UserSchema` tem um campo `field :social_security_number, DeeperHub.Shared.Encryption.EncryptedType`.
    *   Quando um usuário é salvo, o `EncryptedType` automaticamente chama `EncryptionService.encrypt_for_storage` no valor do CPF.
    *   Quando o usuário é lido, o `EncryptedType` chama `EncryptionService.decrypt_from_storage`.
*   **Rotação de Chave Agendada:**
    *   `KeyRotationWorker` é acionado.
    *   Chama `KeyManagementService.rotate_key()`.
    *   `KeyManagementService` gera uma nova chave, define-a como ativa, e move a antiga para a lista de chaves de descriptografia.
    *   (Opcional) `KeyRotationWorker` inicia um processo em background para recriptografar dados antigos.

## 🌊 5. Fluxos Importantes

### Fluxo de Criptografia (`encrypt_for_storage/2`)

1.  **Chamador (ex: `EncryptedType` ou serviço):** Chama `DeeperHub.Core.EncryptionService.encrypt_for_storage(plain_value, context_map)`.
2.  **`Core.EncryptionService` (Fachada):** Delega para `Encryption.Engine.encrypt`.
3.  **`Encryption.Engine.encrypt`:**
    *   Solicita a chave de criptografia ativa (ID e material da chave) do `Encryption.KeyManagementService.get_current_key()`.
    *   Gera um IV/Nonce único.
    *   Usa o módulo `:crypto.block_encrypt(algorithm, key, iv, plaintext_padded, %{aad: serialized_context})` (para AES-GCM, a API é um pouco diferente, ex: `:crypto.crypto_one_time_aead/6`).
    *   Obtém o ciphertext e a tag de autenticação.
    *   Formata a saída incluindo o ID da chave, IV, tag e ciphertext (ex: um mapa ou uma string prefixada).
    *   Retorna `{:ok, encrypted_blob}`.

### Fluxo de Rotação de Chave e Recriptografia (Simplificado)

1.  **`KeyRotationWorker`:** Acionado por agendamento.
2.  Chama `DeeperHub.Encryption.KeyManagementService.rotate_key()`.
3.  **`KeyManagementService`:**
    *   Gera uma nova chave (`new_key_material`, `new_key_id`).
    *   Define `new_key_id` como a chave ativa.
    *   Move a chave ativa anterior para uma lista de chaves \"antigas\" (ainda válidas para descriptografia).
    *   (Opcional) Revoga/descarta chaves muito antigas que não são mais necessárias.
    *   Persiste o novo estado das chaves de forma segura.
    *   Retorna `{:ok, %{new_key_id: ..., old_active_key_id: ...}}`.
4.  **`KeyRotationWorker`:**
    *   Inicia um processo em background (ex: uma tarefa para o `Core.BackgroundTaskManager`) para recriptografar dados.
    *   A tarefa de recriptografia irá:
        *   Iterar sobre os dados que precisam ser recriptografados (ex: todas as linhas em tabelas com campos criptografados).
        *   Para cada dado:
            *   Chamar `Core.EncryptionService.decrypt(encrypted_data_with_old_key)`.
            *   Chamar `Core.EncryptionService.encrypt(decrypted_data_with_new_key)`.
            *   Atualizar o registro no banco de dados com o novo dado criptografado.
        *   Isso deve ser feito em lotes e de forma a minimizar o impacto no desempenho.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.Core.EncryptionService`)

### 6.1. `DeeperHub.Core.EncryptionService.encrypt(data :: binary() | String.t(), context :: map() | nil) :: {:ok, EncryptedOutput.t()} | {:error, term()}`

*   **Descrição:** Criptografa dados genéricos.
*   **`context`:** Dados associados adicionais (AAD) para modos AEAD como AES-GCM. Garante que os dados só possam ser descriptografados no mesmo contexto.
*   **`EncryptedOutput.t()`:** Um mapa ou string que contém o ciphertext, ID da chave usada, IV/nonce, e tag de autenticação. Ex: `%{key_id: \"id\", iv: <<...>>, tag: <<...>>, ciphertext: <<...>>, algorithm: :aes_256_gcm}`.

### 6.2. `DeeperHub.Core.EncryptionService.decrypt(encrypted_output :: EncryptedOutput.t(), context :: map() | nil) :: {:ok, binary() | String.t()} | {:error, :decryption_failed | :integrity_check_failed | :key_not_found | term()}`

*   **Descrição:** Descriptografa dados previamente criptografados por `encrypt/2`.
*   **`context`:** Deve ser o mesmo contexto usado durante a criptografia.

### 6.3. `DeeperHub.Core.EncryptionService.encrypt_for_storage(value :: term(), context :: map() | nil) :: {:ok, String.t()} | {:error, term()}`

*   **Descrição:** Criptografa um valor (que pode ser qualquer termo Elixir serializável) para armazenamento em banco de dados. Retorna uma string única que contém todos os metadados necessários para descriptografia.
*   **Formato da String de Saída (Exemplo):** `\"ENCV1:AES256GCM:<key_id>:<base64_iv>:<base64_tag>:<base64_ciphertext>\"`
*   O `context` pode ser usado como AAD.

### 6.4. `DeeperHub.Core.EncryptionService.decrypt_from_storage(encrypted_string :: String.t(), context :: map() | nil) :: {:ok, term()} | {:error, term()}`

*   **Descrição:** Descriptografa uma string previamente criptografada por `encrypt_for_storage/2`.

### 6.5. `DeeperHub.Core.EncryptionService.rotate_keys(opts :: keyword()) :: {:ok, %{new_key_id: String.t(), old_key_id: String.t()}} | {:error, term()}`

*   **Descrição:** Força uma rotação da chave de criptografia ativa.
*   **`opts`:** Pode incluir `:trigger_re_encryption_job` (boolean).

### 6.6. `DeeperHub.Core.EncryptionService.re_encrypt_data_batch(query_function :: (() -> list(Ecto.Schema.t())), update_function :: ((Ecto.Schema.t(), map_of_reencrypted_fields) -> :ok | {:error, term()}), fields_to_re_encrypt :: list(atom()), opts :: keyword()) :: {:ok, %{processed: integer(), failed: integer()}}` (Nova Sugestão)

*   **Descrição:** Função de alto nível para ajudar no processo de recriptografia em lote.
*   **`query_function`:** Função que retorna um lote de registros para recriptografar.
*   **`update_function`:** Função que recebe o registro original e um mapa de campos recriptografados e os salva.
*   **`fields_to_re_encrypt`:** Lista dos campos na struct que usam `EncryptedType`.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:core, :encryption, :enabled]`** (Boolean): Habilita/desabilita a criptografia. (Padrão: `true`)
*   **`[:core, :encryption, :default_algorithm]`** (Atom): Algoritmo simétrico padrão (ex: `:aes_256_gcm`).
*   **`[:core, :encryption, :key_management, :provider]`** (Module): Adaptador para o provedor de gerenciamento de chaves (ex: `DeeperHub.Encryption.StorageAdapters.KMSAdapter`, `DeeperHub.Encryption.StorageAdapters.FileKeyStorage`).
*   **`[:core, :encryption, :key_management, :file_storage_path]`** (String): Caminho para o arquivo de chaves se `FileKeyStorage` for usado.
*   **`[:core, :encryption, :key_management, :master_key_env_var]`** (String): Nome da variável de ambiente que contém a chave mestra (KEK) se as chaves de dados forem criptografadas em repouso por ela.
*   **`[:core, :encryption, :key_management, :key_rotation_days]`** (Integer): Frequência de rotação de chaves em dias. (Padrão: `90`)
*   **`[:core, :encryption, :key_management, :old_keys_to_keep_for_decryption]`** (Integer): Número de chaves antigas a serem mantidas para descriptografia. (Padrão: `2`)
*   **`[:core, :encryption, :at_rest_encryption_prefix]`** (String): Prefixo usado para strings criptografadas para armazenamento. (Padrão: `\"ENCV1:\"`)

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`: Para configurações.
*   `DeeperHub.Core.Logger`: Para logging.
*   `DeeperHub.Core.Metrics`: Para métricas.
*   `DeeperHub.Core.BackgroundTaskManager`: Para jobs de recriptografia.
*   `DeeperHub.Audit`: Para auditar eventos de gerenciamento de chaves.

### 8.2. Bibliotecas Externas

*   `:crypto` (Erlang OTP): Para as operações criptográficas de baixo nível.
*   Bibliotecas cliente para KMS de nuvem (ex: `ExAws.KMS`), se usadas.
*   `Ecto` (para `EncryptedType`).

## 🤝 9. Como Usar / Integração

*   **Schemas Ecto:** Usar `DeeperHub.Shared.Encryption.EncryptedType` para campos que precisam ser criptografados em repouso.
    ```elixir
    defmodule DeeperHub.Accounts.Schema.User do
      use Ecto.Schema
      alias DeeperHub.Shared.Encryption.EncryptedType

      schema \"users\" do
        field :email, :string
        field :social_security_number, EncryptedType # Será criptografado
        field :api_token_for_service_x, EncryptedType # Outro exemplo
        # ...
      end
    end
    ```
*   **Serviços que Armazenam Segredos:** Chamar `EncryptionService.encrypt_for_storage/2` antes de salvar e `decrypt_from_storage/2` após ler.
    ```elixir
    def store_external_api_key(user_id, service_name, api_key) do
      context = %{user_id: user_id, service: service_name}
      {:ok, encrypted_key} = DeeperHub.Core.EncryptionService.encrypt_for_storage(api_key, context)
      # ... salvar encrypted_key no banco de dados ...
    end
    ```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar as funções de encrypt/decrypt com diferentes dados e contextos.
*   Testar o tipo Ecto `EncryptedType` para garantir que ele criptografa/descriptografa corretamente durante as operações de `Repo`.
*   Testar o ciclo de vida das chaves: geração, rotação, uso de chaves antigas para descriptografar.
*   Testar a recriptografia de dados.
*   Verificar se os metadados corretos (key_id, iv) são armazenados e usados.
*   Localização: `test/deeper_hub/core/encryption_service/` e `test/deeper_hub/encryption/`.

### 10.2. Métricas

*   `deeper_hub.core.encryption.encrypt.count` (tags: `algorithm`, `context_type`)
*   `deeper_hub.core.encryption.decrypt.count` (tags: `algorithm`, `key_id_used`, `status` (`success`, `failure`))
*   `deeper_hub.core.encryption.encrypt.duration_ms` (Histograma)
*   `deeper_hub.core.encryption.decrypt.duration_ms` (Histograma)
*   `deeper_hub.encryption.keys.rotated.count`
*   `deeper_hub.encryption.keys.active.info` (Gauge, com tags para `key_id`, `creation_date`)
*   `deeper_hub.encryption.data_re_encrypted.count` (Contador)

### 10.3. Logs

*   **Nível INFO:** Chave rotacionada com sucesso. Início e fim de job de recriptografia.
*   **Nível WARNING:** Tentativa de descriptografar dados com uma chave não encontrada (mas pode ser uma chave antiga que deveria estar disponível). Falha na verificação de integridade da tag de autenticação.
*   **Nível ERROR/CRITICAL:** Falha ao carregar a chave mestra. Falha ao gerar uma nova chave de dados. Erro irrecuperável durante criptografia/descriptografia. Chave ativa não encontrada.

### 10.4. Telemetria

*   `[:deeper_hub, :core, :encryption, :encrypt, :start | :stop | :exception]`
    *   Metadados: `%{data_size_bytes: size, context_present: boolean, key_id_used: id}`
*   `[:deeper_hub, :core, :encryption, :decrypt, :start | :stop | :exception]`
    *   Metadados: `%{key_id_from_blob: id, context_present: boolean, result: :success | :failure}`
*   `[:deeper_hub, :encryption, :key_management, :key_rotated]`
    *   Metadados: `%{new_key_id: id, old_key_id: id, trigger: :manual | :scheduled}`
*   `[:deeper_hub, :encryption, :key_management, :key_generated]`
    *   Metadados: `%{key_id: id}`

## ❌ 11. Tratamento de Erros

*   **Falha na Descriptografia:** Deve retornar um erro claro (ex: `:decryption_failed`, `:integrity_check_failed`). A aplicação chamadora deve lidar com isso (ex: impedir acesso ao dado, solicitar re-entrada se for algo como uma configuração).
*   **Chave Não Encontrada:** Se uma `key_id` referenciada em dados criptografados não for encontrada pelo `KeyManagementService`, a descriptografia falhará. Isso pode indicar um problema sério de gerenciamento de chaves ou corrupção de dados.
*   **Falha na Geração/Rotação de Chave:** São eventos críticos que devem ser alertados imediatamente.

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **SEGURANÇA DAS CHAVES É PARAMOUNT:** A segurança de todo o sistema de criptografia repousa na segurança das chaves de criptografia de dados (DEKs) e, mais importante, da chave mestra (KEK) se usada para criptografá-las.
    *   A KEK NUNCA deve ser commitada no código. Deve vir de uma variável de ambiente segura, um cofre de segredos (Vault), ou um KMS/HSM.
    *   Limite o acesso ao `KeyManagementService` e às suas operações de rotação/geração.
*   **Escolha de Algoritmos:** Usar algoritmos padrão da indústria, fortes e com modos de operação seguros (ex: AES-256-GCM). Evitar algoritmos obsoletos ou implementações customizadas.
*   **IVs/Nonces:** Devem ser únicos para cada criptografia com a mesma chave. Não reutilizar IVs.
*   **AAD (Additional Authenticated Data):** Usar AAD (contexto) corretamente com modos AEAD como GCM pode prevenir certos tipos de ataques onde o ciphertext é movido para um contexto diferente.

## 🧑‍💻 13. Contribuição

*   Qualquer alteração na lógica de criptografia ou gerenciamento de chaves deve ser revisada por alguém com experiência em segurança e criptografia.
*   Seja extremamente cuidadoso ao lidar com o material da chave.
*   Novos campos sensíveis na aplicação devem usar o `EncryptedType` ou as funções de `encrypt_for_storage`.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Integrar com um HSM ou KMS de nuvem para o armazenamento e operações com chaves de mais alto nível.
*   [ ] Implementar \"Envelope Encryption\" de forma mais explícita se usando KMS de nuvem.
*   [ ] Adicionar suporte para criptografia assimétrica (chave pública/privada) se houver casos de uso (ex: compartilhar dados criptografados com terceiros de forma segura).
*   [ ] Desenvolver uma política de \"destruição criptográfica\" para dados que precisam ser permanentemente irrecuperáveis (destruindo a chave de criptografia associada).
*   [ ] Automatizar e robustecer o processo de recriptografia de dados em segundo plano para grandes volumes de dados, com monitoramento de progresso e tratamento de falhas.

---

*Última atualização: 2025-05-12*

---

Criptografia e gerenciamento de chaves são complexos, mas essenciais!

Temos agora uma boa base de módulos Core e de Segurança. Onde gostaria de ir agora?
Podemos detalhar os submódulos dos `Shared.Utils` (`MapUtils`, `ListUtils`, `ValidationUtils`, `FileUtils`, `SecurityUtils`), ou talvez um módulo de domínio como `DeeperHub.OAuth` ou `DeeperHub.MFA`?"""),
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
                types.Part.from_text(text="""Ok, dado que `DeeperHub.Shared.Utils` é um agrupador, vamos detalhar um de seus componentes que é frequentemente usado em toda a aplicação: `DeeperHub.Shared.Utils.MapUtils`.

---

