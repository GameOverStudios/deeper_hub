# Documentação Deeper: Módulo de Acesso a Dados para Localização (`Deeper.SystemCore.LocalizationRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemCore.LocalizationRepo`. Sua responsabilidade é interagir com as tabelas de localização (`sys_localization_languages`, `sys_localization_keys`, `sys_localization_strings`) para fornecer listas de idiomas e traduções para a API \"Deeper\".

## Responsabilidades Principais:

*   Listar todos os idiomas habilitados no sistema.
*   Buscar todas as strings traduzidas para um idioma específico.
*   Buscar a tradução de uma chave específica em um idioma específico.

## Funções Públicas Principais e Lógica SQL:

*   **`list_enabled_languages() :: {:ok, languages :: list(map())} | {:error, any()}`**
    *   Busca todos os idiomas marcados como `Enabled = 1`.
    *   SQL: `SELECT ID, Name, Title, Flag, Direction, LanguageCountry FROM sys_localization_languages WHERE Enabled = 1 ORDER BY Title;`
    *   Mapeia o resultado para uma lista de mapas, ex: `%{id: 1, code: \"en\", title: \"English\", ...}`.

*   **`get_all_strings_for_lang_code(lang_code :: String.t()) :: {:ok, translations_map :: map()} | {:error, :not_found | any()}`**
    *   Busca o `IDLanguage` para o `lang_code` dado de `sys_localization_languages`. Se não encontrado, `{:error, :language_not_found}`.
    *   Busca todas as chaves e suas traduções para o `IDLanguage`.
    *   SQL:

```sql
        SELECT k.\"Key\", s.String
        FROM sys_localization_strings s
        JOIN sys_localization_keys k ON s.IDKey = k.ID
        WHERE s.IDLanguage = ?; -- ? é o IDLanguage obtido
```

    *   Retorna um mapa onde as chaves são as `sys_localization_keys.Key` e os valores são as `sys_localization_strings.String`.
        *   Ex: `%{ \"_sys_txt_welcome\" => \"Welcome\", \"_submit\" => \"Submit\" }`
    *   Este resultado é ideal para ser cacheado (ex: por um Agente ou ETS, com o `lang_code` como chave do cache).

*   **`get_string(lang_code :: String.t(), key_string :: String.t(), default_value :: String.t() \\\\ nil) :: {:ok, translated_string :: String.t()} | {:error, :not_found | any()}`**
    *   Busca a tradução de uma única `key_string` para um `lang_code`.
    *   (Opcional) Pode usar `get_all_strings_for_lang_code/1` internamente e buscar no mapa cacheado.
    *   Ou, para uma busca direta no DB (menos eficiente se chamado muitas vezes):
        1.  Busca `IDLanguage` para `lang_code`.
        2.  Busca `IDKey` para `key_string`.
        3.  SQL: `SELECT String FROM sys_localization_strings WHERE IDKey = ? AND IDLanguage = ? LIMIT 1;`
    *   Se a tradução não for encontrada, retorna `{:ok, default_value || key_string}` ou `{:error, :string_not_found}`.

## Considerações de Cache:

*   **Lista de Idiomas:** Pode ser cacheada, pois muda raramente.
*   **Traduções por Idioma (`get_all_strings_for_lang_code/1`):** Definitivamente deve ser cacheada. Ao iniciar a aplicação, ou na primeira vez que um idioma é solicitado, todas as suas strings podem ser carregadas do DB e armazenadas em um Agente, ETS, ou `PersistentStorage`. As requisições subsequentes para traduções nesse idioma leriam do cache.
    *   Uma estratégia de invalidação de cache seria necessária se as traduções puderem ser atualizadas em tempo de execução (ex: através da API de Admin).

Este `LocalizationRepo` permitirá que a API \"Deeper\" e, por sua vez, o cliente, suportem interfaces multilíngues.