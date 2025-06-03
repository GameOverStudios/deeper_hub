import requests
import json
import time

BASE_URL = "http://localhost:4000"

def test_root_endpoint():
    """Testa o endpoint raiz da API"""
    print("\n=== Testando endpoint raiz ===")
    response = requests.get(f"{BASE_URL}/")
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")

def test_status_endpoint():
    """Testa o endpoint de status"""
    print("\n=== Testando endpoint de status ===")
    response = requests.get(f"{BASE_URL}/api/status")
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")

def test_info_endpoint():
    """Testa o endpoint de informações do servidor"""
    print("\n=== Testando endpoint de informações ===")
    response = requests.get(f"{BASE_URL}/api/info")
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")

def test_routes_endpoint():
    """Testa o endpoint de rotas"""
    print("\n=== Testando endpoint de rotas ===")
    response = requests.get(f"{BASE_URL}/api/routes")
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")

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
    print(f"\n=== Removendo categoria com ID: {category_id} ===")
    response = requests.delete(f"{BASE_URL}/api/bx_ads_categories_types/{category_id}")
    print(f"Status: {response.status_code}")
    if response.status_code == 204:
        print("Categoria removida com sucesso!")
    else:
        print(f"Resposta: {response.text}")

def search_categories(search_term):
    """Busca categorias pelo nome"""
    print(f"\n=== Buscando categorias com termo: {search_term} ===")
    data = {"filters": {"name": search_term}}
    response = requests.post(
        f"{BASE_URL}/api/bx_ads_categories_types/search",
        json=data,
        headers={"Content-Type": "application/json"}
    )
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")

def run_full_test():
    """Executa um teste completo da API"""
    print("Iniciando teste completo da API...")
    
    # Testa endpoints básicos
    test_root_endpoint()
    test_status_endpoint()
    test_info_endpoint()
    test_routes_endpoint()
    
    # Testa operações CRUD em categorias
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
    
    # Pausa para garantir que as categorias foram criadas
    time.sleep(1)
    
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
    search_categories("promo")
    
    # Remove categorias
    if category1_id:
        delete_category(category1_id)
    
    if category2_id:
        delete_category(category2_id)
    
    # Lista categorias após remoção
    test_categories_list()
    
    print("\nTeste completo finalizado!")

if __name__ == "__main__":
    run_full_test()
