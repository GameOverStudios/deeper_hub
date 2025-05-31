# API de Administração: Gerenciamento de Módulos

Endpoints da API para administradores gerenciarem os módulos da plataforma \"Deeper\", análogo ao gerenciamento de módulos no UNA (tabela `sys_modules`).

**Permissões:** Todos os endpoints aqui requerem um papel de administrador do site com plenos poderes sobre a configuração e estado dos módulos da aplicação.

## Contexto dos Módulos no UNA (e Adaptação para \"Deeper\")

No UNA, `sys_modules` registra todos os módulos instalados, seus metadados (título, versão, fornecedor, caminho, URI, prefixos de classe/DB) e seu estado (`enabled`). Habilitar ou desabilitar um módulo tem implicações em todo o sistema (disponibilidade de funcionalidades, rotas, blocos de página, etc.).

Na arquitetura \"Deeper\" com Elixir:
*   A \"instalação\" de um módulo Elixir é geralmente feita adicionando a dependência e executando suas migrações.
*   A tabela `sys_modules` ainda seria útil para:
    *   Listar os \"módulos conceituais\" do UNA que foram portados ou mapeados para funcionalidades no Elixir.
    *   Controlar o estado `enabled` de certas funcionalidades, que a API \"Deeper\" e o cliente frontend podem consultar para mostrar/ocultar opções ou rotas.
    *   Armazenar metadados que podem ser úteis para a UI de administração (ex: título do módulo, descrição).
*   A habilitação/desabilitação real de código Elixir em runtime é mais complexa do que simplesmente mudar um flag no DB. Pode envolver:
    *   Flags de funcionalidade que são verificadas no código.
    *   Parada/início de `GenServers` ou processos da `Application` supervision tree (para módulos mais complexos).
    *   Reconfiguração dinâmica de rotas no Phoenix (difícil sem reiniciar).
    *   Para \"Deeper\", a API de admin para módulos provavelmente se concentrará em gerenciar o *estado registrado* e os *metadados* dos módulos, e a aplicação Elixir usaria esses flags para condicionar o comportamento. A remoção completa de um módulo Elixir ainda seria um processo de deploy/código.

## Endpoints para Módulos

### 1. Listar Todos os Módulos Registrados

*   **`GET /admin/modules`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:**
    *   `status` (string, ex: `enabled`, `disabled`, `all` - baseado no campo `enabled` e `pending_uninstall`).
    *   `type` (string, ex: `module`, `language`, `template` - do campo `type` do UNA).
    *   `vendor` (string).
    *   `q` (string): Buscar por nome ou título.
*   **Resposta de Sucesso (200 OK):** Lista de módulos.

```json
    {
      \"data\": [
        {
          \"id\": 10,
          \"type\": \"module\",
          \"name\": \"deeper_articles\", // Nome do módulo no sistema \"Deeper\"
          \"title\": \"Artigos Deeper\",
          \"vendor\": \"DeeperTeam\",
          \"version\": \"1.0.0\",
          \"path\": \"lib/deeper/content/articles\", // Caminho conceitual ou real
          \"uri\": \"articles\", // Prefixo de URI usado pela API pública
          \"class_prefix\": \"Deeper.Content.Articles\", // Namespace Elixir
          \"db_prefix\": \"deeper_articles_\", // Prefixo de tabela (se aplicável)
          \"lang_category\": \"Deeper Articles\",
          \"dependencies\": \"deeper_core,deeper_files\", // Módulos dos quais depende
          \"enabled\": 1, // 1 = enabled, 0 = disabled
          \"pending_uninstall\": 0,
          \"date_installed\": 1670000000, // Timestamp da \"instalação\" ou registro
          \"date_updated\": 1690000000 // Timestamp da última atualização de metadados/estado
        }
        // ...
      ]
    }
```

```json
    {
      \"message\": \"Módulo 'deeper_articles' habilitado com sucesso.\",
      \"data\": { /* objeto do módulo atualizado */ }
    }
```

```json
    {
      \"name\": \"deeper_new_feature\",
      \"title\": \"Nova Funcionalidade Deeper\",
      \"vendor\": \"DeeperTeam\",
      \"version\": \"1.0.0\",
      // ... outros campos de sys_modules ...
      \"run_install_hooks\": true // Flag para executar lógica de pós-registro
    }
```

### 2. Obter Detalhes de um Módulo Específico

*   **`GET /admin/modules/{module_name_or_id}`**
    *   Pode aceitar o nome único do módulo (ex: `deeper_articles`) ou seu ID numérico.
*   **Autenticação:** Admin Requerida.
*   **Resposta de Sucesso (200 OK):** Objeto do módulo (formato do item da lista acima).
*   **Respostas de Erro:** `404`.

### 3. Habilitar um Módulo

