# Documentação Deeper: Gerenciamento de Arquivos

Este módulo da API \"Deeper\" é responsável pelo upload, armazenamento, recuperação e gerenciamento de metadados de arquivos. Ele visa replicar e modernizar as funcionalidades encontradas nas tabelas `sys_objects_storage`, `sys_files` (e suas variantes como `sys_images`), `sys_storage_*`, entre outras do sistema UNA.

## Responsabilidades Principais:

*   **Upload de Arquivos:** Permitir que clientes enviem arquivos para o servidor.
*   **Armazenamento de Arquivos:**
    *   Inicialmente, os arquivos serão armazenados no sistema de arquivos local do servidor \"Deeper\".
    *   A arquitetura deve permitir a futura integração com provedores de armazenamento em nuvem (ex: S3, Google Cloud Storage), similar ao conceito de `sys_objects_storage` do UNA.
*   **Armazenamento de Metadados:** Registrar informações sobre cada arquivo (nome, tipo MIME, tamanho, data de upload, ID do uploader, etc.) no banco de dados SQLite.
*   **Recuperação de Arquivos:** Fornecer endpoints para acessar/baixar os arquivos.
*   **Gerenciamento de Acesso:**
    *   Controlar quem pode fazer upload e acessar arquivos (integrado com ACL e, potencialmente, status \"privado\" do arquivo).
    *   Gerar tokens de acesso temporário para arquivos privados, se necessário.
*   **Cotas de Usuário (Opcional/Futuro):** Implementar a lógica de `sys_storage_user_quotas`.
*   **Tipos MIME e Ícones (Opcional/Futuro):** Gerenciar `sys_storage_mime_types`.
*   **Limpeza de Arquivos (Opcional/Futuro):** Lógica de `sys_storage_deletions` e `sys_storage_ghosts`.

## Tabelas do Banco de Dados UNA Relevantes (Adaptadas para SQLite):

*   **`sys_objects_storage`**: Define diferentes \"motores\" de armazenamento. Para \"Deeper\", inicialmente teremos um tipo \"local\", mas a API pode expor essa configuração.
*   **`sys_files`**: Tabela principal para metadados de arquivos genéricos.
*   **`sys_images`**: (Pode ser unificada com `sys_files` ou mantida separada para otimizações/campos específicos de imagem).
*   **`sys_storage_ghosts`**: Arquivos que estão referenciados, mas o arquivo físico pode não existir ou está pendente de processamento.
*   **`sys_storage_tokens`**: Para acesso seguro a arquivos.
*   **`sys_storage_user_quotas`**: Cotas de armazenamento por usuário.
*   **`sys_storage_mime_types`**: Mapeamento de extensões para tipos MIME e ícones.
*   **`sys_storage_deletions`**: Fila para arquivos a serem excluídos.

## Componentes Detalhados:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas mencionadas acima, adaptadas para o contexto \"Deeper\".

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir e sua documentação para criar as tabelas do sistema de gerenciamento de arquivos.

3.  [**Módulos de Acesso a Dados (`data_access_modules.md`)**](./data_access_modules.md):
    *   Descreve os módulos Elixir (ex: `Deeper.Files.StorageRepo`, `Deeper.Files.FilesRepo`) que encapsulam as queries SQL.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para upload, download, listagem e gerenciamento de arquivos.

## Fluxo de Upload Típico:

1.  Cliente (autenticado) envia uma requisição `POST` para um endpoint de upload (ex: `POST /api/v1/files/upload`) com o arquivo como `multipart/form-data`.
2.  API recebe o arquivo.
3.  O arquivo é salvo em um local temporário ou diretamente no local de armazenamento final (configurável).
4.  Metadados do arquivo (nome, tamanho, tipo MIME, ID do usuário, etc.) são extraídos.
5.  Uma nova entrada é criada na tabela `sys_files` (ou equivalente) com esses metadados e o caminho/identificador do arquivo no armazenamento.
6.  API retorna uma resposta JSON com os detalhes do arquivo recém-criado (incluindo seu ID e URL de acesso).

## Considerações de Segurança para Acesso a Arquivos:

*   **Arquivos Públicos:** Podem ser servidos diretamente pelo servidor web (ex: Nginx) ou através de um endpoint da API que lê e transmite o arquivo.
*   **Arquivos Privados:**
    *   O acesso deve ser verificado pela API (permissões do usuário).
    *   A API pode transmitir o arquivo diretamente ou gerar URLs assinadas/tokens de acesso de curta duração para o cliente baixar de um armazenamento (especialmente útil para S3).

Este sistema é fundamental para a maioria dos módulos de conteúdo que lidam com mídia.