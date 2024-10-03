import sys
from vimade.v2.util.promise import Promise
M = sys.modules[__name__]

import vim
IS_V3 = False
if (sys.version_info > (3, 0)):
    IS_V3 = True

IS_NVIM = int(vim.eval('has("nvim")')) == 1

def py2_coerceTypes (input):
  if isinstance(input, str):
    return str(input)
  elif isinstance(input, (int, long)):
    return str(input)
  elif isinstance(input, (bytes, bytearray)):
    return str(input)
  elif isinstance(input, vim.Dictionary):
    result = {}
    for key in input.keys():
      result[key] = coerceTypes(input.get(key))
    return result
  elif isinstance(input, vim.List):
    return [coerceTypes(x) for x in list(input)]
  return input

def py3_coerceTypes (input):
  if isinstance(input, str):
    return str(input)
  elif isinstance(input, int):
    return str(input)
  elif isinstance(input, (bytes, bytearray)):
    return str(input, 'utf-8')
  elif isinstance(input, vim.Dictionary):
    result = {}
    for key in input.keys():
      result[str(key, 'utf-8')] = coerceTypes(input.get(str(key, 'utf-8')))
    return result
  elif isinstance(input, vim.List):
    return [coerceTypes(x) for x in list(input)]
  return input

coerceTypes = py3_coerceTypes if IS_V3 else py2_coerceTypes

def _vim_mem_safe_eval (statement):
  vim.command('unlet g:vimade_eval_ret | let g:vimade_eval_ret=' + statement)
  return coerceTypes(vim.vars['vimade_eval_ret'])

def _vim_eval_and_return (statement):
  vim.command('unlet g:vimade_eval_ret | let g:vimade_eval_ret=' + statement + '')
  #print(statement)
  return vim.eval('g:vimade_eval_ret')

eval_and_return = None
mem_safe_eval = None

if IS_NVIM:
  eval_and_return = vim.eval
  mem_safe_eval = vim.eval
else:
  eval_and_return = _vim_eval_and_return
  mem_safe_eval = _vim_mem_safe_eval

M._batch_cmd = []
M._batch_cmd_promises = []
M._batch_eval = []
M._batch_eval_promises = []

def batch_command(statement):
  promise = Promise()
  M._batch_cmd.append(statement)
  M._batch_cmd_promises.append(promise)
  return promise

def batch_eval_and_return(statement):
  promise = Promise()
  M._batch_eval.append(statement)
  M._batch_eval_promises.append(promise)
  return promise

def flush_batch():
  eval = M._batch_eval
  eval_promises = M._batch_eval_promises
  cmd = M._batch_cmd
  cmd_promises = M._batch_cmd_promises
  promise = Promise()
  
  M._batch_eval = []
  M._batch_eval_promises = []
  M._batch_cmd = []
  M._batch_cmd_promises = []

  if len(cmd):
    vim.command('\n'.join(cmd))
    for i, p in enumerate(cmd_promises):
      p.resolve(None)

  if len(eval):
    results = M.eval_and_return('[' + ','.join(eval) + ']')
    for i, result in enumerate(results):
      eval_promises[i].resolve(result)

  if len(M._batch_eval) or len(M._batch_cmd):
    flush_batch().then(promise)
  else:
    promise.resolve(None)
  return promise
