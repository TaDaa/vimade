import sys
from vimade.util.promise import Promise
M = sys.modules[__name__]
import threading
import vim
import time

GLOBALS = None
IS_V3 = False

# Use the correct queue import for Python 2 and 3
try:
    import queue
except ImportError:
    import Queue as queue

# Queues for bi-directional communication
main_thread_queue = queue.Queue()
main_thread_wait_event = threading.Event()

worker_ops_sent = []
worker_thread_queue = queue.Queue()
worker_thread_wait_event = threading.Event()
worker_finished = False

STOP = 0
EVAL = 1
MEM_SAFE_EVAL = 2
COMMAND = 3
RUN = 4
BATCH_COMMAND = 5
BATCH_EVAL = 6
BATCH_RUN = 7
FLUSH = 8


if (sys.version_info > (3, 0)):
    IS_V3 = True

def __init(args):
  global GLOBALS
  GLOBALS = args['GLOBALS']

IS_NVIM = int(vim.eval('has("nvim")')) == 1
DICTIONARY = (dict, vim.Dictionary) if hasattr(vim, 'Dictionary') else dict
LIST = (list, vim.List) if hasattr(vim, 'List') else list

def py2_coerceTypes (input):
  if isinstance(input, (bytes, bytearray)):
    return str(input)
  elif isinstance(input, DICTIONARY):
    result = {}
    for key in input.keys():
      result[key] = coerceTypes(input.get(key))
    return result
  elif isinstance(input, LIST):
    return [coerceTypes(x) for x in list(input)]
  return input

def py3_coerceTypes (input):
  if isinstance(input, (bytes, bytearray)):
    return str(input, 'utf-8')
  elif isinstance(input, DICTIONARY):
    result = {}
    for key in input.keys():
      if isinstance(key, (bytes, bytearray)):
        key = str(key, 'utf-8')
      result[key] = coerceTypes(input.get(key))
    return result
  elif isinstance(input, LIST):
    return [coerceTypes(x) for x in list(input)]
  return input

coerceTypes = py3_coerceTypes if IS_V3 else py2_coerceTypes

def _vim_mem_safe_eval (statement):
  vim.command('unlet g:vimade_eval_ret | let g:vimade_eval_ret=' + statement)
  return coerceTypes(vim.vars['vimade_eval_ret'])

def _vim_eval_and_return (statement):
  vim.command('unlet g:vimade_eval_ret | let g:vimade_eval_ret=' + statement + '')
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

# lets think this through
# the way this is working:
# at startup=worker thread created
# worker thread waits until main notifies ready

