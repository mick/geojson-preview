url = require 'url'
fs = require 'fs-plus'

GeoJSONPreviewView = require './geojson-preview-view'

module.exports =

  activate: ->
    atom.workspaceView.command 'geojson-preview:show', =>
      @show()

    atom.workspace.registerOpener (uriToOpen) ->
      {protocol, pathname} = url.parse(uriToOpen)
      pathname = decodeURI(pathname) if pathname
      return unless protocol is 'geojson-preview:' and fs.isFileSync(pathname)
      new GeoJSONPreviewView(pathname)

  show: ->
    editor = atom.workspace.getActiveEditor()
    return unless editor?

    #unless editor.getGrammar().scopeName is "source.gfm"
  #    console.warn("Cannot render geojson for '#{editor.getUri() ? 'untitled'}'")
  #    return

    unless fs.isFileSync(editor.getPath())
      console.warn("Cannot render geojson for '#{editor.getPath() ? 'untitled'}'")
      return

    previousActivePane = atom.workspace.getActivePane()
    uri = "geojson-preview://#{editor.getPath()}"
    atom.workspace.open(uri, split: 'right', searchAllPanes: true).done (geoJSONPreviewView) ->
      if geoJSONPreviewView instanceof GeoJSONPreviewView
        geoJSONPreviewView.renderGeoJSON()
        previousActivePane.activate()
