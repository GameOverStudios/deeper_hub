# Módulo: `DeeperHub.Security.PathTraversalProtection` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Security.PathTraversalProtection`

O módulo `DeeperHub.Security.PathTraversalProtection` é dedicado a prevenir ataques de **Path Traversal (também conhecido como Directory Traversal)** no sistema DeeperHub. Este tipo de ataque ocorre quando um invasor manipula variáveis de entrada que são usadas para construir caminhos de arquivos, com o objetivo de acessar arquivos ou diretórios fora do diretório raiz pretendido pela aplicação. Sequências como `../` (ponto-ponto-barra) são comumente usadas para \"subir\" na hierarquia de diretórios.

Este módulo fornece funcionalidades para:
1.  Verificar se um caminho fornecido pelo usuário contém sequências de path traversal.
2.  Sanitizar caminhos para remover ou neutralizar essas sequências.
3.  Normalizar caminhos para uma forma canônica.
4.  Verificar se um caminho resolvido reside dentro de um diretório base permitido.

O objetivo é garantir que o acesso a arquivos seja restrito aos diretórios designados e que entradas maliciosas não resultem em acesso não autorizado a arquivos sensíveis do sistema. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Detecção de Path Traversal (`check_path/2`):**
    *   Analisar uma string de caminho para identificar a presença de sequências como `../`, `..\\`, ou suas variações codificadas (ex: `%2e%2e%2f`).
*   **Sanitização de Caminhos (`sanitize_path/2`):**
    *   Remover ou neutralizar sequências de path traversal de uma string de caminho.
    *   Opcionalmente, resolver o caminho para sua forma canônica após a sanitização.
*   **Normalização de Caminhos (`normalize_path/2`):**
    *   Converter um caminho para sua forma canônica e absoluta, resolvendo `.` e `..` e removendo barras duplicadas.
*   **Verificação de Diretório Base (`verify_path_in_base/3`):**
    *   Garantir que um caminho normalizado e absoluto esteja contido dentro de um ou mais diretórios base permitidos e configurados.
*   **Configuração de Diretórios Base Permitidos (`configure_allowed_dirs/1`):**
    *   Permitir que administradores definam quais diretórios são seguros para a aplicação acessar ou servir arquivos.
*   **Registro de Tentativas (`record_attempt/2`):**
    *   Logar tentativas de path traversal detectadas para auditoria e monitoramento.
*   **Estatísticas (`get_statistics/1`):**
    *   Coletar métricas sobre tentativas de path traversal detectadas.
*   **Integração com Upload/Download de Arquivos:**
    *   Ser utilizado por módulos que lidam com upload, download ou qualquer forma de acesso a arquivos baseada em entrada do usuário.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Security.PathTraversalProtection` (Fachada Pública):**
    *   Ponto de entrada para as funcionalidades de proteção.
    *   Delega para o `PathTraversalProtectionService`.
2.  **`DeeperHub.Security.PathTraversalProtection.Services.PathTraversalProtectionService` (Módulo Funcional):**
    *   **Responsabilidade:** Contém a lógica principal para `check_path`, `sanitize_path`, `normalize_path`, e `verify_path_in_base`.
    *   **Interações:**
        *   Utiliza funções do módulo `Path` do Elixir para manipulação de caminhos.
        *   Interage com `DeeperHub.Core.ConfigManager` para obter a lista de diretórios base permitidos e outras configurações.
        *   Interage com `DeeperHub.Audit` ou `DeeperHub.Security.Monitoring` para registrar tentativas.
3.  **Configurações (via `DeeperHub.Core.ConfigManager` e `DeeperHub.Security.Policy.SecurityPolicyManager`):**
    *   Lista de diretórios base permitidos.
    *   Padrões de detecção (se usar regex mais avançadas).
    *   Política de ação ao detectar uma tentativa (logar, bloquear).

### 3.2. Estrutura de Diretórios (Proposta)

```
security/path_traversal_protection/
├── path_traversal_protection.ex                 # Fachada Pública
│
└── services/
    └── path_traversal_protection_service.ex     # Lógica principal
