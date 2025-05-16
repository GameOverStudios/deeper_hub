project('deeper_client', 'cpp',
  version : '0.1.0',
  default_options : [
    'warning_level=3',
    'cpp_std=c++17',
    'buildtype=debugoptimized',
    'b_ndebug=if-release',
    'b_lto=true',
    'strip=true'
  ]
)

# Configurações de compilação
cpp = meson.get_compiler('cpp')

# Configuração de argumentos de compilação condicionais
if get_option('buildtype').startswith('debug')
  add_project_arguments('-DDEBUG', language: 'cpp')
  message('Build type: Debug')
else
  add_project_arguments('-DNDEBUG', language: 'cpp')
  message('Build type: Release')
endif

# Argumentos de compilação comuns
common_cpp_args = []

# Adiciona definições para Windows
if host_machine.system() == 'windows'
  common_cpp_args += ['-D_WIN32_WINNT=0x0601'] # Windows 7 ou superior
endif

# Arquivos fonte
src_files = [
  'src/main.cpp',
  'src/http_client.cpp',
  'src/websocket_client.cpp'
]

# Diretórios de inclusão
incdir = include_directories('include')

# Lista de dependências
dep_list = []

# Configuração das dependências
json_dep = dependency('nlohmann_json',
  fallback: ['nlohmann_json', 'nlohmann_json_dep'],
  required: true,
  default_options: ['default_library=static', 'tests=false']
)

# Configuração para Windows
if host_machine.system() == 'windows'
  # Bibliotecas do Windows necessárias para WinHTTP
  win_http_dep = cpp.find_library('winhttp', required: true)
  
  # Adiciona definições necessárias para o Windows
  add_project_arguments('-D_WIN32_WINNT=0x0601', language: 'cpp')  # Windows 7 ou superior
  
  # Adiciona as dependências do Windows
  windows_deps = [
    win_http_dep,
    cpp.find_library('wininet'),
    cpp.find_library('ole32'),
    cpp.find_library('oleaut32'),
    cpp.find_library('crypt32'),
    cpp.find_library('shlwapi'),
    cpp.find_library('advapi32'),
    cpp.find_library('ws2_32')
  ]
  
  # Adiciona as dependências à lista
  dep_list += [json_dep] + windows_deps
  
  message('Configuração para Windows concluída')
else
  # Configuração para outros sistemas operacionais (se necessário)
  message('Configuração concluída para ' + host_machine.system())
  dep_list += [json_dep]
endif

# Configuração do executável
executable('deeper_client',
  sources: src_files,
  include_directories: incdir,
  dependencies: dep_list,
  cpp_args: common_cpp_args,
  link_args: ['-pthread'],
  install: true,
  install_dir: 'bin'
)

# Mensagem de conclusão
message('\nConfiguração concluída. Execute "ninja -C build" para compilar.\n')