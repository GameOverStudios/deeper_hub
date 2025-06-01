# Documentação Deeper: Sistema de Votos/Avaliações Genérico

Esta seção detalha a API RESTful \"Deeper\" para interagir com o sistema de votos/avaliações genérico do UNA. Este sistema permite que usuários atribuam um valor numérico (ex: avaliação de 1 a 5 estrelas) a diferentes tipos de conteúdo (perfis, posts, etc.) que foram configurados para suportar votação.

## Tabelas Relevantes do UNA:

*   **`sys_objects_vote`**: Tabela de configuração principal. Cada entrada define um \"objeto de voto\" para um tipo de conteúdo. Especifica:
    *   `Name`: Nome único do objeto de voto (ex: `bx_persons_ratings`, `bx_posts_reviews`). Usado na API.
    *   `Module`: Módulo associado.
    *   `TableMain`: Nome da tabela SQL que armazena o sumário dos votos (contagem, soma total). Ex: `bx_persons_votes`.
    *   `TableTrack`: Nome da tabela SQL que armazena cada voto individual. Ex: `bx_persons_votes_track`.
    *   `PostTimeout`: Tempo (em segundos) antes que um usuário possa votar novamente no mesmo item (se permitido).
    *   `MinValue`, `MaxValue`: Valores mínimo e máximo permitidos para um voto.
    *   `IsUndo`: Se o usuário pode remover/alterar seu voto.
    *   `IsOn`: Se este sistema de votação está ativo.
    *   `TriggerTable`, `TriggerFieldId`, `TriggerFieldRate`, `TriggerFieldRateCount`: Configurações para atualizar a tabela de conteúdo principal com a média da avaliação e a contagem de votos.
*   **Tabela de Sumário de Votos (especificada em `sys_objects_vote.TableMain`)**:
    *   Geralmente contém colunas como `object_id` (ID do item votado), `count` (número de votos), `sum` (soma de todos os valores de votos).
*   **Tabela de Rastreamento de Votos (especificada em `sys_objects_vote.TableTrack`)**:
    *   Geralmente contém colunas como `object_id`, `author_id` (quem votou), `author_nip` (IP), `value` (o voto dado), `date`.

## Responsabilidades da API \"Deeper\":

*   Obter a avaliação média e a contagem de votos para um item de conteúdo.
*   Permitir que usuários submetam/alterem seus votos.
*   Listar quem votou em um item (se a privacidade permitir).

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite da tabela `sys_objects_vote` e exemplos de tabelas `TableMain` (sumário) e `TableTrack` (rastreamento).

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar essas tabelas.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.InteractionSystems.VotingRepo` e suas funções para ler e registrar votos, usando dinamicamente os nomes das tabelas configuradas em `sys_objects_vote`.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful (ex: `GET /ratings/{object_vote_name}/item/{item_id}`).

## Fluxo Típico:

1.  O cliente precisa exibir a avaliação de um item de conteúdo (ex: perfil com `id=456`).
2.  O cliente sabe que o objeto de voto para perfis é, por exemplo, `bx_persons_ratings`.
3.  O cliente chama `GET /api/v1/ratings/object/bx_persons_ratings/item/456`.
4.  A API \"Deeper\":
    a.  Usa o `VotingRepo` para buscar a configuração de `bx_persons_ratings` em `sys_objects_vote`.
    b.  Descobre os nomes das tabelas `TableMain` (ex: `bx_persons_votes`) e `TableTrack` (ex: `bx_persons_votes_track`).
    c.  O `VotingRepo` consulta a `TableMain` para obter `count` e `sum` para o `item_id=456`. Calcula a média.
    d.  (Opcional) Consulta a `TableTrack` para ver se o usuário logado já votou e qual foi seu voto.
5.  A API retorna a avaliação média, contagem e o voto do usuário (se houver).
6.  Para votar, o cliente envia `POST /api/v1/ratings/object/bx_persons_ratings/item/456` com `{\"value\": 4}`. O `VotingRepo` insere/atualiza na `TableTrack`, recalcula e atualiza a `TableMain`, e atualiza os campos `TriggerFieldRate` e `TriggerFieldRateCount` na `TriggerTable` (ex: `bx_persons_data`).