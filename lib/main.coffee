{Disposable} = require 'atom'
IconServices = require './icon-services'

module.exports =
  activate: (state) ->
    @active = true

    atom.commands.add 'atom-workspace',
      'fuzzy-finder:toggle-file-finder': =>
        @createProjectView().toggle()
      'fuzzy-finder:toggle-buffer-finder': =>
        @createBufferView().toggle()
      'fuzzy-finder:toggle-git-status-finder': =>
        @createGitStatusView().toggle()

    process.nextTick => @startLoadPathsTask()

    for editor in atom.workspace.getTextEditors()
      editor.lastOpened = state[editor.getPath()]

    atom.workspace.observePanes (pane) ->
      pane.observeActiveItem (item) -> item?.lastOpened = Date.now()

  deactivate: ->
    if @projectView?
      @projectView.destroy()
      @projectView = null
    if @bufferView?
      @bufferView.destroy()
      @bufferView = null
    if @gitStatusView?
      @gitStatusView.destroy()
      @gitStatusView = null
    @projectPaths = null
    @stopLoadPathsTask()
    @active = false

  consumeElementIcons: (service) ->
    IconServices.set 'element-icons', service
    new Disposable =>
      IconServices.reset 'element-icons'

  consumeFileIcons: (service) ->
    IconServices.set 'file-icons', service
    new Disposable ->
      IconServices.reset 'file-icons'

  serialize: ->
    paths = {}
    for editor in atom.workspace.getTextEditors()
      path = editor.getPath()
      paths[path] = editor.lastOpened if path?
    paths

  createProjectView: ->
    @stopLoadPathsTask()

    unless @projectView?
      ProjectView  = require './project-view'
      @projectView = new ProjectView(@projectPaths)
      @projectPaths = null
    @projectView

  createGitStatusView: ->
    unless @gitStatusView?
      GitStatusView  = require './git-status-view'
      @gitStatusView = new GitStatusView()
    @gitStatusView

  createBufferView: ->
    unless @bufferView?
      BufferView = require './buffer-view'
      @bufferView = new BufferView()
    @bufferView

  startLoadPathsTask: ->
    @stopLoadPathsTask()

    return unless @active
    return if atom.project.getPaths().length is 0

    PathLoader = require './path-loader'
    @loadPathsTask = PathLoader.startTask (@projectPaths) =>
    @projectPathsSubscription = atom.project.onDidChangePaths =>
      @projectPaths = null
      @stopLoadPathsTask()

  stopLoadPathsTask: ->
    @projectPathsSubscription?.dispose()
    @projectPathsSubscription = null
    @loadPathsTask?.terminate()
    @loadPathsTask = null
