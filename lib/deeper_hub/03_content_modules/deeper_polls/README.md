# Documentação Deeper: Módulo de Enquetes (`deeper_polls`)

Este módulo da API \"Deeper\" é responsável pelo gerenciamento de enquetes (pesquisas de opinião) criadas por usuários. Ele permitirá a criação de enquetes com múltiplas opções, a votação por outros usuários e a visualização dos resultados. Visa replicar funcionalidades de módulos como `bx_polls` do sistema UNA.

## Responsabilidades Principais:

*   Criação, leitura, atualização e exclusão (CRUD) de enquetes.
*   Definição da pergunta da enquete e de múltiplas opções de resposta.
*   Configurações da enquete: permitir voto único ou múltiplo, visibilidade dos resultados (imediata, após votar, após fechar), data de término.
*   Registro de votos dos usuários nas opções da enquete.
*   Cálculo e exibição dos resultados da enquete (contagem de votos e porcentagens por opção).
*   Integração com perfis de usuário (criador da enquete, votantes).
*   Controle de privacidade/visibilidade da enquete.
*   Integração com sistemas de comentários (para discutir a enquete).

## Componentes Detalhados:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite para as tabelas `deeper_polls`, `deeper_poll_options`, e `deeper_poll_votes`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar as tabelas do módulo de enquetes.

3.  [**Módulos de Acesso a Dados (`data_access_modules.md`)**](./data_access_modules.md):
    *   Descreve o módulo Elixir (ex: `Deeper.Content.PollsRepo`) que encapsula as queries SQL.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para todas as operações relacionadas a enquetes, opções e votos.

5.  [**Mapeamento da Lógica de Serviço (`service_logic_mapping.md`)**](./service_logic_mapping.md):
    *   Descreve como funcionalidades que seriam \"serviços\" no UNA (ex: \"últimas enquetes\", \"enquetes populares\") são implementadas na API.

6.  [**Objetos Associados (`associated_objects.md`)**](./associated_objects.md):
    *   Detalha como este módulo se integra com perfis de usuário e o sistema de comentários.

## Estrutura de Dados Chave (a ser detalhada em `database_schema.md`):

*   **`deeper_polls`**:
    *   `id`, `profile_id` (criador), `question` (texto da pergunta), `slug`, `description` (opcional), `allow_multiple_choices` (boolean), `results_visibility` (ex: 'always', 'after_vote', 'after_close'), `closes_at` (Unix timestamp, opcional), `status` (ex: 'open', 'closed'), `total_votes_count`, `created_at`, `updated_at`.
*   **`deeper_poll_options`**:
    *   `id`, `poll_id` (FK), `option_text`, `order_index`, `votes_count`.
*   **`deeper_poll_votes`**:
    *   `id`, `poll_id` (FK), `option_id` (FK), `profile_id` (votante), `voted_at`. (Pode ter uma chave única em `poll_id`, `profile_id`, `option_id` se `allow_multiple_choices` for falso, ou apenas em `poll_id`, `profile_id` se um usuário puder votar em apenas uma opção mas puder mudar o voto).

Este módulo permitirá aos usuários coletar opiniões e engajar a comunidade de forma interativa.