```
*(Este módulo é geralmente mais simples e pode não necessitar de um GenServer ou supervisor próprio, a menos que gerencie estado complexo ou tarefas de background, o que não é típico para esta funcionalidade.)*

### 3.3. Decisões de Design Importantes

*   **Normalização Antes da Verificação:** É crucial normalizar os caminhos para sua forma canônica antes de realizar verificações de diretório base. Isso ajuda a evitar bypasses usando diferentes codificações ou sequências de `.` e `..`.
*   **Verificação de Lista Branca de Diretórios Base:** A abordagem mais segura é definir explicitamente quais diretórios a aplicação pode acessar.
*   **Cuidado com Symlinks:** A normalização (`Path.expand/1`) resolve symlinks. É importante estar ciente de como isso interage com as verificações de diretório base, para evitar que um symlink aponte para fora de um diretório permitido.
*   **Contexto do Sistema Operacional:** A manipulação de caminhos pode ter nuances dependendo do sistema operacional (barras vs. contrabarras). O módulo `Path` do Elixir ajuda a abstrair isso.

## 🛠️ 4. Casos de Uso Principais

*   **Download de Arquivo Solicitado pelo Usuário:**
    *   Usuário clica em um link: `/download?file=report.pdf`. O backend recebe `filename = \"report.pdf\"`.
    *   Antes de acessar o arquivo:
        1.  `{:ok, :safe} = PathTraversalProtection.check_path(filename)`
        2.  `{:ok, normalized_filename} = PathTraversalProtection.normalize_path(Path.join(@upload_dir, filename))`
        3.  `{:ok, :allowed} = PathTraversalProtection.verify_path_in_base(normalized_filename, @upload_dir)`
    *   Se todas as verificações passarem, o arquivo é servido.
*   **Tentativa de Acesso Malicioso:**
    *   Invasor tenta: `/download?file=../../../../etc/passwd`.
    *   `PathTraversalProtection.check_path(\"../../../../etc/passwd\")` retorna `{:ok, :unsafe}`.
    *   `PathTraversalProtection.record_attempt(\"../../../../etc/passwd\", %{ip: ..., user_id: ...})`.
    *   A requisição é bloqueada.
*   **Upload de Arquivo com Nome Manipulado:**
    *   Usuário tenta fazer upload de um arquivo com o nome `../avatar.jpg`.
    *   O serviço de upload, antes de construir o caminho final, deve usar `Path.basename(user_supplied_filename)` para pegar apenas o nome do arquivo e depois juntá-lo com o diretório de upload seguro, ou usar `sanitize_path` no nome do arquivo.

## 🌊 5. Fluxos Importantes

### Fluxo de Validação de Caminho para Acesso a Arquivo

1.  **Entrada do Usuário:** Aplicação recebe um nome de arquivo ou caminho parcial de uma fonte não confiável (ex: parâmetro de URL, formulário).
2.  **Verificação Inicial (`check_path/2`):**
    *   `DeeperHub.Security.PathTraversalProtection.check_path(user_input_path)`
    *   Se retornar `{:ok, :unsafe}`, a operação é imediatamente interrompida, a tentativa é logada/auditada.
3.  **Construção do Caminho Completo:**
    *   Juntar o `user_input_path` (que passou na verificação inicial ou foi sanitizado) com o diretório base esperado para a operação (ex: `Path.join(Config.get(:upload_directory), user_input_path)`).
4.  **Normalização do Caminho (`normalize_path/2`):**
    *   `{:ok, canonical_path} = DeeperHub.Security.PathTraversalProtection.normalize_path(full_path)`
    *   Isso resolve quaisquer `.` ou `..` que possam ter restado ou sido formados pela junção.
5.  **Verificação de Diretório Base (`verify_path_in_base/3`):**
    *   `DeeperHub.Security.PathTraversalProtection.verify_path_in_base(canonical_path, Config.get(:upload_directory))`
    *   Se retornar `{:ok, :denied}`, a operação é interrompida, a tentativa é logada/auditada.
