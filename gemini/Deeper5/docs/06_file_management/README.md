# Documentação Deeper: Gerenciamento de Arquivos

Este diretório detalha a API \"Deeper\" para o gerenciamento de arquivos, incluindo upload, armazenamento, recuperação e, potencialmente, transformações básicas (como redimensionamento de imagens, se não for delegado a um sistema de transcodificação separado em `08_advanced_features`). Este sistema se baseará nos conceitos de `sys_objects_storage` e tabelas de arquivos do UNA (ex: `sys_files`, `sys_images`, `bx_persons_pictures`).

## Abordagem \"Deeper\" para Gerenciamento de Arquivos:

O UNA utiliza `sys_objects_storage` para definir diferentes \"motores\" de armazenamento (ex: Local, S3). Cada arquivo upado é registrado em uma tabela de metadados (ex: `sys_files` para arquivos genéricos, ou tabelas específicas como `bx_persons_pictures`).

Para \"Deeper\":

1.  **\"Storages\" Configuráveis:** Manteremos o conceito de múltiplos backends de armazenamento, configuráveis. Inicialmente, podemos focar em um armazenamento local, com a possibilidade de expandir para S3 ou outros.
2.  **Tabela de Metadados de Arquivos Unificada (Proposta):** `deeper_files`
    *   Armazenaria metadados para todos os tipos de arquivos (imagens, vídeos, documentos).
    *   Colunas: `id` (UUID ou auto-incremento), `profile_id` (quem fez o upload), `storage_object_name` (qual configuração de storage foi usada), `original_filename`, `path_on_storage` (relativo ao root do storage), `mime_type`, `size_bytes`, `extension`, `meta_data` (JSON para dimensões de imagem, duração de vídeo, etc.), `is_private` (flag de privacidade), `created_at`, `updated_at`.
    *   Esta tabela `deeper_files` poderia substituir as múltiplas tabelas de arquivos do UNA (`sys_files`, `sys_images`, `bx_persons_pictures`, `sys_cmts_images`, etc.) para simplificar, ou pode coexistir se a migração de dados for muito complexa. Para um novo sistema \"Deeper\", uma tabela unificada é preferível.
3.  **Endpoints da API:**
    *   Um endpoint para upload de arquivos.
    *   Endpoints para recuperar arquivos (seja por URL direta ou streaming pela API).
    *   Endpoints para gerenciar metadados de arquivos (listar, deletar - com permissões).

## Responsabilidades Principais da API de Gerenciamento de Arquivos:

*   Permitir o upload seguro de arquivos por usuários autenticados.
*   Armazenar os arquivos no backend de armazenamento configurado.
*   Registrar os metadados dos arquivos.
*   Fornecer URLs seguras ou conteúdo de arquivo para download/exibição.
*   Gerenciar permissões de acesso a arquivos privados.
*   (Opcional) Lidar com redimensionamento básico de imagens no upload, se não houver um sistema de transcodificação mais avançado.

## Estrutura da Documentação para Gerenciamento de Arquivos:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   `CREATE TABLE` para `sys_objects_storage` (adaptado), `deeper_files` (proposta), e tabelas para versões redimensionadas (`deeper_file_versions` ou `deeper_image_resized`).

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Módulos de migração.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.FileManagement.FileRepo` (para metadados) e `Deeper.FileManagement.StorageManager` (para interagir com os backends de armazenamento).

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints para upload, download e gerenciamento.

## Considerações de Design:

*   **Upload:**
    *   Usar requisições `multipart/form-data`.
    *   Validação de tipo de arquivo, tamanho máximo.
    *   ACL para quem pode fazer upload e para qual \"propósito\" (ex: avatar, anexo de artigo).
*   **Armazenamento:**
    *   O `StorageManager` abstrairia o local de armazenamento (local, S3).
    *   Configurações de storage viriam de `sys_objects_storage` ou de uma configuração \"Deeper\".
*   **Segurança de Arquivos Privados:** Se `is_private = true`, a API deve verificar as permissões do solicitante antes de servir o arquivo ou sua URL. URLs diretas para arquivos privados geralmente não são expostas; em vez disso, a API atua como um proxy.
*   **Nomenclatura de Arquivos:** Gerar nomes de arquivo únicos no armazenamento para evitar colisões.
*   **URLs de Arquivos:** A API deve retornar URLs completas e acessíveis para os arquivos (ex: para tags `<img>` ou links de download).
*   **Transcodificação/Redimensionamento (Escopo):**
    *   **Básico:** Upload de imagem pode gerar thumbnails comuns.
    *   **Avançado:** Para vídeos, PDFs, etc., um sistema de transcodificação mais robusto (discutido em `08_advanced_features/sys_transcoding_api.md`) seria necessário. A API de upload pode enfileirar tarefas de transcodificação.
    *   O UNA tem `sys_objects_transcoder` e `sys_transcoder_images_files`, `sys_transcoder_videos_files`. \"Deeper\" pode adaptar essa ideia.