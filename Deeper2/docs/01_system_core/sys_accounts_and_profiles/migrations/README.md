# Documentação Deeper: Migrações para Contas e Perfis

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao gerenciamento de Contas de Usuário e Perfis no sistema \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Migrações Definidas:

1.  [**Criar Tabela `sys_accounts` (`create_sys_accounts_table.elixir.md`)**](./create_sys_accounts_table.elixir.md):
    *   Responsável por criar a tabela `sys_accounts` para armazenar informações de login e dados básicos da conta.

2.  [**Criar Tabela `sys_profiles` (`create_sys_profiles_table.elixir.md`)**](./create_sys_profiles_table.elixir.md):
    *   Responsável por criar a tabela `sys_profiles` que liga uma conta (`sys_accounts`) a diferentes tipos de perfis de conteúdo (ex: um perfil de pessoa, um perfil de organização).

3.  [**Criar Tabela `bx_persons_data` (`create_bx_persons_data_table.elixir.md`)**](./create_bx_persons_data_table.elixir.md):
    *   Responsável por criar a tabela `bx_persons_data` para armazenar os dados detalhados de perfis do tipo \"pessoa\".

*(Outras migrações para tabelas relacionadas a perfis, como `bx_persons_pictures` ou tabelas de configurações de privacidade específicas, podem ser adicionadas aqui conforme necessário).*

## Executando Migrações

A execução das migrações será gerenciada por uma tarefa Mix customizada ou um script que invoca as funções `up/0` de cada módulo de migração na ordem correta. Detalhes sobre este processo de execução serão definidos no `README.md` raiz do projeto ou em uma seção específica sobre o gerenciamento de migrações.