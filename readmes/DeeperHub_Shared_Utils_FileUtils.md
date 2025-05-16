# Módulo: `Deeper_Hub.Shared.Utils.FileUtils` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Shared.Utils.FileUtils`

O módulo `Deeper_Hub.Shared.Utils.FileUtils` fornece um conjunto de **funções utilitárias para interagir com o sistema de arquivos**. Ele encapsula operações comuns de manipulação de arquivos e diretórios, como leitura, escrita, verificação de existência, cópia, cálculo de hash de arquivos e obtenção de informações sobre arquivos.

Este módulo visa simplificar as interações com o sistema de arquivos, fornecer uma API consistente e lidar com erros comuns de forma previsível. Ele é útil para tarefas como gerenciamento de uploads, leitura de arquivos de configuração (que não estão no `ConfigManager`), escrita de logs em arquivos (se não usar um backend de logger mais avançado), ou qualquer outra operação que necessite acesso direto a arquivos. 😊

**Importante:** O acesso direto ao sistema de arquivos deve ser feito com muito cuidado, especialmente se os caminhos dos arquivos forem influenciados por entrada do usuário. A integração com `Deeper_Hub.Security.PathTraversalProtection` é crucial nesses casos.

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Verificação de Existência:**
    *   Verificar se um arquivo existe em um determinado caminho (`file_exists?/1`).
    *   Verificar se um diretório existe.
*   **Leitura de Arquivos:**
    *   Ler o conteúdo completo de um arquivo de texto (`read_text_file/1`).
    *   Ler o conteúdo de um arquivo binário.
    *   Ler um arquivo linha por linha ou em chunks (para arquivos grandes).
*   **Escrita em Arquivos:**
    *   Escrever (ou sobrescrever) conteúdo em um arquivo de texto (`write_text_file/3`).
    *   Escrever conteúdo binário em um arquivo.
    *   Anexar conteúdo a um arquivo existente.
*   **Manipulação de Arquivos e Diretórios:**
    *   Copiar arquivos (`copy_file/3`).
    *   Mover/Renomear arquivos.
    *   Criar diretórios, incluindo diretórios pai (`ensure_dir_exists/1` - nova sugestão).
    *   Listar o conteúdo de um diretório.
    *   Excluir arquivos e diretórios.
*   **Informações de Arquivo:**
    *   Obter informações sobre um arquivo (tamanho, tipo, permissões, datas de modificação/acesso) (`get_file_info/1`).
    *   Determinar o tipo MIME de um arquivo com base em sua extensão ou conteúdo (magic bytes) (`get_mime_type/1`).
*   **Cálculo de Hash de Arquivo:**
    *   Calcular o hash (MD5, SHA1, SHA256, etc.) do conteúdo de um arquivo (`calculate_file_hash/2`).
*   **Tratamento de Erros:**
    *   Retornar resultados consistentes (ex: `{:ok, ...}` ou `{:error, reason_atom}`) para operações de arquivo.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

*   **`Deeper_Hub.Shared.Utils.FileUtils` (Módulo Funcional):**
    *   Contém todas as funções de utilidade para arquivos.
    *   Utiliza principalmente os módulos `File`, `Path`, e `:erlang.md5/:crypto` (para hashes) do Elixir/Erlang.
    *   **Importante:** As funções que recebem caminhos como entrada devem ser projetadas para funcionar bem com caminhos normalizados e validados por `Deeper_Hub.Security.PathTraversalProtection` se a origem do caminho for externa.

### 3.2. Estrutura de Diretórios

```
shared/utils/file_utils.ex
```

### 3.3. Decisões de Design Importantes

*   **Segurança Primeiro:** Qualquer função que aceite um caminho de arquivo que possa ser influenciado, mesmo que indiretamente, por entrada do usuário, deve ter sua entrada validada e normalizada por `PathTraversalProtection` *antes* de ser passada para `FileUtils`. As funções em `FileUtils` podem assumir que o caminho já é seguro para operações dentro dos diretórios base permitidos.
*   **Tratamento de Erros Explícito:** Operações de arquivo podem falhar por muitos motivos (permissões, arquivo não encontrado, disco cheio, etc.). As funções devem retornar tuplas `{:ok, ...}` ou `{:error, reason}`.
*   **Operações Binárias vs. Texto:** Fornecer funções separadas ou opções claras para lidar com arquivos de texto (com codificação) e arquivos binários.
*   **Streaming para Arquivos Grandes:** Para leitura/escrita de arquivos grandes, usar streams (`File.stream!/3`, `IO.stream/2`) para evitar carregar todo o conteúdo na memória.

## 🛠️ 4. Casos de Uso Principais

