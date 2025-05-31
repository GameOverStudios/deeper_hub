# Documentação Deeper: Sistema de Votos/Avaliações Genérico

Este documento descreve a API \"Deeper\" para o sistema genérico de votos/avaliações, permitindo que os usuários atribuam uma nota (ex: 1 a 5 estrelas) a diferentes tipos de conteúdo (perfis, posts, fotos, etc.) na plataforma.

## Sistema de Votos/Avaliações no UNA:

O UNA utiliza um sistema configurável para votos/avaliações:

*   **`sys_objects_vote`**: Define \"objetos de voto\" para diferentes módulos ou tipos de conteúdo.
    *   `Name`: Nome único do sistema de votação (ex: `bx_persons_rating`, `bx_posts_stars`).
    *   `TableMain`: Tabela que armazena os dados agregados dos votos (ex: `bx_persons_votes`). Contém colunas como `object_id`, `count` (número de votos), `sum` (soma dos valores dos votos).
    *   `TableTrack`: Tabela que armazena os votos individuais dos usuários (ex: `bx_persons_votes_track`). Contém colunas como `object_id`, `author_id`, `value` (o voto dado), `date`.
    *   `MinValue`, `MaxValue`: Define o range de votação (ex: 1 a 5).
    *   `PostTimeout`: Tempo em segundos antes que um usuário possa votar novamente no mesmo item (ou 0 para votar apenas uma vez).
    *   `IsUndo`: Se o usuário pode remover/alterar seu voto.
    *   `TriggerTable`, `TriggerFieldId`, `TriggerFieldRate`, `TriggerFieldRateCount`: Para atualizar a média de avaliação (`rate`) e a contagem de votos (`votes`) no conteúdo pai (ex: em `bx_persons_data`).

*   **Tabelas de Votos:**
    *   **Tabela de Agregação (ex: `bx_persons_votes`):** `object_id`, `count`, `sum`. A média (`rate`) é calculada como `sum / count`.
    *   **Tabela de Rastreamento (ex: `bx_persons_votes_track`):** `object_id`, `author_id`, `author_nip` (IP do autor), `value`, `date`.

## Estratégia da API \"Deeper\" para Votos/Avaliações:

A API \"Deeper\" fornecerá endpoints genéricos que podem ser usados para qualquer \"objeto de voto\" configurado no UNA. A rota da API incluirá um identificador para o `voting_object_name` (que corresponde a `sys_objects_vote.Name`).

### Módulo de Acesso a Dados (`Deeper.Interactions.VotingRepo`):

Este repositório genérico operará nas tabelas `TableMain` e `TableTrack` corretas, dinamicamente.

**Desafios e Abordagem:** Similar ao `CommentsRepo`, o `VotingRepo` precisará:
1.  Obter a configuração do `sys_objects_vote` (incluindo `TableMain`, `TableTrack`, `TriggerTable`, etc.).
2.  Construir SQL dinamicamente (com segurança) para as tabelas corretas.

**Funções Principais e SQLs Esperados (Parametrizados por `table_main`, `table_track`):**

*   **`get_voting_system_config(voting_object_name :: String.t()) :: {:ok, config :: map()} | {:error, :not_found}`**
    *   Busca a configuração de `sys_objects_vote`.
    *   SQL: `SELECT * FROM sys_objects_vote WHERE Name = ? LIMIT 1;`
    *   Retorna `config` incluindo `TableMain`, `TableTrack`, `MinValue`, `MaxValue`, `TriggerTable`, `TriggerFieldId`, `TriggerFieldRate`, `TriggerFieldRateCount`.

*   **`get_rating(voting_object_name, object_id)`**
    *   Busca a configuração para obter `table_main`.
    *   SQL: `SELECT count, sum FROM #{table_main} WHERE object_id = ? LIMIT 1;`
    *   Calcula a média (`rate = sum / count`, cuidando da divisão por zero).
    *   Retorna `%{count: count, sum: sum, rate: rate}`.

*   **`get_user_vote(voting_object_name, object_id, author_profile_id)`**
    *   Busca a configuração para obter `table_track`.
    *   SQL: `SELECT value, date FROM #{table_track} WHERE object_id = ? AND author_id = ? ORDER BY date DESC LIMIT 1;`
    *   Retorna o voto do usuário ou `nil` se não votou.

