# Migração Elixir: Criar Tabela `bx_persons_data` (Referência)

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_data` no banco de dados SQLite.

**Nota Importante:** A definição e o código desta migração já foram fornecidos em:
[`docs/01_system_core/sys_accounts_and_profiles/migrations/create_bx_persons_data_table.elixir.md`](../../01_system_core/sys_accounts_and_profiles/migrations/create_bx_persons_data_table.elixir.md)

Esta referência é incluída aqui para manter a estrutura lógica da documentação do módulo `bx_persons`. Por favor, consulte o link acima para o código e detalhes da migração.

## Resumo do Esquema `bx_persons_data`:

A tabela `bx_persons_data` armazena os dados detalhados para perfis de usuário do tipo \"pessoa\", incluindo:
*   `id` (Chave Primária, referenciada por `sys_profiles.content_id`)
*   `author`
*   Timestamps `added`, `changed`
*   Referências a `picture` e `cover` (IDs de arquivos)
*   Campos de informação pessoal: `fullname`, `description`, `gender`, `birthday`, `location`
*   Contadores de interação: `views`, `rate`, `votes`, `score`, `favorites`, `comments`, `reports`, `featured`
*   Configurações de privacidade: `allow_view_to`, `allow_post_to`, `allow_contact_to`
*   `settings` (JSON para configurações adicionais)

Certifique-se de que esta migração seja executada após a criação da tabela `sys_profiles` se houver uma chave estrangeira de `sys_profiles` para `bx_persons_data.id` (embora o link seja geralmente `sys_profiles.content_id = bx_persons_data.id`, então `bx_persons_data` pode ser criada primeiro). A ordem principal de dependência é `sys_accounts` -> `sys_profiles`.