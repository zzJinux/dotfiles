" let g:drafts_root = '/custom/path'
let g:drafts_save_interval_secs = 10
" let g:drafts_retention_secs = 7 * 24 * 60 * 60
" let g:drafts_manage_updatetime = 1   " set to 0 to NOT touch 'updatetime'

" plugin/drafts.vim
" Self-cleaning drafts for Vim: scratch-only autosave + daily cleanup (max(atime, mtime))
if exists('g:loaded_drafts_plugin') | finish | endif
let g:loaded_drafts_plugin = 1
scriptencoding utf-8

" ------------------------- Config (override in vimrc before load) -------------------------
if !exists('g:drafts_root')
  if empty($XDG_STATE_HOME)
    let g:drafts_root = expand('~/.local/state/vim/drafts')
  else
    let g:drafts_root = $XDG_STATE_HOME . '/vim/drafts'
  endif
endif
if !exists('g:drafts_save_interval_secs')
  let g:drafts_save_interval_secs = 30
endif
if !exists('g:drafts_retention_secs')
  let g:drafts_retention_secs = 7 * 24 * 60 * 60
endif
if !exists('g:drafts_manage_updatetime')
  let g:drafts_manage_updatetime = 1
endif
let s:daily_stamp = g:drafts_root . '/.last_cleanup'

" ------------------------- Timer state (Option A: visible-only autosave) -------------------------
let s:drafts_timer = -1
let s:drafts_poll_ms = 1000  " timer tick cadence (ms)

function! s:mark_changed() abort
  let b:drafts_last_change = reltimefloat(reltime())
endfunction

function! s:update_visible_buf(bnr) abort
  let winid = bufwinid(a:bnr)
  if winid == -1
    return 0
  endif
  call win_execute(winid, 'silent! noautocmd update')
  return 1
endfunction

