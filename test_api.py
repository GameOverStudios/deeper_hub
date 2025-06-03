import requests
import json
import time

BASE_URL = "http://localhost:4000"

def test_categories_list():
    """Testa a listagem de categorias"""
    print("\n=== Testando listagem de categorias ===")
    response = requests.get(f"{BASE_URL}/api/bx_ads_categories_types")
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")

def create_category(name, title, display_add, display_edit, display_view):
    """Cria uma nova categoria"""
    print(f"\n=== Criando categoria: {title} ===")
    data = {
        "name": name,
        "title": title,
        "display_add": display_add,
        "display_edit": display_edit,
        "display_view": display_view
    }
    response = requests.post(
        f"{BASE_URL}/api/bx_ads_categories_types",
        json=data,
        headers={"Content-Type": "application/json"}
    )
    print(f"Status: {response.status_code}")
    
    if response.status_code == 201:
        print(f"Categoria criada com sucesso!")
        print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.json().get("data", {}).get("id")
    else:
        print(f"Erro ao criar categoria: {response.text}")
        return None

def get_category(category_id):
    """Obtém uma categoria pelo ID"""
    print(f"\n=== Obtendo categoria com ID: {category_id} ===")
    response = requests.get(f"{BASE_URL}/api/bx_ads_categories_types/{category_id}")
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")

def update_category(category_id, title):
    """Atualiza uma categoria"""
    print(f"\n=== Atualizando categoria com ID: {category_id} ===")
    data = {"title": title}
    response = requests.put(
        f"{BASE_URL}/api/bx_ads_categories_types/{category_id}",
        json=data,
        headers={"Content-Type": "application/json"}
    )
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")

def delete_category(category_id):
    """Remove uma categoria"""
    print(f"Removendo categoria {category_id}... ", end="")
    response = requests.delete(f"{BASE_URL}/api/bx_ads_categories_types/{category_id}")
    if response.status_code == 204:
        print("OK")
    else:
        print(f"ERRO ({response.status_code})")
    return response.status_code == 204

def batch_delete_categories(category_ids):
    """Remove várias categorias em lote"""
    if not category_ids:
        return True
        
    print("\n--- Removendo categorias em lote ---")
    batch_delete = {
        "operations": [
            {
                "action": "delete",
                "id": category_id
            } for category_id in category_ids
        ]
    }
    
    response = requests.post(
        f"{BASE_URL}/api/bx_ads_categories_types/batch",
        json=batch_delete,
        headers={"Content-Type": "application/json"}
    )
    success = response.status_code == 200
    print(f"Remoção em lote: {'OK' if success else 'ERRO'} ({len(category_ids)} categorias)")
    return success

def search_categories(search_term=None, filters=None, page=None, page_size=None, order_by=None, order_direction=None, fields=None):
    """Busca categorias com filtros avançados, paginação e ordenação"""
    print(f"\n=== Buscando categorias com filtros avançados ===")
    
    # Configura os filtros
    if filters is None:
        filters = {}
    if search_term:
        filters["name"] = search_term
    
    # Configura os parâmetros de paginação e ordenação
    data = {"filters": filters}
    if page is not None:
        data["page"] = page
    if page_size is not None:
        data["page_size"] = page_size
    if order_by is not None:
        data["order_by"] = order_by
    if order_direction is not None:
        data["order_direction"] = order_direction
    if fields is not None:
        data["fields"] = fields
    
    print(f"Dados da requisição: {json.dumps(data, indent=2, ensure_ascii=False)}")
    
    response = requests.post(
        f"{BASE_URL}/api/bx_ads_categories_types/search",
        json=data,
        headers={"Content-Type": "application/json"}
    )
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    return response.json() if response.status_code == 200 else None

def test_pagination():
    """Testa a paginação de categorias"""
    print("\n=== Testando paginação de categorias ===")
    
    # Cria várias categorias para testar paginação usando operações em lote
    batch_data = {
        "operations": [
            {
                "action": "create",
                "data": {
                    "name": f"categoria{i}",
                    "title": f"Categoria {i}",
                    "display_add": f"Adicionar Categoria {i}",
                    "display_edit": f"Editar Categoria {i}",
                    "display_view": f"Visualizar Categoria {i}"
                }
            } for i in range(1, 11)
        ]
    }
    
    print("\n--- Criando categorias em lote para teste de paginação ---")
    response = requests.post(
        f"{BASE_URL}/api/bx_ads_categories_types/batch",
        json=batch_data,
        headers={"Content-Type": "application/json"}
    )
    
    category_ids = []
    if response.status_code == 200:
        results = response.json().get("data", {}).get("results", [])
        category_ids = [item.get("id") for item in results if item.get("success") and item.get("id")]
    
    # Testa paginação com diferentes tamanhos de página
    print("\n--- Testando página 1 com 3 itens por página ---")
    response = requests.get(f"{BASE_URL}/api/bx_ads_categories_types?page=1&page_size=3")
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    
    print("\n--- Testando página 2 com 3 itens por página ---")
    response = requests.get(f"{BASE_URL}/api/bx_ads_categories_types?page=2&page_size=3")
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    
    # Limpa as categorias criadas
    for category_id in category_ids:
        delete_category(category_id)
    
    return category_ids

