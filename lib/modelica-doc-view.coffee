path                  = require 'path'
{CompositeDisposable, Disposable, Range, Point} = require 'atom'
{$, $$$, ScrollView}  = require 'atom-space-pen-views'
_                     = require 'underscore-plus'

module.exports =
class ModelicaDocView extends ScrollView
  atom.deserializers.add(this)

  editorSub           : null
  onDidChangeTitle    : -> new Disposable()
  onDidChangeModified : -> new Disposable()

  @deserialize: (state) ->
    new ModelicaDocView(state)

  @content: ->
    @div class: 'modelica-doc-view native-key-bindings', tabindex: -1

  constructor: ({@editorId, filePath}) ->
    super

    if @editorId?
      @resolveEditor(@editorId)
    else
      if atom.workspace?
        @subscribeToFilePath(filePath)
      else
        # @subscribe atom.packages.once 'activated', =>
        atom.packages.onDidActivatePackage =>
          @subscribeToFilePath(filePath)

  serialize: ->
    deserializer : 'ModelicaDocView'
    filePath     : @getPath()
    editorId     : @editorId

  destroy: ->
    # @unsubscribe()
    @editorSub.dispose()

  subscribeToFilePath: (filePath) ->
    @trigger 'title-changed'
    @handleEvents()
    @renderHTML()

  resolveEditor: (editorId) ->
    resolve = =>
      @editor = @editorForId(editorId)

      if @editor?
        @trigger 'title-changed' if @editor?
        @handleEvents()
      else
        # The editor this preview was created for has been closed so close
        # this preview since a preview cannot be rendered without an editor
        atom.workspace?.paneForItem(this)?.destroyItem(this)

    if atom.workspace?
      resolve()
    else
      # @subscribe atom.packages.once 'activated', =>
      atom.packages.onDidActivatePackage =>
        resolve()
        @renderHTML()

  editorForId: (editorId) ->
    for editor in atom.workspace.getTextEditors()
      return editor if editor.id?.toString() is editorId.toString()
    null

  handleEvents: =>

    changeHandler = =>
      @renderHTML()
      pane = atom.workspace.paneForURI(@getURI())
      if pane? and pane isnt atom.workspace.getActivePane()
        pane.activateItem(this)

    @editorSub = new CompositeDisposable

    if @editor?
      @editorSub.add @editor.onDidSave changeHandler
      @editorSub.add @editor.onDidChangePath => @trigger 'title-changed'

  renderHTML: ->
    @showLoading()
    if @editor?
      @renderHTMLCode()

  extractHTML: (startrow, stoprow, level) ->
    blockregex = /^\s*\b(package|class|model|function|record|block|connector|type)\b\s\b([a-zA-Z0-9_]+)\b/
    row = startrow
    anns0 = anns1 = ""
    loop
      if row > stoprow
        break
      blockmatch = @editor.lineTextForBufferRow(row).match(blockregex)
      if blockmatch
        name = blockmatch[2]
        endregex = new RegExp "\bend\b\s*\b" + name + "\b"
        endregex = new RegExp "end " + name + ";"
        anns1 += "<h" + level + ">" + blockmatch[0] + "</h" + level + ">"
        for erow in [stoprow..(row + 1)]
          if @editor.lineTextForBufferRow(erow).match(endregex)
            anns1 += @extractHTML(row + 1, erow - 1, level + 1)
            row = erow
            break
      htmlmatch = @editor.lineTextForBufferRow(row).match(/<html>/i)
      if htmlmatch
        for erow in [(row + 1)..stoprow]
          if @editor.lineTextForBufferRow(erow).match(/<\/html>/i)
            anns0 +=  @editor.getTextInBufferRange(new Range(new Point(row + 1, 0), new Point(erow, 0)))
            row = erow
            break
      row++
    anns0 + anns1

  renderHTMLCode: (text) ->
    # @html @extractHTML(0, @editor.getLastBufferRow(), 1)
    # See the following for the reason for adding markdown-preview
    # https://discuss.atom.io/t/scrollview-subclass-does-not-scroll/2808
    @html $('<div class="markdown-preview">').append(@extractHTML(0, @editor.getLastBufferRow(), 1))
    atom.commands.dispatch 'language-modelica', 'html-changed'

  getTitle: ->
    if @editor?
      "#{@editor.getTitle()} documentation"
    else
      "modelica-doc view"

  getURI: ->
    "modelica-doc-view://editor/#{@editorId}"

  getPath: ->
    if @editor?
      @editor.getPath()

  showError: (result) ->
    failureMessage = result?.message

    @html $$$ ->
      @h2 'Previewing HTML Failed'
      @h3 failureMessage if failureMessage?

  showLoading: ->
    @html $$$ ->
      @div class: 'atom-html-spinner', 'Loading modelica-doc-view\u2026'
