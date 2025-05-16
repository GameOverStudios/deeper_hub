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
common_cpp_args = [
  '-DWEBSOCKETPP_STRICT_MASKING',
  '-DASIO_STANDALONE',
  '-DASIO_HAS_STD_ADDRESSOF',
  '-DASIO_HAS_STD_ARRAY',
  '-DASIO_HAS_CSTDINT',
  '-DASIO_HAS_STD_SHARED_PTR',
  '-DASIO_HAS_STD_TYPE_TRAITS',
  '-DASIO_HAS_VARIADIC_TEMPLATES',
  '-DASIO_HAS_STD_FUNCTION',
  '-DASIO_HAS_STD_CHRONO'
]

# Arquivos fonte
src_files = [
  'src/main.cpp'
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

websocketpp_dep = dependency('websocketpp',
  fallback: ['websocketpp', 'websocketpp_dep'],
  required: true,
  default_options: [
    'tests=false',
    'examples=false',
    'boost_program_options=disabled'
  ]
)

# Adiciona as dependências à lista
dep_list += [json_dep, websocketpp_dep]

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