def test_ordering():
    """Testa a ordenação de categorias"""
    print("\n=== Testando ordenação de categorias ===")
    
    # Cria categorias para testar ordenação usando operações em lote
    categories = [
        ("categoria_z", "Z Categoria"),
        ("categoria_a", "A Categoria"),
        ("categoria_m", "M Categoria")
    ]
    
    batch_data = {
        "operations": [
            {
                "action": "create",
                "data": {
                    "name": name,
                    "title": title,
                    "display_add": f"Adicionar {title}",
                    "display_edit": f"Editar {title}",
                    "display_view": f"Visualizar {title}"
                }
            } for name, title in categories
        ]
    }
    
    print("\n--- Criando categorias em lote para teste de ordenação ---")
    response = requests.post(
        f"{BASE_URL}/api/bx_ads_categories_types/batch",
        json=batch_data,
        headers={"Content-Type": "application/json"}
    )
    
    category_ids = []
    if response.status_code == 200:
        results = response.json().get("data", {}).get("results", [])
        category_ids = [item.get("id") for item in results if item.get("success") and item.get("id")]
    
    # Testa ordenação por nome (ascendente)
    print("\n--- Testando ordenação por nome (ascendente) ---")
    response = requests.get(f"{BASE_URL}/api/bx_ads_categories_types?order_by=name&order_direction=asc")
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    
    # Testa ordenação por título (descendente)
    print("\n--- Testando ordenação por título (descendente) ---")
    response = requests.get(f"{BASE_URL}/api/bx_ads_categories_types?order_by=title&order_direction=desc")
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    
    # Testa ordenação por múltiplos campos
    print("\n--- Testando ordenação por múltiplos campos ---")
    response = requests.get(f"{BASE_URL}/api/bx_ads_categories_types?order_by=name,title")
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    
    # Limpa as categorias criadas
    for category_id in category_ids:
        delete_category(category_id)
    
    return category_ids

def test_field_selection():
    """Testa a seleção de campos específicos"""
    print("\n=== Testando seleção de campos ===")
    
    # Cria uma categoria para teste
    category_id = create_category(
        "test_fields",
        "Teste de Campos",
        "Adicionar Teste",
        "Editar Teste",
        "Visualizar Teste"
    )
    
    if category_id:
        # Testa seleção de apenas alguns campos
        print("\n--- Testando seleção apenas dos campos id e name ---")
        response = requests.get(f"{BASE_URL}/api/bx_ads_categories_types/{category_id}?fields=id,name")
        print(f"Status: {response.status_code}")
        print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        
        # Testa seleção de outros campos
        print("\n--- Testando seleção apenas dos campos id, title e display_add ---")
        response = requests.get(f"{BASE_URL}/api/bx_ads_categories_types/{category_id}?fields=id,title,display_add")
        print(f"Status: {response.status_code}")
        print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        
        # Limpa a categoria criada
        delete_category(category_id)
    
    return category_id

def test_batch_operations():
    """Testa operações em lote"""
    print("\n=== Testando operações em lote ===")
    
    # Prepara dados para operações em lote
    batch_data = {
        "operations": [
            {
                "operation": "create",
                "data": {
                    "name": "batch_create_1",
                    "title": "Batch Create 1",
                    "display_add": "Adicionar BC1",
                    "display_edit": "Editar BC1",
                    "display_view": "Visualizar BC1"
                }
            },
            {
                "operation": "create",
                "data": {
                    "name": "batch_create_2",
                    "title": "Batch Create 2",
                    "display_add": "Adicionar BC2",
                    "display_edit": "Editar BC2",
                    "display_view": "Visualizar BC2"
                }
            }
        ]
    }
    
    # Executa operação em lote (criação)
    print("\n--- Executando operação em lote (criação) ---")
    response = requests.post(
        f"{BASE_URL}/api/bx_ads_categories_types/batch",
        json=batch_data,
        headers={"Content-Type": "application/json"}
    )
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    
    # Extrai IDs das categorias criadas
    created_ids = []
    if response.status_code == 200:
        for result in response.json().get("results", []):
            if result.get("status") == "success" and result.get("operation") == "create":
                created_ids.append(result.get("data", {}).get("id"))
    
    # Prepara operações de atualização e remoção
    if created_ids:
        update_batch_data = {
            "operations": [
                {
                    "operation": "update",
                    "id": created_ids[0],
                    "data": {
                        "title": "Batch Updated 1"
                    }
                }
            ]
        }
        
        # Se temos pelo menos dois IDs, adiciona uma operação de remoção
        if len(created_ids) > 1:
            update_batch_data["operations"].append({
                "operation": "delete",
                "id": created_ids[1]
            })
        
        # Executa operação em lote (atualização/remoção)
        print("\n--- Executando operação em lote (atualização/remoção) ---")
        response = requests.post(
            f"{BASE_URL}/api/bx_ads_categories_types/batch",
            json=update_batch_data,
            headers={"Content-Type": "application/json"}
        )
        print(f"Status: {response.status_code}")
        print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        
        # Limpa as categorias restantes
        for category_id in created_ids:
            # Verifica se a categoria ainda existe antes de tentar remover
            check_response = requests.get(f"{BASE_URL}/api/bx_ads_categories_types/{category_id}")
            if check_response.status_code == 200:
                delete_category(category_id)
    
    return created_ids

