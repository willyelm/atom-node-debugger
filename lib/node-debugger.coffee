{CompositeDisposable} = require 'atom'
{Debugger} = require './debugger'
jumpToBreakpoint = require './jump-to-breakpoint'
logger = require './logger'
os = require 'os'

processManager = null
_debugger = null
onBreak = null

module.exports =
  nodeDebuggerView: null
  config:
    nodePath:
      type: 'string'
      default: if os.platform() is 'win32' then 'node.exe' else '/bin/node'
    debugPort:
      type: 'number'
      minium: 5857
      maxium: 65535
      default: 5858
    debugHost:
      type: 'string'
      default: '127.0.0.1'
    nodeArgs:
      type: 'string'
      default: ''
    scriptMain:
      type: 'string'
      default: ''
    appArgs:
      type: 'string'
      default: ''
    env:
      type: 'string'
      default: ''

  activate: () ->
    @disposables = new CompositeDisposable()
    _debugger = new Debugger(atom)
    @disposables.add _debugger.subscribeDisposable 'connected', ->
      atom.notifications.addSuccess('connected, enjoy debugging : )')
    @disposables.add _debugger.subscribeDisposable 'disconnected', ->
      atom.notifications.addInfo('finish debugging : )')
    @disposables.add atom.commands.add('atom-workspace', {
      'node-debugger:start-resume': @startOrResume
      'node-debugger:start-active-file': @startActiveFile
      'node-debugger:stop': @stop
      'node-debugger:toggle-breakpoint': @toggleBreakpoint
      'node-debugger:step-next': @stepNext
      'node-debugger:step-in': @stepIn
      'node-debugger:step-out': @stepOut
      'node-debugger:attach': @attach
      'node-debugger:debug-tests-in-current-file': @debugTestsInCurrentFile
    })

    jumpToBreakpoint(_debugger)

  startOrResume: =>
    if _debugger.isConnected()
      _debugger.reqContinue()
    else
      _debugger.start()

  attach: =>
    return if _debugger.isConnected()
    _debugger.attach()

  startActiveFile: =>
    return if _debugger.isConnected()
    _debugger.startActiveFile()

  debugTestsInCurrentFile: =>
    return if _debugger.isConnected()
    _debugger.startTest()

  toggleBreakpoint: =>
    editor = atom.workspace.getActiveTextEditor()
    path = editor.getPath()
    {row} = editor.getCursorBufferPosition()
    _debugger.breakpointManager.toggleBreakpoint editor, path, row

  stepNext: =>
    _debugger.step('next', 1) if _debugger.isConnected()

  stepIn: =>
    _debugger.step('in', 1) if _debugger.isConnected()

  stepOut: =>
    _debugger.step('out', 1) if _debugger.isConnected()

  stop: =>
    _debugger.cleanup()
    jumpToBreakpoint.cleanup()

  deactivate: ->
    logger.info 'deactive', 'stop running plugin'
    jumpToBreakpoint.destroy()
    @stop()
    @disposables.dispose()
    _debugger.dispose()

  serialize: ->
    nodeDebuggerViewState: @nodeDebuggerView.serialize()
