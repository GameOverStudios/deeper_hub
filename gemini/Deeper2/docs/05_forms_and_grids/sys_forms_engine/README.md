# Documentação Deeper: Motor de Formulários (`sys_forms_engine`)

Esta seção detalha a API RESTful \"Deeper\" para interagir com o sistema de formulários dinâmicos do UNA. O objetivo é permitir que um cliente remoto obtenha a definição completa de um formulário (seus campos, atributos, valores pré-definidos) para que possa renderizá-lo, e também para submeter dados de formulário ao backend para processamento.

## Tabelas Relevantes do UNA:

*   **`sys_objects_form`**: Define cada \"objeto de formulário\" (uma instância de um formulário), especificando seu módulo, título, ação de submissão (URL no UNA PHP), tabela de destino dos dados, chave primária, etc.
*   **`sys_form_inputs`**: Define cada campo de entrada individual dentro de um formulário (nome, tipo, legenda, valor padrão, se é obrigatório, validações, etc.).
*   **`sys_form_displays`**: Define diferentes \"exibições\" de um mesmo formulário (ex: formulário de criação, formulário de edição), mostrando/ocultando ou reordenando campos.
*   **`sys_form_display_inputs`**: Tabela de junção para `sys_form_displays` e `sys_form_inputs`, controlando a visibilidade e ordem dos campos em uma exibição específica.
*   **`sys_form_pre_lists`**: Define listas de valores pré-definidos (ex: lista de países, lista de categorias).
*   **`sys_form_pre_values`**: Contém os valores (chave, valor, legenda) para cada lista pré-definida.
*   **`sys_form_fields_ids`**, **`_votes`**, **`_reaction`**: Tabelas para interações (votos, reações) em campos específicos de formulários (funcionalidade mais avançada do UNA).

## Responsabilidades da API \"Deeper\":

1.  **Fornecer Definição do Formulário:**
    *   Dado o nome de um objeto de formulário e opcionalmente um nome de exibição, retornar sua estrutura completa:
        *   Atributos do formulário (da `sys_objects_form`).
        *   Lista de campos (de `sys_form_inputs`, filtrados e ordenados por `sys_form_displays` e `sys_form_display_inputs`).
        *   Para cada campo: tipo, nome, legenda, valor, atributos, se é obrigatório, informações de validação (que o cliente precisará interpretar ou que o backend validará na submissão).
        *   Para campos do tipo `select`, `radio`, `checkbox_set`, etc., fornecer os valores da lista pré-definida associada (de `sys_form_pre_values`).
2.  **Receber Submissão do Formulário:**
    *   Um endpoint para receber os dados submetidos de um formulário.
    *   O backend validará os dados.
    *   O backend executará a ação principal (geralmente `INSERT` ou `UPDATE` na tabela de destino configurada em `sys_objects_form.table`).

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas mencionadas acima.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar essas tabelas.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.Forms.FormsRepo` e suas funções para buscar definições de formulários, listas pré-definidas e para processar dados de formulário (inserir/atualizar na tabela de destino).

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful (ex: `GET /forms/{form_object_name}/definition?display={display_name}` e `POST /forms/{form_object_name}/submit`).

## Considerações Importantes:

*   **Validação de Dados:** O UNA usa `checker_func` e `db_pass` em `sys_form_inputs` para validação e processamento. A API \"Deeper\" precisará:
    *   **Opção 1 (Validação no Cliente e Backend):** A API pode retornar as regras de validação (ex: `required`, `min_length`, `regex_pattern` derivado do `checker_func`) para o cliente realizar validação prévia. O backend *sempre* revalidará na submissão.
    *   **Opção 2 (Validação Principal no Backend):** O cliente envia os dados, e o backend faz toda a validação e retorna erros detalhados por campo.
    A lógica das `checker_func` PHP precisaria ser reimplementada em Elixir ou mapeada para validadores padrão.
*   **Processamento de Dados (`db_pass`):** Funções `db_pass` no UNA (ex: `Xss`, `DateTime`, `Tags`) processam o valor do campo antes de salvar no BD. Essa lógica também precisaria ser replicada/mapeada em Elixir.
*   **Valores Pré-definidos e Internacionalização:** Os `LKey` e `LKey2` em `sys_form_pre_values` são para internacionalização. A API deve retornar os valores já traduzidos para o idioma solicitado, se possível, ou as chaves para o cliente traduzir.
*   **Tipos de Campo Complexos:** Campos como upload de arquivos, editores HTML ricos, campos de localização, etc., exigirão tratamento especial tanto na definição retornada pela API quanto na submissão.