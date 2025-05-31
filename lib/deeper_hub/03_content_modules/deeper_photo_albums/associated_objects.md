# Documentação Deeper: Objetos Associados ao Módulo de Álbuns de Fotos

Este documento descreve como o módulo de Álbuns de Fotos (`deeper_photo_albums`) se integra com outros sistemas e objetos genéricos do \"Deeper\", como perfis de usuário, o sistema de gerenciamento de arquivos, e os sistemas de interação (comentários, votos, etc.).

O módulo `deeper_photo_albums` gerencia as entidades de álbuns e as fotos (como referências a arquivos) dentro deles. As interações e o armazenamento real dos arquivos são tratados por sistemas dedicados.

## 1. Perfis de Usuário (Criadores e Uploaders)

*   **Sistema de Referência:** `📂 01_system_core/sys_accounts_and_profiles/`
*   **Tabelas Envolvidas:**
    *   `deeper_photo_albums`: Contém `profile_id` (criador do álbum).
    *   `deeper_album_photos`: Contém `profile_id` (quem fez o upload da foto específica, que pode ser diferente do criador do álbum).
*   **Integração:**
    *   Ao criar álbuns ou adicionar fotos, o `profile_id` do usuário autenticado (via JWT) é associado.
    *   Ao listar ou visualizar álbuns/fotos, a API frequentemente fará `JOIN` com `sys_profiles` (e `sys_accounts`) para incluir detalhes do criador/uploader se solicitado pelo parâmetro `include`.

## 2. Gerenciamento de Arquivos (Imagens Reais)

*   **Sistema de Referência:** `📂 06_file_management/`
*   **Tabelas Envolvidas:**
    *   `deeper_album_photos`: Contém `file_id` (FK crucial para `deeper_files.id`).
    *   `deeper_files`: Armazena os metadados do arquivo de imagem real (localização no storage, tipo MIME, tamanho, dimensões, etc.).
*   **Fluxo:**
    1.  **Upload:** O usuário faz upload de um arquivo de imagem através dos endpoints do sistema de gerenciamento de arquivos (ex: `POST /api/v1/files/upload`). Este sistema salva o arquivo e cria um registro em `deeper_files`, retornando o `file_id`.
    2.  **Associação:** Ao adicionar uma foto a um álbum (`POST /api/v1/photo-albums/{album_id}/photos`), o cliente envia o `file_id` obtido no passo anterior. O `PhotoAlbumsRepo` cria uma entrada em `deeper_album_photos` ligando o álbum ao `file_id`.
    3.  **Recuperação:** Para exibir uma foto, a API (`GET /album-photos/{id}` ou ao listar fotos) usará o `file_id` para buscar os detalhes do arquivo em `deeper_files` (incluindo `remote_id` e `storage_object`) e construir a URL de acesso à imagem (ex: `/api/v1/files/view/{storage_object}/{remote_id}`).
*   **Capa do Álbum:** A coluna `cover_photo_id` em `deeper_photo_albums` referencia um `deeper_album_photos.id`, que por sua vez tem um `file_id`.

## 3. Comentários

Comentários podem ser aplicados a álbuns inteiros e/ou a fotos individuais.

*   **A. Comentários em Álbuns:**
    *   **Sistema de Referência:** `📂 04_interaction_systems/sys_comments_system/`
    *   **Configuração:** `sys_objects_cmts` teria uma entrada para \"deeper_photo_albums_comments\".
        *   `Name`: \"deeper_photo_albums\"
        *   `TriggerTable`: \"deeper_photo_albums\"
        *   `TriggerFieldId`: \"id\"
    *   **Endpoints da API:**
        *   `GET /api/v1/comments?system_object=deeper_photo_albums&object_id={album_id}`
        *   `POST /api/v1/comments` (com `system_object=\"deeper_photo_albums\"`, `object_id={album_id}`)

*   **B. Comentários em Fotos Individuais (dentro de álbuns):**
    *   **Sistema de Referência:** `📂 04_interaction_systems/sys_comments_system/`
    *   **Configuração:** `sys_objects_cmts` teria uma entrada para \"deeper_album_photos_comments\".
        *   `Name`: \"deeper_album_photos\"
        *   `TriggerTable`: \"deeper_album_photos\"
        *   `TriggerFieldId`: \"id\"
    *   **Endpoints da API:**
        *   `GET /api/v1/comments?system_object=deeper_album_photos&object_id={album_photo_id}`
        *   `POST /api/v1/comments` (com `system_object=\"deeper_album_photos\"`, `object_id={album_photo_id}`)

## 4. Votos / Reações