*   **Módulo de Upload de Avatares:**
    *   Após receber um upload:
        *   `safe_path = PathTraversalProtection.sanitize_and_verify(user_input_path, @avatar_base_dir)`
        *   `FileUtils.write_binary_file(safe_path, uploaded_binary_data)`
        *   `{:ok, hash} = FileUtils.calculate_file_hash(safe_path, :sha256)` (para verificar integridade ou evitar duplicatas)
*   **Leitura de um Arquivo de Configuração JSON Local (não gerenciado pelo `ConfigManager`):**
    *   `case FileUtils.read_text_file(\"/etc/deeper_hub/custom_plugin_config.json\") do {:ok, content} -> Jason.decode(content) ... end`
*   **Escrita de Logs em Arquivo (Backend de Logger Simples):**
    *   `FileUtils.write_text_file(\"/var/log/deeper_hub/service.log\", formatted_log_entry, append: true, ensure_dir: true)`
*   **Servir um Arquivo Estático Protegido:**
    *   Após verificar permissões:
        *   `safe_path = PathTraversalProtection.verify_path_in_base(user_requested_document, @secure_docs_dir)`
        *   `{:ok, file_info} = FileUtils.get_file_info(safe_path)`
        *   `Plug.Conn.send_file(conn, 200, safe_path, 0, file_info.size)`

## 🌊 5. Fluxos Importantes

### Fluxo de Escrita Segura em Arquivo com Criação de Diretório

1.  **Chamador:** `FileUtils.write_text_file(\"/opt/app/data/reports/2023/report.txt\", \"conteúdo\", ensure_dir: true)`.
    *   **Importante:** O chamador é responsável por garantir que o caminho base (`/opt/app/data/reports/2023/`) é um local seguro e permitido, e que `report.txt` não contém elementos de path traversal se vier de entrada do usuário.
2.  **`FileUtils.write_text_file/3`:**
    *   Se `ensure_dir: true`:
        *   `dir = Path.dirname(\"/opt/app/data/reports/2023/report.txt\")` -> `\"/opt/app/data/reports/2023\"`
        *   Chama `File.mkdir_p(dir)`.
    *   Chama `File.write(\"/opt/app/data/reports/2023/report.txt\", \"conteúdo\", [:write])`.
    *   Retorna o resultado de `File.write`.

## 📡 6. API (Funções Públicas do Módulo)

*(Baseado na documentação original e expandindo)*

### 6.1. `Deeper_Hub.Shared.Utils.FileUtils.file_exists?(path :: String.t()) :: boolean()`

*   **Descrição:** Verifica se um arquivo ou diretório existe no `path`. Usa `File.exists?/1`.

### 6.2. `Deeper_Hub.Shared.Utils.FileUtils.read_text_file(path :: String.t(), opts :: keyword()) :: {:ok, String.t()} | {:error, atom()}`

*   **Descrição:** Lê o conteúdo de um arquivo de texto.
*   **`opts`:** `:encoding` (Padrão: `:utf8`).
*   **Retorno:** `{:ok, content}` ou `{:error, reason}` (ex: `:enoent`, `:eacces`). Usa `File.read/1`.

### 6.3. `Deeper_Hub.Shared.Utils.FileUtils.read_binary_file(path :: String.t(), opts :: keyword()) :: {:ok, binary()} | {:error, atom()}` (Nova Sugestão)

*   **Descrição:** Lê o conteúdo de um arquivo como binário.
*   **`opts`:** (Nenhuma específica por enquanto).
*   **Retorno:** `{:ok, binary_content}` ou `{:error, reason}`. Usa `File.read/1`.

### 6.4. `Deeper_Hub.Shared.Utils.FileUtils.write_text_file(path :: String.t(), content :: String.t() | list(String.t()), opts :: keyword()) :: :ok | {:error, atom()}`

*   **Descrição:** Escreve/sobrescreve `content` em `path`.
*   **`opts`:**
    *   `:append` (boolean): Se `true`, anexa ao arquivo. (Padrão: `false`)
    *   `:ensure_dir` (boolean): Se `true`, cria o diretório pai se não existir usando `File.mkdir_p/1`. (Padrão: `false`)
    *   `:encoding` (Padrão: `:utf8`).
*   Usa `File.write/3`.

### 6.5. `Deeper_Hub.Shared.Utils.FileUtils.write_binary_file(path :: String.t(), binary_content :: binary(), opts :: keyword()) :: :ok | {:error, atom()}` (Nova Sugestão)

*   **Descrição:** Escreve/sobrescreve `binary_content` em `path`.
*   **`opts`:** `:append`, `:ensure_dir`.
*   Usa `File.write/3`.

