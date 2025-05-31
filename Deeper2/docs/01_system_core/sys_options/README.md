# Documentação Deeper: Configurações do Sistema (`sys_options`)

Este módulo da API \"Deeper\" é responsável por fornecer acesso às configurações globais e de módulos do sistema UNA, que são armazenadas principalmente na tabela `sys_options` e suas tabelas relacionadas (`sys_options_categories`, `sys_options_types`, `sys_options_mixes`).

O objetivo principal é permitir que o cliente (e o próprio backend \"Deeper\") leia essas configurações para adaptar o comportamento e a aparência da aplicação. A modificação das opções será, em geral, uma funcionalidade da API de Administração (`07_studio_admin_api/`).

## Tabelas Relevantes do UNA:

*   **`sys_options`**: Armazena cada opção individual, seu valor, tipo, categoria, etc.
*   **`sys_options_categories`**: Agrupa opções em categorias (ex: \"Geral\", \"Segurança\", \"Módulo X\").
*   **`sys_options_types`**: Define tipos de categorias de opções para organização no painel de admin do UNA (ex: \"Sistema\", \"Módulos\").
*   **`sys_options_mixes`**: (Avançado) Permite \"mixes\" de configurações, como temas que alteram um conjunto de opções visuais. O suporte inicial da API pode ser apenas de leitura ou focado nas opções ativas.
*   **`sys_options_mixes2options`**: Tabela de junção para `sys_options_mixes`.

## Responsabilidades da API (Leitura Inicial):

*   Fornecer endpoints para buscar valores de opções específicas pelo nome.
*   Fornecer endpoints para buscar todas as opções de uma determinada categoria.
*   Fornecer um endpoint para buscar todas as opções (com cautela, pode ser grande).
*   Considerar como lidar com `sys_options_mixes` para o tema ativo.

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas `sys_options`, `sys_options_categories`, `sys_options_types`, `sys_options_mixes`, e `sys_options_mixes2options`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar as tabelas de opções no banco de dados SQLite.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.SystemCore.OptionsRepo` e suas funções para ler dados das tabelas de opções.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para buscar as configurações.

## Considerações Importantes:

*   **Tipos de Valores:** A coluna `sys_options.value` armazena valores como `TEXT`. A API precisará, idealmente, converter esses valores para tipos Elixir apropriados (inteiro, booleano, string) com base na coluna `sys_options.type` (`digit`, `checkbox`, `text`, etc.) ao retornar para o cliente.
*   **Caching:** As opções do sistema geralmente não mudam com frequência. Implementar caching (no lado do servidor Elixir ou instruindo o cliente a cachear) para os valores das opções pode melhorar significativamente a performance.
*   **Opções por Módulo:** Muitas opções são prefixadas com o nome do módulo (ex: `bx_persons_option_xyz`). A API pode oferecer uma forma de buscar opções por \"escopo\" ou módulo.
*   **Mixes de Tema Ativo:** O UNA usa `sys_options_mixes` para temas. A API precisará de uma lógica para determinar o \"mix\" ativo (geralmente há uma opção em `sys_options` que define o nome do mix de tema ativo) e então buscar os valores sobrescritos por esse mix a partir de `sys_options_mixes2options`. Isso pode ser complexo. Uma abordagem inicial pode ser ignorar os mixes e retornar apenas os valores base de `sys_options`, ou ter um endpoint específico para \"configurações de tema efetivas\".