def test_advanced_search():
    """Testa busca avançada com filtros complexos"""
    print("\n=== Testando busca avançada com filtros complexos ===")
    
    # Cria categorias para teste
    categories = [
        ("categoria_teste_1", "Teste Avançado 1", "Sim"),
        ("categoria_teste_2", "Teste Avançado 2", "Não"),
        ("outra_categoria", "Outra Categoria", "Sim")
    ]
    
    category_ids = []
    for name, title, display_add in categories:
        category_id = create_category(
            name,
            title,
            display_add,
            f"Editar {title}",
            f"Visualizar {title}"
        )
        if category_id:
            category_ids.append(category_id)
    
    # Testa busca com filtro simples
    print("\n--- Testando busca com filtro simples ---")
    search_categories(search_term="teste")
    
    # Testa busca com filtros complexos
    print("\n--- Testando busca com filtros complexos ---")
    search_categories(filters={"name": "categoria", "display_add": "Sim"})
    
    # Testa busca com paginação
    print("\n--- Testando busca com paginação ---")
    search_categories(filters={"name": "categoria"}, page=1, page_size=1)
    
    # Testa busca com ordenação
    print("\n--- Testando busca com ordenação ---")
    search_categories(filters={"name": "categoria"}, order_by="title", order_direction="desc")
    
    # Testa busca com seleção de campos
    print("\n--- Testando busca com seleção de campos ---")
    search_categories(filters={"name": "categoria"}, fields="id,name,title")
    
    # Limpa as categorias criadas
    for category_id in category_ids:
        delete_category(category_id)
    
    return category_ids

def run_full_test():
    """Executa um teste completo da API"""
    print("Iniciando teste completo da API...")
    
    # Testa operações CRUD básicas
    test_categories_list()
    
    # Cria categorias de teste
    category1_id = create_category(
        "promocao", 
        "Promoção", 
        "Adicionar Promoção", 
        "Editar Promoção", 
        "Visualizar Promoção"
    )
    
    category2_id = create_category(
        "destaque", 
        "Destaque", 
        "Adicionar Destaque", 
        "Editar Destaque", 
        "Visualizar Destaque"
    )
    
    # Não precisamos mais de pausa aqui
    # A API deve responder imediatamente
    
    # Lista categorias após criação
    test_categories_list()
    
    # Obtém categorias específicas
    if category1_id:
        get_category(category1_id)
        update_category(category1_id, "Promoção Especial")
        get_category(category1_id)
    
    if category2_id:
        get_category(category2_id)
    
    # Busca categorias
    search_categories(search_term="promo")
    
    # Testa funcionalidades avançadas
    test_pagination()
    test_ordering()
    test_field_selection()
    test_batch_operations()
    test_advanced_search()
    
    # Remove categorias iniciais
    if category1_id:
        delete_category(category1_id)
    
    if category2_id:
        delete_category(category2_id)
    
    # Lista categorias após remoção
    test_categories_list()
    
    print("\nTeste completo finalizado!")

def run_pagination_test():
    """Executa apenas o teste de paginação"""
    test_pagination()

def run_ordering_test():
    """Executa apenas o teste de ordenação"""
    test_ordering()

def run_field_selection_test():
    """Executa apenas o teste de seleção de campos"""
    test_field_selection()

def run_batch_operations_test():
    """Executa apenas o teste de operações em lote"""
    test_batch_operations()

def run_advanced_search_test():
    """Executa apenas o teste de busca avançada"""
    test_advanced_search()

if __name__ == "__main__":
    import sys
    
    # Verifica se há argumentos de linha de comando
    if len(sys.argv) > 1:
        test_type = sys.argv[1].lower()
        
        if test_type == "pagination":
            run_pagination_test()
        elif test_type == "ordering":
            run_ordering_test()
        elif test_type == "fields":
            run_field_selection_test()
        elif test_type == "batch":
            run_batch_operations_test()
        elif test_type == "search":
            run_advanced_search_test()
        else:
            print(f"Teste desconhecido: {test_type}")
            print("Testes disponíveis: pagination, ordering, fields, batch, search")
    else:
        # Sem argumentos, executa o teste completo
        run_full_test()
