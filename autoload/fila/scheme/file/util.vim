let s:File = vital#fila#import('System.File')
let s:Trash = vital#fila#import('System.Trash')
let s:Prompt = vital#fila#import('Prompt')
let s:Revelator = vital#fila#import('App.Revelator')

function! fila#scheme#file#util#new_file(path) abort
  if filereadable(a:path) || isdirectory(a:path)
    throw s:Revelator.error(fila#lib#message#printf(
          \ '"%s" already exist',
          \ a:path,
          \))
  endif
  call s:create_parent_path_if_requested(a:path)
  call writefile([], a:path)
endfunction

function! fila#scheme#file#util#new_directory(path) abort
  if filereadable(a:path) || isdirectory(a:path)
    throw s:Revelator.error(fila#lib#message#printf(
          \ '"%s" already exist',
          \ a:path,
          \))
  endif
  call s:create_parent_path_if_requested(a:path)
  call mkdir(a:path)
endfunction

function! fila#scheme#file#util#copy(src, dst) abort
  if filereadable(a:dst) || isdirectory(a:dst)
    let r = s:select_overwrite_method(a:dst)
    if empty(r)
      throw s:Revelator.info('Cancelled')
    elseif r ==# 'r'
      let new_dst = input(
            \ printf('New name: %s -> ', a:src),
            \ a:dst,
            \ 'file',
            \)
      if empty(new_dst)
        throw s:Revelator.info('Cancelled')
      endif
      return fila#scheme#file#util#copy(a:src, new_dst)
    endif
  endif
  call s:create_parent_path_if_requested(a:dst)
  if filereadable(a:src)
    call s:File.copy(a:src, a:dst)
  else
    call s:File.copy_dir(a:src, a:dst)
  endif
endfunction

function! fila#scheme#file#util#move(src, dst) abort
  if filereadable(a:src) && !filewritable(a:src)
    throw s:Revelator.error(printf(
          \ '"%s" is not writable',
          \ a:src,
          \))
  elseif filereadable(a:dst) || isdirectory(a:dst)
    let r = s:select_overwrite_method(a:dst)
    if empty(r)
      throw s:Revelator.info('Cancelled')
    elseif r ==# 'r'
      let new_dst = input(
            \ printf('New name: %s -> ', a:src),
            \ a:dst,
            \ 'file',
            \)
      if empty(new_dst)
        throw s:Revelator.info('Cancelled')
      endif
      return fila#scheme#file#util#move(a:src, new_dst)
    endif
  endif
  call s:create_parent_path_if_requested(a:dst)
  call s:File.move(a:src, a:dst)
endfunction

function! fila#scheme#file#util#trash(path) abort
  if filereadable(a:path) && !filewritable(a:path)
    throw s:Revelator.error(printf(
          \ '"%s" is not writable',
          \ a:path,
          \))
  endif
  call s:Trash.delete(a:path)
endfunction

function! fila#scheme#file#util#remove(path) abort
  if filereadable(a:path) && !filewritable(a:path)
    throw s:Revelator.error(printf(
          \ '"%s" is not writable',
          \ a:path,
          \))
  endif
  if filereadable(a:path)
    call delete(a:path)
  else
    call s:File.rmdir(a:path, 'r')
  endif
endfunction

function! s:create_parent_path_if_requested(path) abort
  let parent_path = fnamemodify(a:path, ':p:h')
  if !isdirectory(parent_path)
    let m = printf(
          \ 'A parent directory %s does not exist. Create it? (Y[es]/no): ',
          \ parent_path,
          \)
    if !s:Prompt.confirm(m, v:true)
      throw s:Revelator.info('Cancelled')
    endif
    call mkdir(parent_path, 'p')
  endif
endfunction

function! s:select_overwrite_method(path) abort
  let prompt = join([
        \ printf(
        \   'File/Directory "%s" already exists',
        \   a:path,
        \ ),
        \ 'Please select an overwrite method (esc to cancel)',
        \ 'f[orce]/r[ename]: ',
        \], "\n")
  return s:Prompt.select(prompt, 1, 1, '[fr]')
endfunction