class Main():
  def __init__(self):
    self._queue = queue.Queue()
    self._batch_cmd = []
    self._batch_cmd_promises = []
    self._batch_eval = []
    self._batch_eval_promises = []
    self._batch_run = []
    self._batch_run_promises = []
    # self._defer_to_worker = threading.Event()
    if IS_NVIM:
      self.eval_and_return = vim.eval
      self.mem_safe_eval = vim.eval
    else:
      self.eval_and_return = _vim_eval_and_return
      self.mem_safe_eval = _vim_mem_safe_eval
      self.command = vim.command
  def batch_command(self, statement):
    if GLOBALS.disablebatch:
      vim.command(statement)
      return Promise().resolve(None)
    promise = Promise()
    self._batch_cmd.append(statement)
    self._batch_cmd_promises.append(promise)
    return promise
  def batch_eval_and_return(self, statement):
    if GLOBALS.disablebatch:
      return Promise().resolve(self.eval_and_return(statement))
    promise = Promise()
    self._batch_eval.append(statement)
    self._batch_eval_promises.append(promise)
    return promise
  def batch_run(self, statement, **kwargs):
    if GLOBALS.disablebatch:
      return Promise().resolve(statement(**kwargs))
    promise = Promise()
    self._batch_run.append((statement, kwargs))
    self._batch_run_promises.append(promise)
  def enqueue(self, op):
    # print(op)
    self._queue.put(op)
    # self._defer_to_worker.set()
  def flush(self):
    eval = self._batch_eval
    eval_promises = self._batch_eval_promises
    cmd = self._batch_cmd
    cmd_promises = self._batch_cmd_promises
    run = self._batch_run
    run_promises = self._batch_run_promises
    promise = Promise()

    self._batch_eval = []
    self._batch_eval_promises = []
    self._batch_cmd = []
    self._batch_cmd_promises = []
    self._batch_run = []
    self._batch_run_promises = []

    if len(cmd) > 0:
      vim.command('\n'.join(cmd))
      for p in cmd_promises:
        p.resolve(None)

    if len(eval):
      results = self.eval_and_return('[' + ','.join(eval) + ']')
      for i, result in enumerate(results):
        eval_promises[i].resolve(result)

    if len(run):
      for i, (statement, kwargs) in enumerate(run):
        run_promises[i].resolve(statement(**kwargs))

    if (len(self._batch_eval) + len(self._batch_cmd) + len(self._batch_run)) > 0:
      self.flush().then(promise)
    else:
      promise.resolve(None)
    return promise
  def defer_to_worker(self, worker):
    def scope_resolution(op):
      def promise_then(val):
        op['response'] = val
        event = op.get('event')
        if event:
          event.set()
        # if put_back:
        #   worker._defer_to_main.set()
          # worker._waiting_for.put(op)
        # TODO use public
        # worker._defer_to_main.set()
      return promise_then
    while worker.is_running():
      op = self._queue.get(block = True) or {}
      type = op.get('type')
      statement = op.get('statement')
      # event = op.get('event')
      requires_flush = False
      if type == EVAL:
        self.batch_eval_and_return(statement).then(scope_resolution(op))
        # op['response'] = self.eval_and_return(statement)
        requires_flush = True
      elif type == MEM_SAFE_EVAL:
        scope_resolution(op)(self.mem_safe_eval(statement))
        requires_flush = False
      elif type == COMMAND:
        # op['response'] = self.command(statement)
        self.batch_command(statement).then(scope_resolution(op))
        requires_flush = True
      elif type == RUN:
        self.batch_run(statement[0], statement[1]).then(scope_resolution(op))
        requires_flush = True
      elif type == BATCH_EVAL:
        # sets an internal promise to set the op response
        self.batch_eval_and_return(statement).then(scope_resolution(op))
        requires_flush = True
      elif type == BATCH_COMMAND:
        # sets an internal promise to set the op response
        self.batch_command(statement).then(scope_resolution(op))
        requires_flush = True
      elif type == BATCH_RUN:
        self.batch_run(statement[0], statement[1]).then(scope_resolution(op))
        requires_flush = True
      elif type == STOP:
        self.flush()
        # TODO we need to ensure actually fully flushed
        break
      elif type == FLUSH:
        requires_flush = True
      if self._queue.empty() or requires_flush == True:
        self.flush()
      # if event:
      #   event.set()

main = Main()

class Worker():
  def __init__(self):
    self._defer_to_main = threading.Event()
    self._waiting_for_responses = []
    self._waiting_to_stop = False
    self._running = False
    # self._waiting_for_count = 0
    # self._waiting_for = queue.Queue()
    # self._waiting_for = queue.Queue()
    # self._tick = 0
  def start(self):
    self._running = True
  def is_running(self):
    return self._running
  def stop(self):
    if len(self._waiting_for_responses) > 0:
    # if self._waiting_for_count > 0:
      self._waiting_to_stop = True
      self.wait_for_responses()
    else:
      op = {'type' : STOP}
      self._running = False
      main.enqueue(op)
  def _sync_enqueue_to_main(self, op_type, statement):
    event = threading.Event()
    op = {
      'type': op_type,
      'statement': statement,
      'event': event,
    }
    main.enqueue(op)
    event.wait()
    return op['response']
  def _batch_enqueue_to_main(self, op_type, statement):
    op = {
      'type': op_type,
      'statement': statement,
      'promise': Promise(),
      'event': self._defer_to_main,
    }
    main.enqueue(op)
    self._waiting_for_responses.append(op)
    # self._waiting_for_count = self._waiting_for_count + 1
    return op['promise']
  def command(self, statement):
    return self._sync_enqueue_to_main(COMMAND, statement)
  def eval_and_return(self, statement):
    return self._sync_enqueue_to_main(EVAL, statement)
  def mem_safe_eval(self, statement):
    return self._sync_enqueue_to_main(MEM_SAFE_EVAL, statement)
  def run(self, statement):
    return self._sync_enqueue_to_main(RUN, statement)
  def batch_run(self, statement, **kwargs):
    return self._batch_enqueue_to_main(BATCH_RUN, (statement, kwargs))
  def batch_command(self, statement):
    return self._batch_enqueue_to_main(BATCH_COMMAND, statement)
  def batch_eval_and_return(self, statement):
    return self._batch_enqueue_to_main(BATCH_EVAL, statement)
  def flush(self):
    main.enqueue({'type': FLUSH})
  def wait_for_responses(self):
    # while self._waiting_for_count > 0:
    #   op = self._waiting_for.get(block = True)
    #   self._waiting_for_count = self._waiting_for_count - 1
    #   if 'response' in op:
    #     op['promise'].resolve(op['response'])
    # if self._waiting_to_stop:
    #   self.stop()
    while len(self._waiting_for_responses) > 0:
      ln = len(self._waiting_for_responses)
      i = 0
      while i < ln:
        op = self._waiting_for_responses[i]
        if 'response' in op:
          self._waiting_for_responses.pop(i)
          i = i - 1
          ln = ln - 1
          op['promise'].resolve(op['response'])
        i = i + 1
      if ln > 0:
        # print('blocking worker for main')
        self._defer_to_main.wait()
        self._defer_to_main.clear()
      elif self._waiting_to_stop:
        # print('stopping')
        self.stop()

