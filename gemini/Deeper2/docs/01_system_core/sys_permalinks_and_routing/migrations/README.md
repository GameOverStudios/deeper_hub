# Documentação Deeper: Migrações para Permalinks e Regras de Reescrita

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas às tabelas de Permalinks (`sys_permalinks`) e Regras de Reescrita (`sys_rewrite_rules`) do sistema UNA.

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Migrações Definidas:

1.  [**Criar Tabela `sys_permalinks` (`create_sys_permalinks_table.elixir.md`)**](./create_sys_permalinks_table.elixir.md):
    *   Cria a tabela para armazenar os mapeamentos entre URLs padrão e permalinks amigáveis.

2.  [**Criar Tabela `sys_rewrite_rules` (`create_sys_rewrite_rules_table.elixir.md`)**](./create_sys_rewrite_rules_table.elixir.md):
    *   Cria a tabela para armazenar regras de reescrita de URL baseadas em expressões regulares.

## Utilização na API \"Deeper\":

Enquanto estas tabelas são criadas para manter a estrutura de dados do UNA, sua utilização direta pela API \"Deeper\" para roteamento pode ser diferente do UNA PHP. Elas podem servir de base para um endpoint de \"resolução de caminho\" ou para informar a lógica de busca por slugs/URIs de conteúdo.