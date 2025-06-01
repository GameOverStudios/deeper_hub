# Documentação Deeper: Endpoints da API para Gerenciamento de Arquivos

Este documento especifica os endpoints RESTful para o upload, recuperação e gerenciamento de arquivos no sistema \"Deeper\".

**Convenções Gerais:**
*   Endpoints sob `/api/v1`.
*   Respostas e corpos de requisição em JSON (exceto para upload de arquivo que é `multipart/form-data` e download de arquivo que é o próprio arquivo).
*   Autenticação JWT obrigatória para upload e gerenciamento de arquivos, e para acesso a arquivos privados.
*   Códigos de status HTTP e formatos de erro seguem as [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md).
*   ACL será aplicado (quem pode fazer upload, para qual propósito, quem pode acessar/deletar).

---

## 1. Upload de Arquivos (`/files`)

### 1.1. Fazer Upload de um Novo Arquivo

*   **Endpoint:** `POST /files/upload`
*   **Autenticação:** Requerida (JWT).
*   **Descrição:** Permite que um usuário autenticado faça upload de um novo arquivo.
*   **Tipo de Requisição:** `multipart/form-data`
*   **Campos do Formulário (multipart):**
    *   `file`: O arquivo binário a ser upado (obrigatório).
    *   `storage_backend_name` (opcional): Nome do backend de armazenamento a ser usado (de `deeper_storage_backends.storage_name`). Se omitido, usa o backend padrão.
    *   `is_private` (opcional, boolean `true`|`false` ou `1`|`0`): Se o arquivo deve ser privado (default: `false`).
    *   `original_filename` (opcional): Se o cliente quiser sugerir um nome original diferente do que está no cabeçalho do upload.
    *   `purpose` (opcional, string): Uma chave para indicar o propósito do arquivo (ex: `avatar`, `article_featured_image`, `comment_attachment`). Isso pode influenciar o `storage_backend_name` usado, validações ou o `stored_path`.
    *   `meta_data` (opcional, string JSON): Metadados adicionais a serem armazenados com o arquivo.
*   **Resposta de Sucesso (201 Created):**

```json
    {
      \"data\": {
        \"id\": 123, // ID do arquivo em deeper_files
        \"original_filename\": \"minha_imagem.jpg\",
        \"stored_filename\": \"abcdef123456.jpg\", // Nome gerado no storage
        \"stored_path\": \"user_uploads/2023/10/\",
        \"mime_type\": \"image/jpeg\",
        \"size_bytes\": 102400,
        \"extension\": \"jpg\",
        \"is_private\": false,
        \"url\": \"/api/v1/files/abcdef123456.jpg/view\", // URL para visualizar/baixar (pode variar se for presigned)
        \"meta_data\": {\"width\": 800, \"height\": 600}, // Exemplo
        \"created_at\": 1678895000
      }
    }
```

```json
    {
      \"data\": {
        \"id\": 123,
        \"original_filename\": \"minha_imagem.jpg\",
        \"stored_filename\": \"abcdef123456.jpg\",
        \"mime_type\": \"image/jpeg\",
        \"size_bytes\": 102400,
        \"is_private\": false,
        \"meta_data\": {\"width\": 800, \"height\": 600},
        \"created_at\": 1678895000,
        \"uploader_profile_id\": 15,
        \"url\": \"/api/v1/files/abcdef123456.jpg/view\" // URL de visualização/download
        // Incluir URLs para versões/thumbnails se existirem
        // \"versions\": {
        //   \"thumbnail_small\": \"/api/v1/files/abcdef123456.jpg/view?version=thumbnail_small\"
        // }
      }
    }
```

*   **Respostas de Erro:**
    *   `400 Bad Request`: Arquivo ausente, tipo de arquivo não permitido, tamanho excede o limite.
    *   `401 Unauthorized`.
    *   `403 Forbidden`: Usuário não tem permissão para fazer upload (ACL geral ou para o `purpose` específico).
    *   `500 Internal Server Error` (ex: falha ao salvar no storage, falha ao registrar no DB).