worker = Worker()


# allows synchronous eval_and_return from worker thread
# def th_eval_and_return(statement):
#   op = {
#     'eval': statement, 
#     'event': threading.Event(),
#     'response': None
#   }
#   main_thread_queue.put(op)
#   op['event'].wait()
#   main_thread_wait_event.set()
#   return op['response']
#
# # allows synchronous mem_safe_eval from worker thread
# def th_mem_safe_eval(statement):
#   op = {
#     'mem_safe_eval': statement, 
#     'event': threading.Event(),
#     'response': None
#   }
#   main_thread_queue.put(op)
#   op['event'].wait()
#   main_thread_wait_event.set()
#   return op['response']
#
# def th_command(statement):
#   op = {
#     'command': statement, 
#     'event': threading.Event(),
#     'response': None
#   }
#   main_thread_queue.put(op)
#   op['event'].wait()
#   main_thread_wait_event.set()
#   return op['response']
#
# def th_batch_eval_and_return (statement):
#   if GLOBALS.disablebatch:
#     return Promise().resolve(th_eval_and_return(statement))
#   op = {
#     'batch_eval': statement,
#     'promise': Promise()
#   }
#   main_thread_queue.put(op)
#   main_thread_wait_event.set()
#   worker_ops_send.append(op)
#   return op['promise']
#
# def th_batch_command(statement):
#   if GLOBALS.disablebatch:
#     return Promise().resolve(th_command(statement))
#   op = {
#     'batch_command': statement,
#     'promise': Promise()
#   }
#   main_thread_queue.put(op)
#   main_thread_wait_event.set()
#   worker_ops_sent.append(op)
#   return op['promise']
#
# def worker_unwind():
#   while(len(worker_ops_sent)):
#     ln = len(worker_opts_sent)
#     for i in range(0, ln):
#       if 'result' in op:
#         ln = ln - 1
#         worker_ops_sent.pop(i)
#         promise = op.get('promise')
#         if promise:
#           promise.resolve(op['result'])
#

def batch_command(statement):
  if GLOBALS.disablebatch:
    vim.command(statement)
    return Promise().resolve(None)
  promise = Promise()
  M._batch_cmd.append(statement)
  M._batch_cmd_promises.append(promise)
  return promise

def batch_eval_and_return(statement):
  if GLOBALS.disablebatch:
    return Promise().resolve(eval_and_return(statement))
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


def block_main_thread(worker):
  def scope_resolution(op):
    def promise_then(val):
      op['response'] = val
      # TODO better to call this once if possible during resolving a set of events
      worker_thread_wait_event.set()
    return promise_then

  while worker.is_alive():
    try:
      op = main_thread_queue.get(block=False) or {}
      eval = op.get('eval')
      b_command = op.get('batch_command')
      b_eval = op.get('batch_eval')
      command = op.get('command')
      event = op.get('event')
      safe_eval = op.get('mem_safe_eval')
      promise = op.get('promise')
      if b_command:
        # sets an internal promise to set the op response
        batch_command(b_command).then(scope_resolution(op))
      if b_eval:
        # sets an internal promise to set the op response
        batch_eval_and_return(b_eval).then(scope_resolution(op))
      if command:
        op['response'] = vim.command(command)
      if eval:
        op['response'] = eval_and_return(eval)
      if safe_eval:
        op['response'] = M.mem_safe_eval(safe_eval)
      if event:
        event.set()
    except queue.Empty:
      # print('blocking for main')
      # TODO also reorganize this logic
      main_thread_wait_event.wait()

