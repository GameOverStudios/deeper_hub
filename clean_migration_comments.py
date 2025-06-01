import os
import glob

def clean_comments_from_migration_files(directory):
    """Remove linhas de comentário que começam com '--' de arquivos .ex em um diretório."""
    migration_files = glob.glob(os.path.join(directory, "*.ex"))
    
    if not migration_files:
        print(f"Nenhum arquivo .ex encontrado em {directory}")
        return

    print(f"Encontrados {len(migration_files)} arquivos .ex para processar.")

    for filepath in migration_files:
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            original_line_count = len(lines)
            cleaned_lines = [line for line in lines if not line.strip().startswith('-- ')]
            new_line_count = len(cleaned_lines)
            
            if new_line_count < original_line_count:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.writelines(cleaned_lines)
                print(f"Comentários removidos de: {filepath} ({original_line_count - new_line_count} linhas removidas)")
            else:
                print(f"Nenhum comentário para remover em: {filepath}")
        except Exception as e:
            print(f"Erro ao processar o arquivo {filepath}: {e}")

if __name__ == "__main__":
    migrations_directory = os.path.join("lib", "deeper_hub", "core", "data", "migrations")
    # Constrói o caminho absoluto baseado no diretório do script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    absolute_migrations_directory = os.path.join(script_dir, migrations_directory)
    
    print(f"Iniciando limpeza de comentários no diretório: {absolute_migrations_directory}")
    clean_comments_from_migration_files(absolute_migrations_directory)
    print("Limpeza de comentários concluída.")
