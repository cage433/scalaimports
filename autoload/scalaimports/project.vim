let s:this_script_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let g:known_scala_imports = {}

function! scalaimports#project#extend_known_imports(dict)
  call extend(g:known_scala_imports, a:dict)
endfunction

function! scalaimports#project#build_imports_map(imports_file)
  let imports_map = {}
  for line in readfile(a:imports_file)
    let [class, packages] = split(line, " ")
    let packages_list = split(packages, ",")
    let imports_map[class] = packages_list + get(imports_map, class, [])
  endfor
  return imports_map
endfunction

function! scalaimports#project#rebuild_imports_map(purge_package_file)
  if a:purge_package_file
    silent exec ":! rm -rf .maker.vim/external_packages/"
    silent exec ":! rm -rf .maker.vim/project_packages/"
    redraw!
  endif
  let s:scala_imports_map = {}
  echo "Rebuilding package file"
  exec ":! ruby ".s:this_script_dir."/scala-imports.rb" 
  redraw!
  let s:external_imports_map = scalaimports#project#build_imports_map('.maker.vim/external_packages/by_class')
  let s:source_imports_map = scalaimports#project#build_imports_map('.maker.vim/project_packages/by_class')
  let s:scala_imports_map = deepcopy(s:external_imports_map)
  for [class, packages] in items(s:source_imports_map)
    let s:scala_imports_map[class] = get(s:external_imports_map, class, []) + packages
  endfor
  :redraw!
endfunction

function! scalaimports#project#build_imports_map_if_necessary()
  if !exists('s:scala_imports_map')
    call scalaimports#project#rebuild_imports_map(0)
  endif
endfunction

function!scalaimports#project#known_import_or_lookup(klass, dict)
  if has_key(g:known_scala_imports, a:klass)
    return [ get(g:known_scala_imports, a:klass) ]
  else
    return get(a:dict, a:klass, [])
  endif
endfunction

function! scalaimports#project#packages_for_class(klass)
  call scalaimports#project#build_imports_map_if_necessary()
  return scalaimports#project#known_import_or_lookup(a:klass, s:scala_imports_map)
endfunction

function! scalaimports#project#source_packages_for_class(klass)
  call scalaimports#project#build_imports_map_if_necessary()
  return scalaimports#project#known_import_or_lookup(a:klass, s:source_imports_map)
endfunction

