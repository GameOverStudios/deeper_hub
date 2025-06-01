# Documentação Deeper: Mapeamento da Lógica de \"Serviço\" para API (Módulo `deeper_articles`)

No sistema UNA, os módulos PHP frequentemente expõem \"serviços\" (métodos públicos em suas classes de módulo) que são chamados pelo core para:

1.  Gerar blocos de HTML para serem exibidos em páginas (ex: \"Últimos Artigos\", \"Artigos Populares\", \"Nuvem de Categorias\").
2.  Fornecer dados para outros componentes.
3.  Realizar ações específicas.

Com a API RESTful \"Deeper\", essa lógica de \"serviço\" precisa ser mapeada para endpoints da API que retornam dados JSON, ou para funcionalidades dentro dos controllers/repositórios Elixir. O cliente da API (frontend) será então responsável por buscar esses dados e renderizar a UI apropriada.

Abaixo estão exemplos de \"serviços\" comuns de um módulo de artigos e como eles seriam mapeados:

## 1. Serviço: \"Listar Últimos N Artigos\" (para um bloco na página inicial, por exemplo)

*   **Funcionalidade UNA PHP (Exemplo Hipotético):**
    *   `BxArticlesModule->service_latest_articles(int $count = 5, bool $show_summary = true)`
    *   Retornaria HTML formatado contendo os `N` artigos mais recentes.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/articles`
    *   **Query Parameters:**
        *   `sort_by=published_at_desc` (ou `created_at_desc`)
        *   `status=published`
        *   `per_page={N}` (onde N é o número de artigos desejados, ex: `per_page=5`)
        *   `page=1`
        *   `fields=id,title,slug,excerpt,published_at,author_name,featured_image_thumbnail_url` (cliente solicita os campos necessários para a exibição concisa).
    *   **Lógica no `Deeper.Content.ArticlesRepo`:** A função `list_articles/2` lidaria com esses parâmetros.
    *   **Responsabilidade do Cliente:** O cliente busca esses dados e os renderiza em seu componente de \"Últimos Artigos\".

## 2. Serviço: \"Listar Artigos Populares\" (baseado em visualizações ou votos)

*   **Funcionalidade UNA PHP:**
    *   `BxArticlesModule->service_popular_articles(int $count = 5, string $period = \"week\")`
    *   Retornaria HTML.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/articles`
    *   **Query Parameters:**
        *   `sort_by=views_desc` (ou `votes_desc`, `score_desc` - exigiria que os contadores de votos/score fossem acessíveis ou que o `ArticlesRepo` pudesse ordenar por eles, possivelmente com subqueries ou joins com tabelas de interação).
        *   `status=published`
        *   `published_since={timestamp}` (para filtrar por período, ex: artigos publicados na última semana).
        *   `per_page={N}`
        *   `page=1`
    *   **Lógica no `Deeper.Content.ArticlesRepo`:** A função `list_articles/2` precisaria ser estendida para suportar ordenação por `views` ou por contadores de interações (o que pode envolver JOINs com tabelas de sumário de votos/scores ou cálculos dinâmicos se esses contadores não estiverem na tabela `deeper_articles`).
    *   **Responsabilidade do Cliente:** Renderizar a lista.

## 3. Serviço: \"Listar Artigos por Categoria\"

*   **Funcionalidade UNA PHP:**
    *   `BxArticlesModule->service_articles_by_category(string $category_slug, int $page = 1, int $per_page = 10)`
    *   Retornaria HTML paginado.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/articles`
    *   **Query Parameters:**
        *   `category_slug={slug_da_categoria}` (OU `category_id={id_da_categoria}`)
        *   `status=published`
        *   `page={page_num}`
        *   `per_page={items_per_page}`
        *   `sort_by=published_at_desc`
    *   **Lógica no `Deeper.Content.ArticlesRepo`:** A função `list_articles/2` já foi projetada para aceitar `category_slug` ou `category_id` como filtros.
    *   **Responsabilidade do Cliente:** Renderizar a lista e a paginação.

## 4. Serviço: \"Exibir Bloco de Categorias de Artigos\" (Nuvem de Tags ou Lista)

*   **Funcionalidade UNA PHP:**
    *   `BxArticlesModule->service_article_categories_list(string $display_type = \"list\")`
    *   Retornaria HTML de uma lista ou nuvem de categorias.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/article-categories`
    *   **Query Parameters:**
        *   `include_article_count=true` (parâmetro customizado para a API, se necessário)
        *   `sort_by=name_asc` (ou `article_count_desc` se o contador for incluído)
    *   **Lógica no `Deeper.Content.ArticleCategoriesRepo`:** A função `list_categories/1` poderia ser estendida para, opcionalmente, fazer um `JOIN` com `deeper_articles_to_categories` e `deeper_articles` (com status `published`) para contar o número de artigos em cada categoria.

```json
        {
          \"data\": [
            {\"id\": 1, \"name\": \"Programação\", \"slug\": \"programacao\", \"article_count\": 25},
            {\"id\": 5, \"name\": \"Elixir\", \"slug\": \"elixir\", \"article_count\": 10}
          ]
        }
```

```json
        {
          \"data\": [
            {\"month_year\": \"2023-10\", \"article_count\": 5, \"archive_link\": \"/articles?published_month=2023-10\"},
            {\"month_year\": \"2023-09\", \"article_count\": 12, \"archive_link\": \"/articles?published_month=2023-09\"}
          ]
        }
```

```sql
        UPDATE deeper_articles SET views = views + 1 WHERE id = ?;
```

```elixir
        # Exemplo de SQL no ArticleCategoriesRepo para incluir contagem
        # SELECT c.*, COUNT(atc.article_id) as article_count
        # FROM deeper_article_categories c
        # LEFT JOIN deeper_articles_to_categories atc ON c.id = atc.category_id
        # LEFT JOIN deeper_articles a ON atc.article_id = a.id AND a.status = 'published' -- Importante filtrar por status aqui
        # GROUP BY c.id, c.name, c.slug ...
        # ORDER BY c.name;
```

```elixir
        # Exemplo de SQL no ArticlesRepo (SQLite)
        # SELECT STRFTIME('%Y-%m', published_at, 'unixepoch') as month_year, COUNT(id) as article_count
        # FROM deeper_articles
        # WHERE status = 'published' AND published_at IS NOT NULL
        # GROUP BY month_year
        # ORDER BY month_year DESC;
```

    *   **Resposta da API:**

    *   **Responsabilidade do Cliente:** Receber a lista de categorias (com contagens, se solicitado) e renderizar como uma lista, nuvem de tags, etc.

## 5. Serviço: \"Exibir Arquivo de Artigos\" (por mês/ano)

*   **Funcionalidade UNA PHP:**
    *   `BxArticlesModule->service_articles_archive_list()`
    *   Retornaria HTML com links para arquivos mensais (ex: \"Outubro 2023 (5)\").

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/articles/archive-summary` (Endpoint customizado)
    *   **Lógica no `Deeper.Content.ArticlesRepo`:** Uma nova função seria necessária para agrupar artigos por ano/mês e contar.

    *   **Resposta da API:**

    *   **Cliente usaria `GET /api/v1/articles?published_month=YYYY-MM` para listar os artigos de um mês específico.**
        *   O `ArticlesRepo.list_articles/2` precisaria de um novo filtro para `published_month`.

## 6. Serviço: \"Gerar Slug Único\"

*   **Funcionalidade UNA PHP:** Lógica interna ao criar/editar um post para garantir que o slug seja único.
*   **Mapeamento para API \"Deeper\":**
    *   **Não um endpoint direto.** Esta é uma lógica de negócios.
    *   Pode ser uma função helper no Elixir (`Slugger.generate_unique_slug(title, existing_slugs_query_function)`).
    *   O controller da API, ao receber um `POST` ou `PUT /articles`, chamaria essa função antes de passar os dados para `ArticlesRepo.create_article/1` ou `ArticlesRepo.update_article/2`.
    *   Se o cliente fornecer um slug, o backend deve validá-lo para unicidade. Se não fornecer, o backend o gera.

## 7. Serviço: \"Incrementar Contagem de Visualizações\"

*   **Funcionalidade UNA PHP:** Lógica chamada quando uma página de artigo é visualizada.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `POST /api/v1/articles/{id_or_slug}/view` (Endpoint específico para registrar uma visualização).
    *   **Autenticação:** Opcional, mas pode ser útil para evitar abuso (ex: limitar uma view por IP/usuário por período).
    *   **Lógica no `Deeper.Content.ArticlesRepo`:** Uma função `increment_view_count(article_id)` que executa:

    *   **Responsabilidade do Cliente:** Chamar este endpoint quando um artigo é carregado/visualizado.
    *   **Alternativa:** O sistema UNA principal (`sys_objects_view` e sua tabela de rastreamento) poderia ser usado. A API poderia ter um endpoint genérico `POST /api/v1/views/{object_name}/{object_id}` que interage com o `ViewsRepo`.

## Considerações Gerais:

*   **Estado vs. Dados:** A API REST se concentra em expor o estado dos recursos (os dados). A lógica de apresentação (como renderizar uma \"nuvem de tags\") é transferida para o cliente.
*   **Granularidade dos Endpoints:** Em vez de serviços que retornam HTML complexo, a API \"Deeper\" fornecerá endpoints de dados mais granulares, permitindo que o cliente componha a UI.
*   **Eficiência:** Consultas no `ArticlesRepo` (e outros repos) devem ser otimizadas, especialmente para serviços como \"artigos populares\" ou contagens agregadas. O uso de `EXPLAIN QUERY PLAN` será vital.
*   **Caching:** O cliente pode cachear respostas da API. O backend também pode implementar caching para queries frequentes.
*   **Parâmetro `include`:** O uso de um parâmetro `include` nos endpoints `GET /articles` e `GET /articles/{id}` (como `?include=author,categories`) pode ajudar a reduzir o número de chamadas de API necessárias pelo cliente, similar ao que o GraphQL oferece, mas de forma mais simples. Isso exigiria que os Repos construíssem `JOIN`s dinamicamente.

Este mapeamento demonstra como a funcionalidade orientada a \"serviços de UI\" do UNA pode ser transformada em uma API de dados, dando mais flexibilidade e responsabilidade ao cliente.