# Documentação Deeper: Detalhes Internos do Core

Este diretório contém documentação sobre os componentes de baixo nível e mecanismos internos do backend \"Deeper\" que são cruciais para seu funcionamento, mas não são diretamente expostos como funcionalidades de API para o cliente final.

Compreender estes componentes é essencial para desenvolvedores que trabalham na manutenção e expansão do backend.

## Seções Detalhadas:

1.  [**`Deeper.Core.Data.Repo` - Repositório de Dados (`deeper_core_data_repo_details.md`)**](./deeper_core_data_repo_details.md):
    *   Descreve a implementação e o uso do módulo `Deeper.Core.Data.Repo`.
    *   Como ele gerencia conexões com o banco de dados SQLite usando `DBConnection`.
    *   Como as queries SQL são executadas.
    *   Estratégias para mapeamento de resultados de queries para structs ou mapas Elixir.
    *   Gerenciamento de transações.

2.  [**Executor de Migrações (`migrations_runner_details.md`)**](./migrations_runner_details.md):
    *   Explica o mecanismo ou tarefa Mix customizada (`mix deeper.migrate`, `mix deeper.rollback`) para descobrir, aplicar e reverter migrações de esquema.
    *   Como a ordem das migrações é gerenciada.
    *   Como o versionamento do esquema é rastreado (provavelmente usando uma tabela como `schema_migrations`).

Estes documentos visam fornecer clareza sobre a infraestrutura de dados do \"Deeper\".