*   **`submit_vote(voting_object_name, author_profile_id, author_ip_integer, params :: map())`**
    *   `params`: `object_id`, `value` (o voto).
    1.  Busca `config = get_voting_system_config(voting_object_name)`.
    2.  Valida `params.value` contra `config.MinValue` e `config.MaxValue`.
    3.  Verifica `config.PostTimeout`: Consulta `table_track` para o último voto deste `author_profile_id` no `object_id`. Se dentro do timeout, retorna erro. (Se timeout = 0 e já votou, verifica `config.IsUndo`).
    4.  **Inicia Transação.**
    5.  Se `config.IsUndo` e usuário já votou, pode precisar remover/atualizar o voto antigo em `table_track` e ajustar os valores em `table_main` (subtrair o voto antigo).
    6.  Insere/Atualiza em `table_track`:
        *   SQL (se `IsUndo` ou pode votar múltiplas vezes após timeout): `INSERT INTO #{config.TableTrack} (object_id, author_id, author_nip, value, date) VALUES (?, ?, ?, ?, ?);`
        *   SQL (se pode votar apenas uma vez e atualizar): `INSERT OR REPLACE INTO #{config.TableTrack} (object_id, author_id, author_nip, value, date) VALUES (?, ?, ?, ?, ?);` (Precisa de uma chave única em `object_id, author_id` na `table_track`).
    7.  Atualiza `table_main` (agregação):
        *   Busca o registro existente ou cria um novo.
        *   SQL: `INSERT INTO #{config.TableMain} (object_id, count, sum) VALUES (?, 1, ?) ON CONFLICT(object_id) DO UPDATE SET count = count + 1, sum = sum + ?;` (onde `?` é `params.value`).
        *   Se um voto antigo foi removido/alterado, a lógica de `sum` e `count` precisa ser ajustada.
    8.  Busca o novo `count` e `sum` de `table_main`.
    9.  Calcula `new_rate = new_sum / new_count`.
    10. Se `config.TriggerTable` estiver definido:
        *   SQL: `UPDATE #{config.TriggerTable} SET #{config.TriggerFieldRate} = ?, #{config.TriggerFieldRateCount} = ? WHERE #{config.TriggerFieldId} = ?;` (usando `new_rate`, `new_count`, `params.object_id`).
    11. **Commita Transação.**
    12. Retorna `{:ok, %{rate: new_rate, count: new_count, user_vote: params.value}}`.

### Endpoints da API (`/api/v1/ratings/{voting_object_name}`):

O `{voting_object_name}` na rota corresponde a `sys_objects_vote.Name` (ex: `bx_persons`, `bx_posts`). No UNA, o `Name` em `sys_objects_vote` é frequentemente o mesmo nome do módulo ou um identificador para o conteúdo.

*   **Obter Avaliação de um Objeto:**
    *   **Endpoint:** `GET /api/v1/ratings/{voting_object_name}/object/{object_id}`
    *   **Path Parameters:**
        *   `voting_object_name`: Ex: `bx_persons`.
        *   `object_id`: O ID do conteúdo sendo avaliado (ex: ID do perfil da pessoa).
    *   **Autenticação:** Opcional para ler, mas se o usuário estiver autenticado, a resposta pode incluir seu voto pessoal.
    *   **Resposta de Sucesso (200 OK):**

```json
        {
          \"data\": {
            \"object_id\": 123,
            \"average_rating\": 4.5, // Calculado (sum/count)
            \"total_votes\": 150,  // count
            \"current_user_vote\": 5 // Ou null se não votou ou não autenticado
          }
        }
```

```json
        {
          \"value\": 4 // O voto/nota dado pelo usuário (ex: 1 a 5)
        }
```

```json
        {
          \"data\": {
            \"object_id\": 123,
            \"average_rating\": 4.6, // Nova média
            \"total_votes\": 151,
            \"current_user_vote\": 4,
            \"message\": \"Vote registered successfully.\"
          }
        }
```

