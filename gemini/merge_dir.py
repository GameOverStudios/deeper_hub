import os
import shutil
from pathlib import Path

def find_highest_deeper_dir(base_dir):
    """Encontra o diretório Deeper com o número mais alto"""
    max_num = 0
    max_dir = None
    
    for item in os.listdir(base_dir):
        if item == "Deeper":
            if max_num == 0:  # Se encontrar um diretório chamado "Deeper" sem número
                max_dir = os.path.join(base_dir, "Deeper")
        elif item.startswith("Deeper") and item[6:].isdigit():
            num = int(item[6:])
            if num > max_num:
                max_num = num
                max_dir = os.path.join(base_dir, f"Deeper{num}")
    
    return max_dir

def copy_contents(src, dst):
    """Copia o conteúdo de src para dst sem sobrescrever arquivos existentes"""
    if not os.path.exists(dst):
        os.makedirs(dst)
    
    for item in os.listdir(src):
        src_path = os.path.join(src, item)
        dst_path = os.path.join(dst, item)
        
        if os.path.isfile(src_path):
            if not os.path.exists(dst_path):
                shutil.copy2(src_path, dst_path)
                print(f"Copiado: {src_path} -> {dst_path}")
            else:
                print(f"Arquivo já existe, pulando: {dst_path}")
        elif os.path.isdir(src_path):
            if not os.path.exists(dst_path):
                os.makedirs(dst_path)
            copy_contents(src_path, dst_path)

def generate_tree(directory, prefix=""):
    """Gera uma representação em árvore do diretório"""
    tree = []
    items = sorted(os.listdir(directory))
    for i, item in enumerate(items):
        path = os.path.join(directory, item)
        is_last = i == len(items) - 1
        tree.append(f"{prefix}{'└── ' if is_last else '├── '}{item}")
        if os.path.isdir(path):
            extension = "    " if is_last else "│   "
            tree.append(generate_tree(path, prefix + extension))
    return "\n".join(filter(None, tree))

def main():
    # Diretório base onde estão os diretórios Deeper
    base_dir = os.path.dirname(os.path.abspath(__file__))
    target_dir = os.path.join(base_dir, "Deeper")
    
    # Verificar e remover o diretório Deeper se existir
    if os.path.exists(target_dir):
        print(f"Removendo diretório existente: {target_dir}")
        shutil.rmtree(target_dir)
        print("Diretório removido com sucesso.")
    
    # Encontrar todos os diretórios Deeper* e ordená-los em ordem decrescente
    deeper_dirs = []
    for item in os.listdir(base_dir):
        item_path = os.path.join(base_dir, item)
        if os.path.isdir(item_path):
            if item == "Deeper":
                deeper_dirs.append((0, item_path))
            elif item.startswith("Deeper") and item[6:].isdigit():
                deeper_dirs.append((int(item[6:]), item_path))
    
    # Ordenar em ordem decrescente (maior número primeiro)
    deeper_dirs.sort(reverse=True, key=lambda x: x[0])
    
    if not deeper_dirs:
        print("Nenhum diretório Deeper* encontrado.")
        return
    
    print("Processando diretórios na seguinte ordem:")
    for num, path in deeper_dirs:
        print(f"Deeper{num if num > 0 else ''} -> {path}")
    
    # Criar diretório de destino
    os.makedirs(target_dir)
    print(f"\nDiretório de destino criado: {target_dir}")
    
    # Copiar conteúdo dos diretórios na ordem correta
    for num, src_dir in deeper_dirs:
        if os.path.samefile(src_dir, target_dir):
            print(f"\nPulando o próprio diretório de destino: {src_dir}")
            continue
            
        print(f"\nCopiando conteúdo de: {src_dir}")
        copy_contents(src_dir, target_dir)
    
    # Gerar e salvar a árvore de diretórios
    tree_file = os.path.join(target_dir, "index.txt")
    print(f"\nGerando árvore de diretórios em: {tree_file}")
    
    tree_content = generate_tree(target_dir)
    with open(tree_file, "w", encoding="utf-8") as f:
        f.write("Estrutura de diretórios:\n")
        f.write("=" * 30 + "\n")
        f.write(tree_content)
    
    print("\nProcesso concluído com sucesso!")

if __name__ == "__main__":
    main()