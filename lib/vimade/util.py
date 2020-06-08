import vim
IS_NVIM = int(vim.eval('has("nvim")')) == 1

def _vim_eval_and_return (statement):
  vim.command('unlet g:vimade_eval_ret | let g:vimade_eval_ret=' + statement + '')
  return vim.eval('g:vimade_eval_ret')

_nvim_eval_and_return = vim.eval

eval_and_return = None
if IS_NVIM:
  eval_and_return = _nvim_eval_and_return
else:
  eval_and_return = _vim_eval_and_return