function! s:timer_tick(_id) abort
  let now = reltimefloat(reltime())
  let root = resolve(fnamemodify(g:drafts_root, ':p'))
  let root_slash = root =~# '/$' ? root : root . '/'

  for b in range(1, bufnr('$'))
    if !buflisted(b) || !bufloaded(b) | continue | endif

    let modifiable = getbufvar(b, '&modifiable')
    let modified   = getbufvar(b, '&modified')
    let buftype    = getbufvar(b, '&buftype')
    if !(modifiable && modified && buftype ==# '') | continue | endif

    let name = bufname(b)
    if empty(name) | continue | endif
    let abs  = resolve(fnamemodify(name, ':p'))
    if stridx(abs, root_slash) != 0 | continue | endif

    let last = getbufvar(b, 'drafts_last_change', 0.0)
    if last == 0.0
      call setbufvar(b, 'drafts_last_change', now)
      continue
    endif
    if (now - last) < g:drafts_save_interval_secs | continue | endif

    call s:update_visible_buf(b)
  endfor
endfunction

function! s:start_timer() abort
  if s:drafts_timer == -1 && has('timers')
    let s:drafts_timer = timer_start(s:drafts_poll_ms, function('<SID>timer_tick'), {'repeat': -1})
  endif
endfunction

function! s:stop_timer() abort
  if s:drafts_timer != -1
    call timer_stop(s:drafts_timer)
    let s:drafts_timer = -1
  endif
endfunction

" ------------------------- Helpers -------------------------
function! s:ensure_dir(path) abort
  if !isdirectory(a:path) | call mkdir(a:path, 'p') | endif
  return a:path
endfunction

function! s:ym_dir() abort
  let dir = g:drafts_root . '/' . strftime('%Y') . '/' . strftime('%m')
  return s:ensure_dir(dir)
endfunction

function! s:ft_suffix() abort
  let ft = &filetype
  return empty(ft) ? '' : '-' . ft
endfunction

function! s:buf_has_text(buf) abort
  if !bufloaded(a:buf) | return 0 | endif
  if getbufvar(a:buf, '&buftype') !=# '' | return 0 | endif
  let lines = getbufline(a:buf, 1, '$')
  return !(empty(lines) || (len(lines) == 1 && lines[0] ==# ''))
endfunction

" Assign a permanent drafts path to an unnamed, normal buffer as soon as it has content.
function! s:assign_draft_path() abort
  if bufname('%') !=# '' | return | endif               " already named
  if &buftype !=# '' | return | endif                    " only normal buffers
  if !&modifiable | return | endif                " skip special/unmodifiable
  if !s:buf_has_text(bufnr('%')) | return | endif

  let dir = s:ym_dir()
  let name = strftime('%Y%m%d-%H%M%S') . '-buf' . bufnr('%') . s:ft_suffix() . '.txt'
  let path = dir . '/' . name
  execute 'file' fnameescape(path)
  silent keepalt keepjumps noautocmd write
endfunction

" Is the current buffer a drafts file (under drafts_root)?
function! s:is_drafts_buffer() abort
  let name = expand('%:p')
  if empty(name) | return 0 | endif
  let root = resolve(fnamemodify(g:drafts_root, ':p'))
  let abs  = resolve(fnamemodify(name, ':p'))
  return stridx(abs, root . (root =~# '/$' ? '' : '/')) == 0
endfunction

" Scratch-only autosave (drafts dir only), on idle.
function! s:idle_autosave() abort
  if &modifiable && &modified && &buftype ==# '' && s:is_drafts_buffer()
    silent! noautocmd update
  endif
endfunction

" Get atime in epoch seconds; return -1 if unavailable.
function! s:file_atime(path) abort
  if has('unix')
    let cmd = 'sh -c ''(stat -c %X ' . shellescape(a:path) .
          \ ' 2>/dev/null) || (stat -f %a ' . shellescape(a:path) . ' 2>/dev/null) || echo -1'''
    let out = system(cmd)
    let n = str2nr(split(out, '\n')[-1], 10)
    return n > 0 ? n : -1
  elseif has('win32') || has('win64')
    let ps = 'powershell -NoProfile -Command "(Get-Item ' .
          \ '''' . substitute(a:path, '''', '''''', 'g') . '''' .
          \ ').LastAccessTime.ToFileTimeUtc()"'
    let out = system(ps)
    if v:shell_error != 0 | return -1 | endif
    let ft = str2float(trim(out))
    if ft <= 0 | return -1 | endif
    " Convert Windows FILETIME (100ns since 1601) to Unix seconds:
    return float2nr(ft / 10000000.0 - 11644473600.0)
  endif
  return -1
endfunction

" Is a given absolute path currently open in this Vim instance?
function! s:is_open_in_vim(path) abort
  let target = fnamemodify(a:path, ':p')
  for b in range(1, bufnr('$'))
    if buflisted(b)
      let name = bufname(b)
      if !empty(name) && fnamemodify(name, ':p') ==# target
        return 1
      endif
    endif
  endfor
  return 0
endfunction

" Daily cleanup: delete drafts older than retention, based on max(atime, mtime); skip open buffers.
function! s:cleanup_old_drafts() abort
  call s:ensure_dir(g:drafts_root)
  let now = localtime()

  " once-per-day guard via stamp file
  let need = 1
  if filereadable(s:daily_stamp)
    let last = getftime(s:daily_stamp)
    if last > 0 && now - last < 24 * 60 * 60
      let need = 0
    endif
  endif
  if !need | return | endif

  for f in glob(g:drafts_root . '/**/*', 1, 1)
    if empty(f) | continue | endif
    if isdirectory(f) | continue | endif
    if s:is_open_in_vim(f) | continue | endif

    let m = getftime(f)
    let a = s:file_atime(f)
    let ref = (a > 0 && a > m) ? a : m

    if ref > 0 && (now - ref) > g:drafts_retention_secs
      call delete(f)
    endif
  endfor

  " touch stamp
  call writefile([], s:daily_stamp)
endfunction

" ------------------------- Commands -------------------------
function! s:undraft_current() abort
  if !<SID>is_drafts_buffer()
    echoerr 'Not a drafts buffer'
    return
  endif
  let path = expand('%:p')
  if filereadable(path)
    call delete(path)
  endif
  " Detach from drafts lifecycle: make it a scratch buffer with a neutral name
  setlocal buftype=nofile bufhidden=hide noswapfile
  let newname = '[Undrafted ' . strftime('%Y-%m-%d %H:%M:%S') . ']'
  execute 'file' fnameescape(newname)
  setlocal nomodified
endfunction

command! DraftsUndraft call <SID>undraft_current()

" ------------------------- Autocommands -------------------------
augroup DraftsAutosave
  autocmd!
  " As soon as text appears in an unnamed buffer, assign drafts path and write once.
  autocmd TextChanged,TextChangedI * call <SID>assign_draft_path()

  " Track edits to compute idleness for timer-based autosave
  autocmd TextChanged,TextChangedI * call <SID>mark_changed()
  autocmd BufEnter * if get(b:, 'drafts_last_change', 0.0) == 0.0 | let b:drafts_last_change = reltimefloat(reltime()) | endif

  " Start/stop timer if available; otherwise fallback to CursorHold path without touching 'updatetime'
  autocmd VimEnter * if has('timers') | call <SID>start_timer() | endif
  autocmd VimLeavePre * if has('timers') | call <SID>stop_timer() | endif

  if !has('timers')
    " Legacy fallback: do idle autosave via CursorHold (uses user's existing 'updatetime')
    autocmd CursorHold,CursorHoldI * call <SID>idle_autosave()
  endif

  " Daily cleanup on startup (with 24h stamp guard).
  autocmd VimEnter * call <SID>cleanup_old_drafts()
augroup END