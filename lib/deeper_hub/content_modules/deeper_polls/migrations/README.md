# Documentação Deeper: Migrações para Módulo de Enquetes

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao módulo de Enquetes (`deeper_polls`) no sistema \"Deeper\".

## Migrações Definidas:

1.  [**Criar Tabela `deeper_polls` (`create_deeper_polls_table.elixir.md`)**](./create_deeper_polls_table.elixir.md):
    *   Cria a tabela principal `deeper_polls` para armazenar os detalhes das enquetes.

2.  [**Criar Tabela `deeper_poll_options` (`create_deeper_poll_options_table.elixir.md`)**](./create_deeper_poll_options_table.elixir.md):
    *   Cria a tabela `deeper_poll_options` para armazenar as opções de resposta para cada enquete.

3.  [**Criar Tabela `deeper_poll_votes` (`create_deeper_poll_votes_table.elixir.md`)**](./create_deeper_poll_votes_table.elixir.md):
    *   Cria a tabela `deeper_poll_votes` para registrar os votos dos usuários nas opções das enquetes.

A ordem de execução destas migrações deve ser: `deeper_polls` primeiro, depois `deeper_poll_options`, e por último `deeper_poll_votes`, para satisfazer as dependências de chaves estrangeiras.