Similar aos comentários, votos/reações podem ser aplicados a álbuns e/ou fotos.

*   **A. Votos/Reações em Álbuns:**
    *   **Sistema de Referência:** `sys_voting_system/` ou `sys_reactions_system/`
    *   **Configuração:** `sys_objects_vote` (ou `_reaction`) para \"deeper_photo_albums_votes\".
    *   **Endpoints da API:**
        *   `GET /api/v1/votes/summary?object_name=deeper_photo_albums_votes&object_id={album_id}`
        *   `POST /api/v1/votes` (com `object_name=\"deeper_photo_albums_votes\"`, `object_id={album_id}`)

*   **B. Votos/Reações em Fotos Individuais:**
    *   **Sistema de Referência:** `sys_voting_system/` ou `sys_reactions_system/`
    *   **Configuração:** `sys_objects_vote` (ou `_reaction`) para \"deeper_album_photos_votes\".
    *   **Endpoints da API:**
        *   `GET /api/v1/votes/summary?object_name=deeper_album_photos_votes&object_id={album_photo_id}`
        *   `POST /api/v1/votes` (com `object_name=\"deeper_album_photos_votes\"`, `object_id={album_photo_id}`)

## 5. Favoritos (para Álbuns e/ou Fotos)

*   **Sistema de Referência:** `📂 04_interaction_systems/sys_favorites_system/`
*   **Configuração:**
    *   Para Álbuns: `sys_objects_favorite` para \"deeper_photo_albums_favorites\".
    *   Para Fotos: `sys_objects_favorite` para \"deeper_album_photos_favorites\".
*   **Endpoints da API (Exemplo para Álbuns):**
    *   `GET /api/v1/favorites/status?object_name=deeper_photo_albums_favorites&object_id={album_id}`
    *   `POST /api/v1/favorites` (com `object_name=\"deeper_photo_albums_favorites\"`, `object_id={album_id}`)

## 6. Visualizações (Views - para Álbuns e/ou Fotos)

*   **Sistema de Referência:** Pode ser um sistema de visualizações genérico (`sys_objects_view` do UNA) ou contadores simples nas tabelas `deeper_photo_albums` e `deeper_album_photos`.
*   **Tabelas Envolvidas (se contadores simples):**
    *   `deeper_photo_albums`: Contém `views_count` (para o álbum).
    *   `deeper_album_photos`: Contém `views_count` (para a foto individual).
*   **Registro de Visualização:**
    *   `POST /api/v1/photo-albums/{album_id}/view`: Incrementaria `deeper_photo_albums.views_count`.
    *   `POST /api/v1/album-photos/{album_photo_id}/view`: Incrementaria `deeper_album_photos.views_count`.
*   **Lógica:** No `PhotoAlbumsRepo`, funções como `increment_album_view_count(album_id)` e `increment_album_photo_view_count(album_photo_id)`.

## 7. Denúncias (Reporting - para Álbuns ou Fotos)

*   **Sistema de Referência:** `📂 04_interaction_systems/sys_reporting_system/`
*   **Configuração:**
    *   Para Álbuns: `sys_objects_report` para \"deeper_photo_albums_reports\".
    *   Para Fotos: `sys_objects_report` para \"deeper_album_photos_reports\".
*   **Endpoints da API:** `POST /api/v1/reports` com `object_name` e `object_id` apropriados.

## 8. Tags/Categorias para Fotos/Álbuns (Opcional/Avançado)

*   Se fotos ou álbuns puderem ser tagueados ou categorizados de forma mais granular (além da estrutura de álbuns em si):
    *   Seriam necessárias tabelas adicionais (`deeper_photo_tags`, `deeper_album_tags`, e tabelas de junção).
    *   A lógica seria similar à categorização de artigos ou eventos.

## Considerações:

*   **Nomenclatura de Objetos:** A consistência nos nomes dos objetos (ex: \"deeper_photo_albums\", \"deeper_album_photos\") é vital para a configuração e uso dos sistemas genéricos de interação.
*   **Granularidade das Interações:** Decidir se as interações (comentários, votos) acontecem no nível do álbum, no nível da foto individual, ou em ambos, afeta o design da UI e a configuração dos sistemas de interação. Ambas as abordagens são comuns.
*   **Performance:** Para álbuns com muitas fotos, retornar todas as interações (comentários, votos) para cada foto em uma listagem de álbum seria inviável. As APIs de listagem devem focar nos dados principais, e os detalhes das interações de itens individuais devem ser carregados sob demanda ou com `include` explícito.

A integração com estes sistemas associados transforma o módulo de álbuns de um simples repositório de imagens em uma experiência de compartilhamento de mídia social e interativa.