*   **Lógica de Backend (Controller):**
    1.  Extrair `uploader_profile_id` do JWT.
    2.  Verificar permissão ACL para upload (e para o `purpose` se fornecido).
    3.  Receber o arquivo upado (`Plug.Upload`).
    4.  Validar tipo de arquivo, tamanho (configurações podem vir de `sys_options` ou `deeper_storage_backends`).
    5.  Determinar o `storage_backend_name` (do request ou default).
    6.  Chamar `Deeper.FileManagement.FileRepo.get_storage_backend_config/1`.
    7.  Instanciar o adaptador `StorageManager` apropriado.
    8.  Gerar `stored_filename` único e `stored_path` (ex: baseado em data, `uploader_profile_id`, `purpose`).
    9.  Coletar metadados do arquivo (`mime_type`, `size_bytes`, `extension`, `original_filename`).
    10. Chamar `StorageManager.store_file/2` para salvar o arquivo físico.
    11. Se sucesso, chamar `Deeper.FileManagement.FileRepo.create_file_record/1` para salvar metadados.
    12. (Opcional) Se for imagem e redimensionamento básico estiver habilitado, gerar thumbnails e salvar suas infos (ou criar registros em `deeper_file_versions`).
    13. (Opcional) Se for vídeo/áudio e transcodificação for necessária, enfileirar uma tarefa de transcodificação.
    14. Construir e retornar a URL de acesso ao arquivo.

---

## 2. Acesso a Arquivos (`/files/{identifier}`)

### 2.1. Visualizar/Baixar Arquivo

*   **Endpoint:** `GET /files/{stored_filename_or_id}/{action}`
    *   `stored_filename_or_id`: O `deeper_files.stored_filename` (preferencialmente) ou `deeper_files.id`.
    *   `action`: Pode ser `view` (para tentar exibir inline) ou `download` (para forçar download).
*   **Autenticação:** Requerida se o arquivo for privado (`deeper_files.is_private = 1`).
*   **Descrição:** Serve o conteúdo do arquivo. Para arquivos públicos em alguns storages (ex: S3 público), este endpoint pode redirecionar para a URL pública direta. Para arquivos privados, ou arquivos em storage local, a API atua como um proxy.
*   **Query Parameters (Opcionais para imagens/versões):**
    *   `version={version_profile_name}` (ex: `thumbnail_small`): Para solicitar uma versão específica do arquivo (se `deeper_file_versions` for usado).
*   **Resposta de Sucesso:**
    *   **Para `view` e tipos de mídia suportados (imagem, pdf):**
        *   Status `200 OK`.
        *   Header `Content-Type` apropriado (ex: `image/jpeg`).
        *   Header `Content-Disposition: inline; filename=\"original_filename.jpg\"`.
        *   Corpo da resposta é o conteúdo binário do arquivo.
    *   **Para `download` ou tipos não visualizáveis inline:**
        *   Status `200 OK`.
        *   Header `Content-Type: application/octet-stream` (ou o MIME type real).
        *   Header `Content-Disposition: attachment; filename=\"original_filename.jpg\"`.
        *   Corpo da resposta é o conteúdo binário do arquivo.
    *   **Para redirecionamento (arquivos públicos em S3/CDN):**
        *   Status `302 Found`.
        *   Header `Location` apontando para a URL direta do arquivo.
*   **Respostas de Erro:** `401`, `403` (se privado e sem permissão), `404` (arquivo não encontrado).
*   **Lógica de Backend (Controller):**
    1.  Buscar metadados do arquivo via `FileRepo.get_file_record_by_id/1` ou `get_file_record_by_stored_name/2`.
    2.  Se `is_private = 1`, verificar permissão do usuário autenticado (esta lógica de permissão pode ser complexa, dependendo de como o arquivo está associado a outros conteúdos e suas regras de privacidade).
    3.  Determinar o `storage_backend_name` e obter sua configuração.
    4.  Instanciar o `StorageManager`.
    5.  Se uma `version` for solicitada, buscar os metadados da versão em `deeper_file_versions` e usar seu `stored_path/filename`.
    6.  Se o storage tiver uma `base_url` e o arquivo for público e a ação for `view`, considerar redirecionar para `StorageManager.get_public_url/3`.
    7.  Para arquivos privados ou que precisam ser servidos pela API:
        *   Chamar `StorageManager.retrieve_file/3`.
        *   Se retornar um caminho local, usar `Plug.Conn.send_file/5`.
        *   Se retornar um stream, usar `Plug.Conn.send_chunked/2`.
    8.  Definir os headers `Content-Type` e `Content-Disposition` apropriados.

### 2.2. Obter Metadados de um Arquivo

*   **Endpoint:** `GET /files/{stored_filename_or_id}/meta`
*   **Autenticação:** Opcional (se metadados básicos são públicos, ou requerida se o arquivo for privado).
*   **Descrição:** Retorna os metadados de um arquivo específico (da tabela `deeper_files`).
*   **Resposta de Sucesso (200 OK):**