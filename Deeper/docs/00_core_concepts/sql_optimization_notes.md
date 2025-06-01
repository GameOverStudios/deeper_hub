# Documentação Deeper: Notas sobre Otimização de SQL (Manual com SQLite)

Ao trabalhar com SQL escrito manualmente, especialmente com SQLite, a otimização é uma consideração chave para garantir bom desempenho. Este documento descreve algumas estratégias e boas práticas.

## 1. Entendendo o Plano de Execução

*   **`EXPLAIN QUERY PLAN` (SQLite):** Antes de finalizar qualquer query complexa, use o comando `EXPLAIN QUERY PLAN SELECT ...;` do SQLite.
*   Isso mostrará como o SQLite pretende executar a query, incluindo:
    *   Quais tabelas são escaneadas (`SCAN TABLE`).
    *   Quais índices são usados (`SEARCH TABLE ... USING INDEX ...`).
    *   Se são usadas tabelas temporárias para ordenação ou junções.
*   O objetivo é minimizar `SCAN TABLE` em tabelas grandes e garantir que os índices apropriados sejam utilizados para `WHERE`, `JOIN` e `ORDER BY`.

## 2. Índices

*   **Crie Índices Estrategicamente:**
    *   Em colunas usadas frequentemente em cláusulas `WHERE`.
    *   Em colunas usadas em `JOIN ... ON ...`.
    *   Em colunas usadas em `ORDER BY`.
    *   Em colunas com alta cardinalidade (muitos valores distintos).
*   **Índices Compostos:** Considere índices em múltiplas colunas se as queries frequentemente filtram ou juntam por essas combinações. A ordem das colunas no índice composto é importante.
    *   Exemplo: `CREATE INDEX idx_user_status_role ON users(status, role);` é útil para `WHERE status = ? AND role = ?`.
*   **`COVERING INDEXES`:** Se um índice contém todas as colunas necessárias para uma query (tanto no `SELECT`, `WHERE`, quanto no `JOIN`), o SQLite pode satisfazer a query usando apenas o índice, sem precisar acessar a tabela principal. Isso é muito eficiente.
*   **Evite Índices Excessivos:** Muitos índices podem tornar as operações de escrita (`INSERT`, `UPDATE`, `DELETE`) mais lentas, pois os índices também precisam ser atualizados. Encontre um equilíbrio.
*   **`ANALYZE`:** Após criar índices ou popular tabelas com dados significativos, execute o comando `ANALYZE;` (ou `ANALYZE nome_tabela;`). Isso coleta estatísticas sobre a distribuição dos dados, ajudando o otimizador de queries do SQLite a fazer escolhas melhores.

## 3. Escrevendo Queries Eficientes

*   **Seja Específico nos `SELECT`s:**
    *   Evite `SELECT *` se você não precisa de todas as colunas. Selecione apenas as colunas necessárias. Isso reduz a quantidade de dados transferidos e pode permitir o uso de covering indexes.
*   **Cláusulas `WHERE`:**
    *   Garanta que as colunas nas cláusulas `WHERE` sejam indexadas, especialmente para comparações de igualdade (`=`) e range (`<`, `>`, `BETWEEN`).
    *   Funções em colunas na cláusula `WHERE` podem impedir o uso de índices (ex: `WHERE UPPER(name) = 'TEST'` não usará um índice em `name`). Se possível, aplique a função ao valor de comparação (`WHERE name = UPPER('test')` se o `name` estiver em maiúsculas, ou armazene o valor já transformado).
*   **`JOIN`s:**
    *   Use o tipo de `JOIN` correto (`INNER JOIN`, `LEFT JOIN`).
    *   Garanta que as colunas usadas nas condições `ON` sejam indexadas em ambas as tabelas.
    *   A ordem das tabelas em `JOIN`s pode, às vezes, influenciar o plano no SQLite, mas o otimizador geralmente tenta encontrar a melhor ordem.
*   **`LIKE` e Wildcards:**
    *   `LIKE '%termo'` (wildcard no início) geralmente não pode usar um índice B-tree padrão de forma eficiente.
    *   `LIKE 'termo%'` (wildcard no final) pode usar um índice se a coluna estiver indexada.
    *   Para buscas full-text complexas, considere as extensões FTS do SQLite.
*   **`IN` vs. `JOIN`:**
    *   Para um pequeno número de valores, `WHERE coluna IN (?, ?, ?)` pode ser eficiente.
    *   Para muitos valores, ou se os valores vêm de outra tabela, um `JOIN` é geralmente mais performático.
*   **Subqueries:**
    *   Subqueries correlacionadas (aquelas que referenciam colunas da query externa) podem ser lentas. Tente reescrevê-las como `JOIN`s quando possível.
    *   Subqueries não correlacionadas na cláusula `FROM` ou `JOIN` podem ser otimizadas pelo SQLite.
*   **`UNION` vs. `UNION ALL`:**
    *   `UNION` remove duplicatas, o que adiciona uma sobrecarga de processamento (geralmente uma ordenação).
    *   Se você sabe que não haverá duplicatas, ou se as duplicatas são aceitáveis, use `UNION ALL` para melhor performance.
*   **`LIMIT` e `OFFSET` para Paginação:**
    *   `LIMIT N OFFSET M` é a forma padrão de fazer paginação.
    *   Para `OFFSET`s muito grandes, a performance pode degradar, pois o SQLite ainda precisa processar (mas não retornar) as `M` linhas anteriores.
    *   Considere a paginação baseada em cursor (keyset pagination) para tabelas muito grandes e paginação profunda, onde você busca \"depois\" do último ID da página anterior (`WHERE id > last_id ORDER BY id LIMIT N`).

## 4. Transações

*   Para múltiplas operações de escrita que devem ser atômicas, use transações (`BEGIN TRANSACTION; ... COMMIT;` ou `ROLLBACK;`).
*   Para grandes volumes de `INSERT`s, envolvê-los em uma única transação pode ser significativamente mais rápido do que cada `INSERT` ser sua própria transação implícita.

## 5. Pool de Conexões (`DBConnection`)

*   Embora não seja diretamente uma otimização SQL, usar um pool de conexões gerenciado pela `DBConnection` (ou sua camada `Deeper.Core.Data.Repo`) é crucial. Ele reutiliza conexões, evitando a sobrecarga de estabelecer uma nova conexão para cada query.

## 6. Preparando Statements

*   Se você executa a mesma query SQL muitas vezes com parâmetros diferentes, \"preparar\" o statement uma vez e executá-lo múltiplas vezes pode ser mais eficiente, pois o SQLite não precisa re-parsear e re-otimizar a query a cada vez. As bibliotecas Elixir como `DBConnection` geralmente lidam com isso internamente ao usar placeholders (`?`).

Ao seguir estas diretrizes e testar regularmente com `EXPLAIN QUERY PLAN`, você poderá escrever SQL manual eficiente para o backend \"Deeper\".