### 6.6. `Deeper_Hub.Shared.Utils.FileUtils.copy_file(source_path :: String.t(), dest_path :: String.t(), opts :: keyword()) :: :ok | {:error, atom()}`

*   **Descrição:** Copia um arquivo de `source_path` para `dest_path`.
*   **`opts`:**
    *   `:force` (boolean): Se `true`, sobrescreve `dest_path` se existir. (Padrão: `false`, retorna erro se destino existe).
    *   `:ensure_dest_dir` (boolean): Se `true`, cria o diretório pai de `dest_path`. (Padrão: `false`)
*   Usa `File.copy/3`.

### 6.7. `Deeper_Hub.Shared.Utils.FileUtils.get_file_info(path :: String.t()) :: {:ok, File.Stat.t()} | {:error, atom()}`

*   **Descrição:** Retorna informações sobre o arquivo (tamanho, tipo, datas). Usa `File.stat/1`.

### 6.8. `Deeper_Hub.Shared.Utils.FileUtils.get_mime_type(path :: String.t()) :: {:ok, String.t()} | {:error, :extension_not_found}`

*   **Descrição:** Tenta inferir o tipo MIME com base na extensão do arquivo. Pode usar um mapa interno de extensões para tipos MIME ou uma biblioteca.
*   **Retorno:** Ex: `{:ok, \"image/png\"}`, `{:ok, \"application/octet-stream\"}` (como fallback), ou `{:error, :extension_not_found}`.

### 6.9. `Deeper_Hub.Shared.Utils.FileUtils.calculate_file_hash(path :: String.t(), algorithm :: :md5 | :sha1 | :sha256 | :sha512) :: {:ok, String.t()} | {:error, atom()}`

*   **Descrição:** Calcula o hash do conteúdo do arquivo usando o `algorithm` especificado. Retorna o hash como uma string hexadecimal.
*   Usa `:crypto.hash/2` ou `:erlang.md5/1`.

### 6.10. `Deeper_Hub.Shared.Utils.FileUtils.ensure_dir_exists(dir_path :: String.t()) :: :ok | {:error, atom()}` (Nova Sugestão)

*   **Descrição:** Garante que um diretório exista, criando-o (e seus pais) se necessário. Usa `File.mkdir_p/1`.

### 6.11. `Deeper_Hub.Shared.Utils.FileUtils.list_dir(dir_path :: String.t(), opts :: keyword()) :: {:ok, list(String.t())} | {:error, atom()}` (Nova Sugestão)

*   **Descrição:** Lista o conteúdo (arquivos e subdiretórios) de um diretório.
*   **`opts`:** `:include_hidden` (boolean).
*   Usa `File.ls/1`.

### 6.12. `Deeper_Hub.Shared.Utils.FileUtils.delete_file(path :: String.t()) :: :ok | {:error, atom()}` (Nova Sugestão)

*   **Descrição:** Exclui um arquivo. Usa `File.rm/1`.

### 6.13. `Deeper_Hub.Shared.Utils.FileUtils.delete_dir_recursive(dir_path :: String.t()) :: :ok | {:error, atom()}` (Nova Sugestão)

*   **Descrição:** Exclui um diretório e todo o seu conteúdo recursivamente. Usa `File.rm_rf/1`. **Usar com extremo cuidado.**

## ⚙️ 7. Configuração

Este módulo geralmente não tem muitas configurações próprias, mas pode ser influenciado por:
*   `[:shared, :utils, :file, :default_text_encoding]` (String): Encoding padrão para arquivos de texto. (Padrão: `\"utf-8\"`)
*   `[:shared, :utils, :file, :mime_type_mappings]` (Map): Mapa customizado de `%{\".ext\" => \"mime/type\"}` para `get_mime_type/1`.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Security.PathTraversalProtection`: Crucial para ser usado pelos chamadores deste módulo se os caminhos vierem de fontes não confiáveis.
*   `Deeper_Hub.Core.ConfigManager` (para configurações opcionais).

### 8.2. Bibliotecas Externas

*   Nenhuma, primariamente usa os módulos `File`, `Path`, `:crypto` do Elixir/Erlang.
*   Opcionalmente, uma biblioteca para detecção de MIME type mais robusta (baseada em magic bytes) se `get_mime_type/1` precisar ser mais avançado.

## 🤝 9. Como Usar / Integração

Os chamadores devem primeiro garantir que os caminhos são seguros (usando `PathTraversalProtection`) antes de passar para `FileUtils`.

```elixir
alias Deeper_Hub.Shared.Utils.FileUtils
alias Deeper_Hub.Security.PathTraversalProtection

