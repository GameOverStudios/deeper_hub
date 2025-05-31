# Documentação Deeper: Internacionalização e Localização (`sys_localization_*`)

Este documento descreve como a API \"Deeper\" fornecerá acesso aos dados de internacionalização (i18n) e localização (l10n) do sistema UNA, permitindo que o cliente remoto renderize a interface em múltiplos idiomas.

**Objetivo Principal:** Permitir que o cliente obtenha listas de idiomas disponíveis e as strings traduzidas para chaves específicas, no idioma selecionado pelo usuário ou detectado.

**Nota:** Esta seção foca em *ler* os dados de localização. A API para *gerenciar* idiomas e traduções (adicionar novos idiomas, editar strings) será parte da \"API do Studio/Admin\" (`07_studio_admin_api/`).

## Tabelas Relevantes do UNA (e sua adaptação para \"Deeper\"):

1.  **`sys_localization_languages`**:
    *   Define os idiomas disponíveis no sistema.
    *   Campos: `ID`, `Name` (código do idioma, ex: `en`, `pt-BR`), `Flag` (código do país para ícone de bandeira, ex: `gb`, `br`), `Title` (nome do idioma, ex: `English`, `Português (Brasil)`), `Direction` (`LTR` ou `RTL`), `LanguageCountry` (ex: `en-GB`, `pt-BR`), `Enabled` (se o idioma está ativo).

