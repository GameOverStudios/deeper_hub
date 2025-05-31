# Documentação Deeper: Migrações para Permalinks e Roteamento

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao Sistema de Permalinks (`sys_permalinks`) do UNA.

## Migrações Definidas:

1.  [**Criar Tabela `sys_permalinks` (`create_sys_permalinks_table.elixir.md`)**](./create_sys_permalinks_table.elixir.md):
    *   Cria a tabela `sys_permalinks`, que armazena os mapeamentos entre URLs \"standard\" (com query parameters) e URLs amigáveis (permalinks).

2.  **(Opcional) Criar Tabela `sys_rewrite_rules` (`create_sys_rewrite_rules_table.elixir.md`)**:
    *   A tabela `sys_rewrite_rules` no UNA é mais para reescritas de URL no nível do servidor web (Apache/Nginx). Para a API \"Deeper\", o foco é em como `sys_permalinks` ajuda a resolver um caminho para um objeto de página e parâmetros. A migração para `sys_rewrite_rules` pode ser incluída por completude do esquema, mas seu uso direto pela API \"Deeper\" pode ser limitado.

## Ordem e Dependências:

*   Estas tabelas são geralmente independentes de outras tabelas core em termos de chaves estrangeiras diretas, mas a lógica que as utiliza dependerá da existência de `sys_objects_page`.