@secure_base_dir Application.compile_env!(:my_app, :secure_file_storage_path)

def process_uploaded_document(user_filename, binary_data) do
  # 1. Pegar apenas o nome do arquivo, não o caminho completo do cliente
  safe_name = Path.basename(user_filename) 
  
  # 2. Construir o caminho completo dentro do diretório base seguro
  target_path_candidate = Path.join(@secure_base_dir, safe_name)

  # 3. Normalizar e verificar se ainda está dentro do diretório base
  case PathTraversalProtection.normalize_path(target_path_candidate) do
    {:ok, normalized_path} ->
      case PathTraversalProtection.verify_path_in_base(normalized_path, @secure_base_dir) do
        {:ok, :allowed} ->
          FileUtils.write_binary_file(normalized_path, binary_data)
        _ ->
          {:error, :unsafe_path_after_normalization}
      end
    {:error, _} ->
      {:error, :invalid_path_construction}
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar cada função com caminhos válidos e inválidos.
*   Testar operações em arquivos/diretórios existentes e não existentes.
*   Testar tratamento de erros de permissão (pode exigir configuração do sistema de arquivos no ambiente de teste).
*   Testar opções como `:append`, `:force`, `:ensure_dir`.
*   Testar `calculate_file_hash` com arquivos conhecidos.
*   Testar `get_mime_type` para extensões comuns.
*   Localização: `test/deeper_hub/shared/utils/file_utils_test.exs`.

### 10.2. Métricas / 10.3. Logs / 10.4. Telemetria

Geralmente não são emitidos diretamente por este módulo utilitário. Os chamadores seriam responsáveis por registrar métricas (ex: número de arquivos escritos, tempo de hash) ou logs de erro se uma operação de arquivo falhar.
*   Exceção: `record_attempt` em `PathTraversalProtection` seria chamado pelo código que usa `FileUtils` se uma verificação de segurança falhar *antes* de chamar `FileUtils`.

## ❌ 11. Tratamento de Erros

*   As funções retornam `{:ok, ...}` ou `{:error, reason_atom}`. Os `reason_atom` geralmente correspondem aos átomos de erro do módulo `File` (ex: `:enoent` - arquivo não encontrado, `:eacces` - permissão negada, `:eisdir` - é um diretório, etc.).
*   É responsabilidade do chamador tratar esses erros.

## 🛡️ 12. Considerações de Segurança

*   **NUNCA use entrada de usuário diretamente para construir caminhos de arquivo sem sanitização e validação rigorosa com `PathTraversalProtection`.** Este módulo `FileUtils` assume que os caminhos fornecidos já foram verificados ou são estaticamente definidos e seguros.
*   **Permissões de Arquivo:** Esteja ciente das permissões com as quais os arquivos/diretórios são criados.
*   **Condições de Corrida (Race Conditions):** Em operações como verificar se um arquivo existe e depois escrevê-lo, pode haver condições de corrida se não forem tratadas adequadamente (TOCTOU - Time-of-check to time-of-use). Use `File.write/3` com flags apropriadas ou mecanismos de bloqueio se a atomicidade for crítica (embora isso seja mais complexo).
*   **Exposição de Informações em Erros:** Erros de arquivo podem vazar informações sobre a estrutura do sistema de arquivos. Trate os erros de forma a não expor esses detalhes para o usuário final.

## 🧑‍💻 13. Contribuição

*   Mantenha as funções focadas em operações de arquivo genéricas.
*   Sempre pense nas implicações de segurança de qualquer nova função que lide com caminhos.
*   Documente claramente o comportamento de erro.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Adicionar funções para lidar com arquivos temporários de forma segura.
*   [ ] Utilitários para compressão/descompressão de arquivos (zip, gzip).
*   [ ] Funções de streaming mais avançadas para processamento de arquivos grandes.
*   [ ] Para `get_mime_type`, integrar com uma biblioteca que use \"magic bytes\" para uma detecção mais robusta do que apenas a extensão.

---

*Última atualização: 2025-05-12*

---

Este cobre `FileUtils`. O próximo utilitário natural seria `Deeper_Hub.Shared.Utils.SecurityUtils` para fechar o ciclo dos utilitários mais comuns. Depois disso, poderíamos ir para `Deeper_Hub.OAuth` ou `Deeper_Hub.MFA`?"""),
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
                types.Part.from_text(text="""Perfeito! Vamos finalizar a seção de utilitários detalhando `Deeper_Hub.Shared.Utils.SecurityUtils`. Este módulo é para helpers de segurança de baixo nível que são genéricos e não se encaixam em um módulo de segurança mais específico.

---