2.  **`sys_localization_categories`**:
    *   Categoriza as chaves de tradução para organização (ex: \"Geral\", \"Contas\", \"Módulo X\").
    *   Campos: `ID`, `Name`.

3.  **`sys_localization_keys`**:
    *   Armazena as chaves únicas para as strings de texto que precisam ser traduzidas.
    *   Campos: `ID`, `IDCategory` (FK para `sys_localization_categories.id`), `Key` (a string da chave, ex: `_sys_txt_welcome`, `_bx_persons_txt_profile_page_title`).

4.  **`sys_localization_strings`**:
    *   Armazena as traduções efetivas para cada chave em cada idioma.
    *   Campos: `IDKey` (FK para `sys_localization_keys.ID`), `IDLanguage` (FK para `sys_localization_languages.ID`), `String` (o texto traduzido).

## Estratégia da API \"Deeper\" para Localização:

A API \"Deeper\" fornecerá endpoints para:
*   Listar os idiomas habilitados.
*   Obter todas as strings traduzidas para um idioma específico (para o cliente cachear).
*   (Opcional) Obter a tradução de uma chave específica em um idioma específico (menos eficiente para o cliente).

### Módulo de Acesso a Dados (`Deeper.SystemCore.LocalizationRepo`):

Um módulo como `Deeper.SystemCore.LocalizationRepo` encapsulará as queries SQL.

**Funções Principais e SQLs Esperados:**

*   **`list_enabled_languages() :: {:ok, list(map())} | {:error, any()}`**
    *   Busca todos os idiomas marcados como `Enabled = 1` (ou 'yes').
    *   SQL: `SELECT ID, Name, Title, Flag, Direction, LanguageCountry FROM sys_localization_languages WHERE Enabled = 1;` (ou o valor booleano correspondente).
    *   Retorna uma lista de mapas, cada mapa representando um idioma.

*   **`get_strings_for_language(language_code :: String.t()) :: {:ok, map_of_strings :: map()} | {:error, :not_found | any()}`**
    *   Busca todas as chaves e suas traduções para um determinado código de idioma (ex: \"en\", \"pt-BR\").
    *   SQL:

```json
        {
          \"data\": [
            {
              \"id\": 1,
              \"code\": \"en\", // sys_localization_languages.Name
              \"title\": \"English\",
              \"flag\": \"gb\",
              \"direction\": \"LTR\",
              \"system_code\": \"en-GB\" // sys_localization_languages.LanguageCountry
            },
            {
              \"id\": 2,
              \"code\": \"pt-BR\",
              \"title\": \"Português (Brasil)\",
              \"flag\": \"br\",
              \"direction\": \"LTR\",
              \"system_code\": \"pt-BR\"
            }
            // ... outros idiomas habilitados ...
          ]
        }
```

```json
        {
          \"data\": {
            // Chave: String Traduzida
            \"_sys_txt_welcome\": \"Welcome\",
            \"_sys_txt_username\": \"Username\",
            \"_bx_persons_txt_profile\": \"Profile\",
            \"_submit\": \"Submit\",
            \"_cancel\": \"Cancel\"
            // ... todas as outras chaves e traduções para o idioma ...
          },
          \"language_info\": { // Opcional: informações sobre o idioma solicitado
            \"code\": \"en\",
            \"title\": \"English\"
          }
        }
```

```json
        {
          \"data\": {
            \"key\": \"_sys_txt_welcome\",
            \"value\": \"Welcome\",
            \"language_code\": \"en\"
          }
        }
```

```sql
        SELECT k.\"Key\", s.String
        FROM sys_localization_strings s
        JOIN sys_localization_keys k ON s.IDKey = k.ID
        JOIN sys_localization_languages l ON s.IDLanguage = l.ID
        WHERE l.Name = ?;
```

```sql
        SELECT s.String
        FROM sys_localization_strings s
        JOIN sys_localization_keys k ON s.IDKey = k.ID
        JOIN sys_localization_languages l ON s.IDLanguage = l.ID
        WHERE l.Name = ? AND k.\"Key\" = ?
        LIMIT 1;
```

```sql
CREATE TABLE IF NOT EXISTS sys_localization_languages (
  ID INTEGER PRIMARY KEY AUTOINCREMENT,
  Name TEXT NOT NULL UNIQUE, -- 'en', 'pt-BR'
  Flag TEXT NOT NULL, -- 'gb', 'br'
  Title TEXT NOT NULL, -- 'English', 'Português (Brasil)'
  Direction TEXT NOT NULL DEFAULT 'LTR' CHECK(Direction IN ('LTR', 'RTL')),
  LanguageCountry TEXT NOT NULL UNIQUE, -- 'en-GB', 'pt-BR'
  Enabled INTEGER NOT NULL DEFAULT 0 -- 0 para false, 1 para true
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_localization_keys (
  ID INTEGER PRIMARY KEY AUTOINCREMENT,
  IDCategory INTEGER NOT NULL, -- FK para sys_localization_categories.ID
  \"Key\" TEXT NOT NULL UNIQUE, -- A chave da string, ex: '_sys_txt_welcome'. Aspas em \"Key\" para evitar conflito.
  FOREIGN KEY (IDCategory) REFERENCES sys_localization_categories(ID)
);
CREATE INDEX IF NOT EXISTS idx_sys_localization_keys_key ON sys_localization_keys(\"Key\");
```

```sql
CREATE TABLE IF NOT EXISTS sys_localization_strings (
  IDKey INTEGER NOT NULL, -- FK para sys_localization_keys.ID
  IDLanguage INTEGER NOT NULL, -- FK para sys_localization_languages.ID
  String TEXT NOT NULL,
  PRIMARY KEY (IDKey, IDLanguage),
  FOREIGN KEY (IDKey) REFERENCES sys_localization_keys(ID) ON DELETE CASCADE,
  FOREIGN KEY (IDLanguage) REFERENCES sys_localization_languages(ID) ON DELETE CASCADE
);
```

    *   Retorna um mapa onde as chaves são as `sys_localization_keys.Key` e os valores são as `sys_localization_strings.String`. Ex: `%{ \"_sys_txt_welcome\" => \"Welcome\", \"_submit\" => \"Submit\" }`.

*   **`get_string(language_code :: String.t(), key_string :: String.t()) :: {:ok, translated_string :: String.t()} | {:error, :not_found | any()}`** (Opcional, para casos específicos)
    *   Busca a tradução de uma única chave em um idioma.
    *   SQL:

### Endpoints da API (`/api/v1/system/localization`):

*   **Listar Idiomas Habilitados:**
    *   **Endpoint:** `GET /api/v1/system/localization/languages`
    *   **Descrição:** Retorna uma lista de todos os idiomas habilitados no sistema.
    *   **Autenticação:** Não requerida (informação pública).
    *   **Resposta de Sucesso (200 OK):**

*   **Obter Todas as Strings para um Idioma:**
    *   **Endpoint:** `GET /api/v1/system/localization/strings/{language_code}`
    *   **Path Parameter:** `language_code` (ex: \"en\", \"pt-BR\").
    *   **Descrição:** Retorna um objeto JSON contendo todas as chaves de tradução e suas strings correspondentes para o idioma especificado. Ideal para o cliente carregar e cachear no início da sessão.
    *   **Autenticação:** Não requerida.
    *   **Resposta de Sucesso (200 OK):**

    *   **Respostas de Erro:** `404 Not Found` (se o `language_code` não existir ou não estiver habilitado).

*   **(Opcional) Obter String Específica:**
    *   **Endpoint:** `GET /api/v1/system/localization/string/{language_code}/{key_string}`
    *   **Path Parameters:** `language_code`, `key_string` (ex: \"_sys_txt_welcome\").
    *   **Descrição:** Retorna a tradução de uma única chave. Menos eficiente para o cliente se muitas chaves forem necessárias.
    *   **Autenticação:** Não requerida.
    *   **Resposta de Sucesso (200 OK):**

    *   **Respostas de Erro:** `404 Not Found`.

## Tabelas de Localização (Esquema SQLite):

Os `CREATE TABLE` statements para `sys_localization_languages`, `sys_localization_categories`, `sys_localization_keys`, e `sys_localization_strings` precisarão ser definidos no `docs/00_core_concepts/database_schema_sqlite.md` e ter suas respectivas migrações Elixir.

**Exemplo `sys_localization_languages` (SQLite):**

**Exemplo `sys_localization_keys` (SQLite):**

**Exemplo `sys_localization_strings` (SQLite):**

*(A tabela `sys_localization_categories` é mais simples: `ID INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL UNIQUE`)*.

## Considerações para o Cliente:

*   O cliente deve primeiro chamar `GET /api/v1/system/localization/languages` para saber quais idiomas estão disponíveis.
*   Em seguida, pode chamar `GET /api/v1/system/localization/strings/{language_code}` para o idioma selecionado (ou um idioma padrão) e armazenar todas as strings localmente (ex: em memória, localStorage).
*   Uma biblioteca i18n no lado do cliente (ex: `i18next` para JavaScript) pode então usar este conjunto de strings para exibir o texto traduzido.
*   O cliente precisará de um mecanismo para permitir que o usuário altere o idioma, o que resultaria em uma nova chamada para buscar as strings do novo idioma.

Com esta API de localização, o cliente \"Deeper\" poderá suportar uma interface multilíngue de forma eficaz.