*   **`POST /admin/modules/{module_name_or_id}/enable`**
*   **Autenticação:** Admin Requerida.
*   **Ação do Backend:**
    1.  Verifica se o módulo pode ser habilitado (ex: dependências satisfeitas).
    2.  Define `sys_modules.enabled = 1`.
    3.  **Importante:** Pode precisar disparar um evento no sistema Elixir para que as partes relevantes da aplicação (ex: router, menus dinâmicos) reconheçam a mudança. Isso pode envolver:
        *   Notificar um `GenServer` central de configuração/módulos.
        *   Limpar caches relevantes.
        *   Para funcionalidades que dependem de processos, pode tentar iniciar esses processos (complexo).
    4.  Executa \"ganchos\" `on_enable` se o módulo portado tiver essa lógica (ex: registrar alertas, menus).
*   **Resposta de Sucesso (200 OK):** Objeto do módulo atualizado ou mensagem de sucesso.

*   **Respostas de Erro:** `400` (ex: dependências não atendidas), `401`, `403`, `404`, `500` (se a lógica de habilitação em runtime falhar).

### 4. Desabilitar um Módulo

*   **`POST /admin/modules/{module_name_or_id}/disable`**
*   **Autenticação:** Admin Requerida.
*   **Ação do Backend:**
    1.  Verifica se o módulo pode ser desabilitado (ex: outros módulos não dependem criticamente dele).
    2.  Define `sys_modules.enabled = 0`.
    3.  **Importante:** Dispara evento para notificar o sistema Elixir da mudança.
        *   Funcionalidades associadas devem parar de funcionar ou ser ocultadas.
        *   Processos associados podem precisar ser parados.
    4.  Executa \"ganchos\" `on_disable`.
*   **Resposta de Sucesso (200 OK):** Objeto do módulo atualizado ou mensagem de sucesso.
*   **Respostas de Erro:** `400` (ex: outros módulos dependem dele), `401`, `403`, `404`, `500`.

### 5. (Opcional) \"Instalar\" / Registrar Novo Módulo (via API)
    (Mais complexo, pois a instalação real do código Elixir é um deploy. Isto seria para registrar um módulo já deployado no DB.)

*   **`POST /admin/modules/register`**
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):** Metadados do módulo a ser registrado em `sys_modules`.

*   **Ação do Backend:**
    1.  Insere o registro em `sys_modules`.
    2.  Se `run_install_hooks` for true, tenta executar uma função de \"instalação\" do módulo Elixir (ex: `Deeper.NewFeature.Installer.on_install()`) que poderia popular configurações padrão, criar objetos de sistema (páginas, menus), etc.
*   **Resposta de Sucesso (201 Created):** Objeto do módulo registrado.

### 6. (Opcional) \"Desinstalar\" / Marcar para Desinstalação
    (Remover o registro do DB. A remoção do código é um processo de deploy.)

*   **`POST /admin/modules/{module_name_or_id}/uninstall`** (ou DELETE)
*   **Autenticação:** Admin Requerida.
*   **Ação do Backend:**
    1.  Executa \"ganchos\" `on_uninstall` do módulo (ex: remover tabelas, configurações, objetos de sistema).
    2.  Define `sys_modules.pending_uninstall = 1` ou remove o registro de `sys_modules`.
*   **Resposta de Sucesso (200 OK):** Mensagem de sucesso.

## Considerações para Repositórios e Contextos:

*   **`Deeper.SystemCore.ModulesRepo` (ou `SysModulesRepo`):**
    *   Funções CRUD para a tabela `sys_modules`.
    *   Funções para buscar módulos por status, nome, etc.
    *   Função para atualizar o campo `enabled`.
*   **`Deeper.SystemCore.Modules` (Contexto/Serviço):**
    *   Verificará permissões de admin.
    *   Orquestrará as ações de habilitar/desabilitar:
        *   Chamar o Repo para atualizar o DB.
        *   Disparar eventos internos do Elixir (ex: via `Registry` ou `Phoenix.PubSub`) para notificar outras partes da aplicação sobre a mudança de estado de um módulo.
        *   Invocar dinamicamente funções `on_enable` / `on_disable` / `on_install` / `on_uninstall` dos módulos Elixir correspondentes, se existirem (ex: usando `apply(Module, :function, args)` com base no `class_prefix` do módulo).
*   **Impacto no Resto da Aplicação Elixir:**
    *   **Roteador Phoenix:** Pode precisar de lógica para carregar rotas condicionalmente com base nos módulos habilitados em `sys_modules` durante a inicialização ou através de um mecanismo de recarga (complexo). Uma abordagem mais simples é ter todas as rotas definidas, mas os controllers verificarem o status do módulo antes de processar a requisição.
    *   **Menus e Blocos de Página:** O sistema que renderiza menus (`sys_menu_items`) e blocos de página (`sys_pages_blocks`) já deve verificar o campo `module` e se esse módulo está habilitado antes de tentar renderizar o item/bloco ou chamar seu serviço.
    *   **Flags de Funcionalidade:** O código Elixir pode usar uma função helper (ex: `Deeper.Modules.is_enabled?(\"module_name\")`) que consulta o estado em `sys_modules` (possivelmente com cache) para habilitar/desabilitar funcionalidades em runtime.

A API de gerenciamento de módulos fornece uma interface para controlar o comportamento modular da plataforma \"Deeper\" a partir de uma perspectiva administrativa, mesmo que a \"instalação\" física do código Elixir seja um passo de deploy.