```sql
    CREATE TABLE IF NOT EXISTS sys_objects_vote (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Name TEXT NOT NULL UNIQUE, -- Nome do objeto de voto, ex: bx_persons
      Module TEXT NOT NULL,
      TableMain TEXT NOT NULL, -- Tabela de agregação, ex: bx_persons_votes
      TableTrack TEXT NOT NULL, -- Tabela de rastreamento, ex: bx_persons_votes_track
      PostTimeout INTEGER NOT NULL DEFAULT 86400, -- Em segundos
      MinValue INTEGER NOT NULL DEFAULT 1,
      MaxValue INTEGER NOT NULL DEFAULT 5,
      Pruning INTEGER NOT NULL DEFAULT 0, -- Dias para manter votos em track (0 = para sempre)
      IsUndo INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      IsOn INTEGER NOT NULL DEFAULT 1,
      TriggerTable TEXT,
      TriggerFieldId TEXT,
      TriggerFieldRate TEXT, -- Coluna para média de avaliação
      TriggerFieldRateCount TEXT, -- Coluna para contagem de votos
      ClassName TEXT,
      ClassFile TEXT
    );
```

```sql
    CREATE TABLE IF NOT EXISTS bx_persons_votes (
      object_id INTEGER PRIMARY KEY, -- FK para bx_persons_data.id
      count INTEGER NOT NULL DEFAULT 0,
      sum INTEGER NOT NULL DEFAULT 0
      -- FOREIGN KEY (object_id) REFERENCES bx_persons_data(id) ON DELETE CASCADE -- Opcional
    );
```

```sql
    CREATE TABLE IF NOT EXISTS bx_persons_votes_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL,
      author_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) do votante
      author_nip INTEGER, -- IP como inteiro
      value INTEGER NOT NULL, -- O voto (ex: 1-5)
      date INTEGER NOT NULL -- Unix Timestamp
      -- UNIQUE (object_id, author_id) -- Se um usuário só pode votar uma vez
    );
    CREATE INDEX IF NOT EXISTS idx_bx_persons_votes_track_obj_author ON bx_persons_votes_track(object_id, author_id);
```

*   **Submeter um Voto/Avaliação:**
    *   **Endpoint:** `POST /api/v1/ratings/{voting_object_name}/object/{object_id}/vote`
    *   **Autenticação:** Requer JWT.
    *   **Corpo da Requisição (JSON):**

    *   **Resposta de Sucesso (200 OK ou 201 Created):**

    *   **Respostas de Erro:** `400 Bad Request` (valor do voto inválido, fora do range MinValue/MaxValue), `401 Unauthorized`, `403 Forbidden` (ex: timeout não expirou, não pode refazer voto).

*   **(Opcional) Remover Voto (se `IsUndo = 1`):**
    *   **Endpoint:** `DELETE /api/v1/ratings/{voting_object_name}/object/{object_id}/vote`
    *   **Autenticação:** Requer JWT.
    *   **Lógica:** Remove o voto do usuário de `table_track`, ajusta `table_main` e `TriggerTable`.
    *   **Resposta de Sucesso (200 OK):** Retorna a nova avaliação.

## Tabelas de Votos (Esquema SQLite):

*   **`sys_objects_vote` (Configuração):**

*   **Exemplo de Tabela de Agregação (`bx_persons_votes`):**

*   **Exemplo de Tabela de Rastreamento (`bx_persons_votes_track`):**

    Se `IsUndo` for falso e um usuário só puder votar uma vez, o índice `UNIQUE (object_id, author_id)` é crucial. Se `IsUndo` for verdadeiro ou houver `PostTimeout`, esse índice único não se aplica, e a lógica de buscar o último voto do usuário é necessária.

## Considerações:

*   **Atomicidade:** A submissão de um voto (inserir em `table_track`, atualizar `table_main`, atualizar `TriggerTable`) deve ser uma operação atômica (transação).
*   **Cálculo da Média:** O `rate` deve ser calculado como `sum / count`, tratando a divisão por zero se `count` for 0.
*   **Permissões para Votar:** A API deve verificar se o usuário tem permissão para votar no objeto em questão (ACL do módulo pai).

Este sistema de votação genérico pode ser aplicado a diversos conteúdos, bastando configurar uma nova entrada em `sys_objects_vote` e criar as tabelas `TableMain` e `TableTrack` correspondentes (ou reutilizá-las se o design permitir).