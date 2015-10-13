{CompositeDisposable, Point, Range, TextBuffer} = require 'atom'
url             = require 'url'
ModelicaDocView = require './modelica-doc-view'

module.exports = ModelicaFolding =
  subscriptions: null

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles the view
    @subscriptions.add atom.commands.add 'atom-workspace', 'language-modelica:toggleannotations': (event) => @toggleannotations(event)
    @subscriptions.add atom.commands.add 'atom-workspace', 'language-modelica:toggleallannotations': => @toggleallannotations()
    @subscriptions.add atom.commands.add 'atom-workspace', 'language-modelica:toggledocview': => @toggledocview()

    atom.workspace.addOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'modelica-doc-view:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is 'editor'
        new ModelicaDocView(editorId: pathname.substring(1))
      else
        new ModelicaDocView(filePath: pathname)

    @foldnext = true

  deactivate: ->
    @subscriptions.dispose()

  toggleannotations: (event) ->
    editor = atom.workspace.getActiveTextEditor()
    startpos = editor.getCursorBufferPosition()
    startrow = startpos.row
    if !editor.lineTextForBufferRow(startrow).match(/annotation/)
      event.abortKeyBinding()
      return
    shouldunfold = editor.isFoldedAtBufferRow(startrow + 1)
    row = startrow
    loop
      if shouldunfold
        editor.unfoldBufferRow(row)
      if editor.lineTextForBufferRow(row).match(/\)\s*;\s*$/)
        if !shouldunfold
          if row > startrow
            editor.setSelectedBufferRange(new Range(new Point(startrow, 0), new Point(row, 0)))
            editor.foldSelectedLines()
            editor.moveUp()
        break
      row++

  toggleallannotations: ->
    editor = atom.workspace.getActiveTextEditor()
    editor.createFold(0, editor.getLastBufferRow())
    if !@foldnext
      editor.unfoldAll()
    else # fold
      lookingforfirst = true
      for row in [0..editor.getLastBufferRow()]
        if lookingforfirst
          if editor.lineTextForBufferRow(row).match(/annotation/)
            firstrow = row
            lookingforfirst = false
        if !lookingforfirst
          if editor.lineTextForBufferRow(row).match(/\)\s*;\s*$/)
            lookingforfirst = true
            if row > firstrow
              editor.createFold(firstrow, row)
    editor.moveToTop()
    editor.unfoldCurrentRow()
    @foldnext = !@foldnext

  toggledocview: ->

    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    uri = "modelica-doc-view://editor/#{editor.id}"

    previewPane = atom.workspace.paneForURI(uri)
    if previewPane
      previewPane.destroyItem(previewPane.itemForURI(uri))
      return

    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, split: 'right', searchAllPanes: true).done (modelicaDocView) ->
      if modelicaDocView instanceof ModelicaDocView
        modelicaDocView.renderHTML()
        previousActivePane.activate()