6.  **Acesso ao Arquivo:** Se todas as verificações passarem, o `canonical_path` pode ser usado para acessar o arquivo.

## 📡 6. API (Funções Públicas da Fachada)

### 6.1. `DeeperHub.Security.PathTraversalProtection.check_path(path :: String.t(), opts :: keyword()) :: {:ok, :safe | :unsafe} | {:error, term()}`

*   **Descrição:** Verifica se uma string de caminho contém sequências de path traversal (ex: `../`). Não resolve ou normaliza o caminho.
*   **`opts`:**
    *   `:patterns_to_check` (list(Regex.t()), opcional): Regexes adicionais para verificar.
*   **Retorno:** `:safe` se nenhuma sequência perigosa for detectada, `:unsafe` caso contrário.

### 6.2. `DeeperHub.Security.PathTraversalProtection.sanitize_path(path :: String.t(), opts :: keyword()) :: {:ok, String.t()} | {:error, term()}`

*   **Descrição:** Tenta remover ou neutralizar sequências de path traversal de uma string de caminho.
*   **`opts`:**
    *   `:replacement_strategy` (atom): Como lidar com `../` (ex: `:remove`, `:replace_with_underscore`). (Padrão: `:remove`)
*   **Retorno:** A string de caminho sanitizada.

### 6.3. `DeeperHub.Security.PathTraversalProtection.normalize_path(path :: String.t(), opts :: keyword()) :: {:ok, String.t()} | {:error, term()}`

*   **Descrição:** Converte um caminho para sua forma canônica e absoluta, resolvendo `.` , `..` e symlinks (via `Path.expand/1`).
*   **`opts`:**
    *   `:relative_to` (String.t): Diretório base para resolver caminhos relativos. (Padrão: diretório de trabalho atual).
*   **Retorno:** O caminho absoluto e normalizado.
*   **Atenção:** O uso de `Path.expand/1` implica acesso ao sistema de arquivos.

### 6.4. `DeeperHub.Security.PathTraversalProtection.verify_path_in_base(target_path :: String.t(), allowed_base_dir :: String.t() | list(String.t()), opts :: keyword()) :: {:ok, :allowed | :denied} | {:error, term()}`

*   **Descrição:** Verifica se o `target_path` (que deve ser absoluto e normalizado) está contido dentro do `allowed_base_dir` (ou qualquer um na lista de diretórios base).
*   **`opts`:**
    *   `:ensure_target_exists` (boolean): Se `true`, também verifica se `target_path` existe no sistema de arquivos. (Padrão: `false`)
*   **Retorno:** `:allowed` se seguro, `:denied` se fora do diretório base.

### 6.5. `DeeperHub.Security.PathTraversalProtection.configure_allowed_dirs(list_of_absolute_paths :: list(String.t())) :: :ok | {:error, term()}`

*   **Descrição:** Define a lista de diretórios base que são considerados seguros para a aplicação acessar diretamente. Essa configuração seria armazenada no `Core.ConfigManager`.
*   **Nota:** É mais provável que essa configuração seja gerenciada pelo `SecurityPolicyManager`.

### 6.6. `DeeperHub.Security.PathTraversalProtection.record_attempt(attempted_path :: String.t(), source_info :: map()) :: :ok`

