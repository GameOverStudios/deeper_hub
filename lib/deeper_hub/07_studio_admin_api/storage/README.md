# Documentação Deeper Studio API: Gerenciamento de Armazenamento

Este documento descreve os endpoints da API de Administração (\"Studio API\") para o gerenciamento de \"Objetos de Armazenamento\" (`sys_objects_storage`). Esta funcionalidade permite que administradores configurem diferentes backends de armazenamento (Local, S3, etc.) para os arquivos da plataforma \"Deeper\".

**Objetivo Principal:** Permitir que administradores visualizem, criem, modifiquem e deletem configurações de objetos de armazenamento, controlando onde e como os arquivos são guardados, quais tipos são permitidos, e as cotas associadas.

## Tabelas Relevantes (já definidas e migradas):

*   `sys_objects_storage`: A tabela principal que define cada motor/objeto de armazenamento.

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.Files.StorageRepo`: Precisará de funções CRUD completas para `sys_objects_storage`.
    *   Funções para listar, criar, obter por nome, atualizar e deletar configurações de storage objects.
    *   Funções para recalcular/atualizar `current_size` e `current_number` (embora a atualização principal seja feita durante uploads/deleções, pode haver uma função de sincronização/recalque aqui).

## Endpoints da API de Administração para Armazenamento (`/api/v1/admin/storage/objects`):

---
### Gerenciamento de Objetos de Armazenamento

#### 1. Listar Todos os Objetos de Armazenamento

*   **Endpoint:** `GET /api/v1/admin/storage/objects`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"object_name\": \"bx_persons_pictures_storage\", // sys_objects_storage.object
          \"engine\": \"Local\", // S3, Wasabi, etc.
          \"table_files\": \"bx_persons_pictures\",
          \"max_file_size_bytes\": 5242880, // 5MB
          \"current_size_bytes\": 1024000,
          \"quota_size_bytes\": 10737418240 // 10GB
        }
        // ... outros storage objects ...
      ]
    }
```

```json
    {
      \"object_name\": \"general_public_files\",
      \"engine\": \"S3\",
      \"params_json\": { // Convertido para string JSON no DB
        \"bucket\": \"my-deeper-bucket\",
        \"region\": \"us-east-1\",
        \"key\": \"AWS_ACCESS_KEY\",
        \"secret\": \"AWS_SECRET_KEY\",
        \"endpoint_url\": \"https://s3.us-east-1.amazonaws.com\" // Opcional
      },
      \"token_life_seconds\": 3600,
      \"cache_control_seconds\": 2592000,
      \"levels_subdir\": 0, // Não aplicável para S3
      \"table_files_name\": \"sys_files_public\", // Nome da tabela de metadados
      \"ext_mode\": \"allow-deny\",
      \"ext_allow_csv\": \"jpg,png,gif,pdf\",
      \"ext_deny_csv\": \"exe,php\",
      \"quota_size_bytes\": 0, // Ilimitado
      \"max_file_size_bytes\": 20971520 // 20MB
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"object_name\": \"general_public_files\",
        \"engine\": \"S3\",
        \"params\": { // Parseado de string JSON do DB
          \"bucket\": \"my-deeper-bucket\",
          \"region\": \"us-east-1\"
          // NÃO expor chaves secretas aqui!
        },
        \"params_to_edit\": { // Campos que o admin pode ver/editar para params
            \"bucket\": \"my-deeper-bucket\", \"region\": \"us-east-1\", \"key\": \"AWS_ACCESS_***\" // Mascarado
        },
        \"token_life_seconds\": 3600,
        // ... todos os outros campos ...
        \"current_size_formatted\": \"1.5 GB\",
        \"quota_size_formatted\": \"100 GB\"
      }
    }
```

```json
    {
      \"data\": {
        \"object_name\": \"general_public_files\",
        \"new_current_size_bytes\": 12345678,
        \"new_current_number\": 580,
        \"message\": \"Storage usage resynchronized.\"
      }
    }
```

#### 2. Criar Novo Objeto de Armazenamento

*   **Endpoint:** `POST /api/v1/admin/storage/objects`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Todos os campos de `sys_objects_storage`.

*   **Resposta de Sucesso (201 Created):** Retorna o objeto de armazenamento criado.
*   **Lógica do Backend:**
    *   Valida os dados. `params_json` é convertido para string antes de salvar. `ext_allow_csv` e `ext_deny_csv` são convertidos para strings CSV.
    *   Insere em `sys_objects_storage`.
    *   **Importante:** A criação da `table_files_name` no banco de dados *não* é feita por este endpoint. A tabela de metadados de arquivos deve existir previamente (criada por uma migração separada, como `create_sys_files_table.elixir.md` ou uma migração específica para `sys_files_public`).

#### 3. Obter Detalhes de um Objeto de Armazenamento

*   **Endpoint:** `GET /api/v1/admin/storage/objects/{storage_object_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:** Lê de `sys_objects_storage`. Parseia `params` de JSON string para mapa. Mascara segredos em `params_to_edit`.

#### 4. Atualizar um Objeto de Armazenamento

*   **Endpoint:** `PUT /api/v1/admin/storage/objects/{storage_object_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Campos de `sys_objects_storage` a serem atualizados.
    *   Para `params_json`, o cliente envia o objeto JSON. O backend o converte para string.
    *   Se `key` ou `secret` nos `params_json` forem enviados como strings de placeholder (ex: `********`) o backend não os atualiza, mantendo os valores existentes no DB (que não foram expostos). Se um novo valor for fornecido, ele é atualizado.
*   **Resposta de Sucesso (200 OK):** Retorna o objeto de armazenamento atualizado (com segredos mascarados).

#### 5. Deletar um Objeto de Armazenamento

*   **Endpoint:** `DELETE /api/v1/admin/storage/objects/{storage_object_name}`
*   **Autenticação:** Requer JWT de Admin.
*   **Lógica:**
    *   Deleta de `sys_objects_storage`.
    *   **Atenção:** Isso *não* deleta a tabela de metadados de arquivos (`table_files`) nem os arquivos físicos associados. A deleção de um storage object é uma operação perigosa e a UI deve alertar fortemente sobre isso. A limpeza de arquivos e da tabela de metadados seria uma tarefa manual ou um processo separado.
*   **Resposta de Sucesso (204 No Content).**
*   **Respostas de Erro:** `409 Conflict` (se o storage object estiver em uso crítico e não puder ser deletado - lógica a definir).

#### 6. (Opcional) Sincronizar/Recalcular Uso de um Objeto de Armazenamento

*   **Endpoint:** `POST /api/v1/admin/storage/objects/{storage_object_name}/resync-usage`
*   **Autenticação:** Requer JWT de Admin.
*   **Lógica do Backend:**
    1.  Busca `storage_config`.
    2.  Executa uma query na `storage_config[\"table_files\"]` para calcular a soma total de `size` e `COUNT(*)` de todos os arquivos.
    3.  Chama `StorageRepo.update_storage_object_size_and_number` com os valores calculados (substituindo `current_size` e `current_number`).
*   **Resposta de Sucesso (200 OK):**

## Considerações:

*   **Segurança de `params`:** A API NUNCA deve retornar chaves secretas ou credenciais armazenadas em `sys_objects_storage.params` diretamente ao cliente. Ao obter detalhes, esses campos devem ser mascarados ou omitidos. Ao atualizar, se o cliente não fornecer um novo valor para um campo secreto, o valor existente no banco de dados deve ser preservado.
*   **Criação de `table_files`:** A API de criação de `sys_objects_storage` não cria a tabela SQL `table_files` referenciada. Essa tabela deve ser criada através de uma migração separada (como a `create_sys_files_table.elixir.md` ou uma específica para o novo storage object). A UI de admin deve guiar o administrador nesse processo ou verificar a existência da tabela.
*   **Testar Conexão do Engine:** Ao criar/atualizar um storage object (especialmente para engines como S3), seria útil ter uma ação \"Testar Conexão\" que tentasse uma operação simples (ex: listar buckets ou fazer um pequeno upload de teste) usando os `params` fornecidos para verificar se estão corretos antes de salvar.
*   **Deleção de Storage Object:** É uma operação muito destrutiva se os arquivos físicos não forem gerenciados. A UI deve ter múltiplas confirmações.

Esta API de gerenciamento de armazenamento permite aos administradores configurar como e onde os arquivos da plataforma \"Deeper\" são armazenados e gerenciados.