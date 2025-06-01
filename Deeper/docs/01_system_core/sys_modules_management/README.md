# Documentação Deeper: Gerenciamento de Módulos (`sys_modules`) - Leitura

Esta seção da API \"Deeper\" descreve como as informações sobre os módulos do sistema UNA (armazenadas principalmente na tabela `sys_modules`) podem ser acessadas. O foco inicial é na leitura dessas informações. A modificação do status dos módulos (habilitar, desabilitar, instalar, desinstalar) é uma funcionalidade complexa que se encaixa melhor na API de Administração (`07_studio_admin_api/`).

No contexto do backend \"Deeper\", entender quais módulos estão \"habilitados\" no banco de dados original do UNA pode ser útil para:

1.  **Decidir quais funcionalidades da API devem estar ativas ou disponíveis.** Se um módulo como `bx_events` está desabilitado no UNA, a API \"Deeper\" para eventos pode optar por não expor dados ou retornar um status indicando que a funcionalidade não está ativa.
2.  **Informar o cliente sobre os recursos disponíveis.**
3.  **Ajudar na lógica de carregamento de configurações ou recursos específicos de módulos.**

## Tabelas Relevantes do UNA:

*   **`sys_modules`**: Tabela principal contendo informações sobre cada módulo (nome, título, versão, caminho, URI, prefixos, status de habilitado, etc.).
*   **`sys_modules_file_tracks`**: Rastreia arquivos de módulo (mais relevante para o sistema de atualização do UNA PHP).
*   **`sys_modules_relations`**: Define relações e ações de dependência entre módulos (mais relevante para o instalador/desinstalador do UNA PHP).

## Abordagem para a API \"Deeper\" (Leitura):

*   Fornecer endpoints para listar todos os módulos e seus status.
*   Fornecer um endpoint para obter detalhes de um módulo específico pelo nome.
*   A API \"Deeper\" não executará diretamente a lógica de `on_enable`, `on_disable` de `sys_modules_relations` ao ler o status. Ela apenas reportará o status como está no banco de dados.

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define o `CREATE TABLE` statement para SQLite da tabela `sys_modules` (e opcionalmente `sys_modules_file_tracks`, `sys_modules_relations` se a leitura de alguma informação delas for útil para a API de leitura).

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar essas tabelas no banco de dados SQLite.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.SystemCore.ModulesRepo` e suas funções para ler dados da tabela `sys_modules`.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para buscar informações sobre os módulos.

## Considerações:

*   A API \"Deeper\" tratará o campo `enabled` da tabela `sys_modules` como a \"fonte da verdade\" sobre o status de um módulo, conforme registrado pelo sistema UNA original.
*   A lógica complexa de instalação/desinstalação e gerenciamento de dependências do UNA PHP não será replicada na API de leitura.