*   **Descrição:** Registra uma tentativa de path traversal.
*   **`source_info`:** `%{ip_address: \"...\", user_id: \"...\", request_path: \"...\"}`.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager` e/ou `DeeperHub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :path_traversal, :enabled]`** (Boolean): Habilita/desabilita as verificações. (Padrão: `true`)
*   **`[:security, :path_traversal, :allowed_base_directories]`** (List de Strings): Lista de caminhos absolutos para os diretórios base permitidos (ex: `[\"/var/www/deeper_hub/uploads\", \"/var/www/deeper_hub/public_assets\"]`). Esta é uma configuração CRÍTICA.
*   **`[:security, :path_traversal, :log_suspicious_attempts]`** (Boolean): Se tentativas detectadas devem ser logadas. (Padrão: `true`)
*   **`[:security, :path_traversal, :block_on_suspicious_attempt]`** (Boolean): Se deve bloquear a requisição ao detectar uma tentativa. (Padrão: `true` para a maioria dos casos)
*   **`[:security, :path_traversal, :default_sanitize_strategy]`** (Atom): Estratégia padrão para `sanitize_path/2`. (Padrão: `:remove`)

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`: Para obter a lista de diretórios base permitidos e outras configurações.
*   `DeeperHub.Core.Logger`: Para logging.
*   `DeeperHub.Audit` ou `DeeperHub.Security.Monitoring`: Para registrar tentativas.

### 8.2. Bibliotecas Externas

*   Nenhuma específica, utiliza principalmente o módulo `Path` do Elixir.

## 🤝 9. Como Usar / Integração

*   **Qualquer módulo que lide com caminhos de arquivo fornecidos pelo usuário:**
    *   **Uploads:** Antes de salvar um arquivo com um nome fornecido pelo usuário, use `Path.basename/1` no nome do arquivo do usuário e depois junte-o com um diretório de upload seguro.
        ```elixir
        def handle_upload(user_supplied_filename, file_binary) do
          base_upload_dir = ConfigManager.get([:storage, :upload_dir]) # Ex: \"/srv/uploads\"
          safe_filename = Path.basename(user_supplied_filename) # Pega apenas o nome do arquivo
          
          # Validação adicional no safe_filename (ex: caracteres permitidos)
          # ...

          final_path = Path.join(base_upload_dir, safe_filename)

          # Verificar se final_path ainda está dentro do base_upload_dir (após Path.join, pode não ser necessário se base_upload_dir for absoluto e safe_filename não tiver barras)
          # Mas para ser extra seguro, especialmente se base_upload_dir puder ser relativo ou safe_filename puder ser manipulado:
          {:ok, normalized_final_path} = DeeperHub.Security.PathTraversalProtection.normalize_path(final_path)
          case DeeperHub.Security.PathTraversalProtection.verify_path_in_base(normalized_final_path, base_upload_dir) do
            {:ok, :allowed} -> File.write(normalized_final_path, file_binary)
            _ -> {:error, :unsafe_path}
          end
        end
        ```
    *   **Downloads/Acesso a Arquivos:**
        ```elixir
        def serve_file(conn, requested_file) do
          allowed_dirs = ConfigManager.get([:security, :path_traversal, :allowed_base_directories])
          
          case DeeperHub.Security.PathTraversalProtection.check_path(requested_file) do
            {:ok, :unsafe} ->
              DeeperHub.Security.PathTraversalProtection.record_attempt(requested_file, %{ip: ..., conn: conn})
              send_resp(conn, 403, \"Forbidden\")
            {:ok, :safe} ->
              # Tentar encontrar o arquivo em cada diretório base permitido
              found_path = Enum.find_value(allowed_dirs, fn base_dir ->
                potential_path = Path.join(base_dir, requested_file)
                {:ok, normalized_path} = DeeperHub.Security.PathTraversalProtection.normalize_path(potential_path)
                case DeeperHub.Security.PathTraversalProtection.verify_path_in_base(normalized_path, base_dir) do
                  {:ok, :allowed} when File.exists?(normalized_path) -> normalized_path
                  _ -> nil
                end
              end)

              if found_path do
                Plug.Conn.send_file(conn, 200, found_path)
              else
                send_resp(conn, 404, \"Not Found\")
              end
          end
        end
        ```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar `check_path/2` com vários vetores de path traversal (ex: `../`, `..\\`, `%2e%2e%2f`, `..%2f`, caminhos absolutos inesperados).
*   Testar `sanitize_path/2` para garantir que ele remove/neutraliza corretamente as sequências.
*   Testar `normalize_path/2` com caminhos complexos, incluindo `.` e `..`.
*   Testar `verify_path_in_base/3` com caminhos que estão dentro, fora, e na borda dos diretórios base permitidos, incluindo casos com symlinks se relevante para o ambiente.
*   Localização: `test/deeper_hub/security/path_traversal_protection/`.

### 10.2. Métricas

*   `deeper_hub.security.path_traversal.paths_checked.count`
*   `deeper_hub.security.path_traversal.unsafe_paths_detected.count` (tags: `context_operation`)
*   `deeper_hub.security.path_traversal.paths_sanitized.count`
*   `deeper_hub.security.path_traversal.access_denied_base_dir.count`

### 10.3. Logs

*   **Nível WARNING:** `check_path/2` detecta um caminho `unsafe`. `verify_path_in_base/3` nega acesso.
*   **Nível INFO/DEBUG:** Detalhes da normalização de caminhos, se complexa.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :path_traversal, :check_path, :stop]`
    *   Metadados: `%{input_path: path, result: :safe | :unsafe}`
*   `[:deeper_hub, :security, :path_traversal, :verify_base, :stop]`
    *   Metadados: `%{target_path: path, base_dir: dir, result: :allowed | :denied}`

## ❌ 11. Tratamento de Erros

*   Detecção de path traversal (`:unsafe` ou `:denied`) deve, na maioria dos casos, resultar no bloqueio da operação e, possivelmente, da requisição.
*   Erros internos no serviço (ex: falha ao ler configuração de diretórios base) devem ser logados criticamente e o sistema deve falhar de forma segura (negar acesso a arquivos).

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Configuração Correta dos Diretórios Base:** A segurança deste módulo depende fortemente da configuração correta e restritiva dos `allowed_base_directories`. Eles devem ser caminhos absolutos e não devem ser muito amplos.
*   **Symlinks:** Se o sistema de arquivos subjacente usa symlinks, `Path.expand/1` (usado em `normalize_path`) os resolverá. É preciso garantir que um symlink dentro de um diretório permitido não aponte para uma localização fora dele que não deveria ser acessível.
*   **Codificações de Caminho:** Esteja ciente de diferentes codificações de caracteres (URL encoding, double encoding) que os invasores podem usar para tentar contornar as verificações. As funções de verificação devem lidar com as formas canônicas.

## 🧑‍💻 13. Contribuição

*   Sempre valide e normalize caminhos antes de usá-los em operações de sistema de arquivos.
*   Use `Path.join/2` para construir caminhos de forma segura, mas sempre valide o resultado final se algum componente vier de entrada não confiável.
*   Ao definir `allowed_base_directories`, seja o mais específico possível.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Adicionar suporte para políticas de path traversal mais granulares, baseadas no contexto da operação ou no tipo de arquivo.
*   [ ] Integrar com um sistema de \"sandboxing\" ou capabilities no nível do sistema operacional para restringir ainda mais onde o processo Elixir pode ler/escrever arquivos, como uma camada de defesa adicional.
*   [ ] Desenvolver regexes mais sofisticadas para `check_path/2` para detectar técnicas de evasão mais obscuras, mantendo a performance.
*   [ ] Opção para normalizar caminhos sem acessar o sistema de arquivos (ou seja, sem resolver symlinks via `Path.expand`), útil para validação pura de strings de caminho antes de qualquer I/O.

---

*Última atualização: 2025-05-12*

---

Proteção contra Path Traversal é crucial para qualquer aplicação que lida com arquivos.

O que vem agora? Poderíamos cobrir `DeeperHub.Security.DdosProtection` ou talvez mudar para um módulo Core como `DeeperHub.Core.Cache` para variar um pouco?"""),
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
                types.Part.from_text(text="""Ok, vamos continuar com a camada de segurança e detalhar o `DeeperHub.Security.DdosProtection`. Ataques de Negação de Serviço Distribuída são uma ameaça significativa para a disponibilidade de qualquer serviço online.

---

