path = require 'path'
{$, $$$, EditorView, ScrollView} = require 'atom'
_ = require 'underscore-plus'
{File} = require 'pathwatcher'
geojsonhint = require 'geojsonhint'
require 'mapbox.js'

module.exports =
class GeoJSONPreviewView extends ScrollView
  atom.deserializers.add(this)

  @deserialize: ({filePath}) ->
    new GeoJSONPreviewView(filePath)

  @content: ->
    @div class: 'geojson-preview native-key-bindings', tabindex: -1

  constructor: (filePath) ->
    super
    @file = new File(filePath)
    @handleEvents()

  serialize: ->
    deserializer: 'GeoJSONPreviewView'
    filePath: @getPath()

  destroy: ->
    @unsubscribe()

  handleEvents: ->
    @subscribe atom.syntax, 'grammar-added grammar-updated', _.debounce((=> @renderGeoJSON()), 250)
    @subscribe this, 'core:move-up', => @scrollUp()
    @subscribe this, 'core:move-down', => @scrollDown()
    @subscribe @file, 'contents-changed', =>
      @renderGeoJSON()
      pane = atom.workspace.paneForUri(@getUri())
      if pane? and pane isnt atom.workspace.getActivePane()
        pane.activateItem(this)

  renderGeoJSON: ->
    @showLoading()
    @file.read().then (contents) =>
      errors = geojsonhint.hint(contents)
      if errors.length > 0
        @showError(errors)
      else
        @html $$$ ->
          @div class: 'geojson-preview-map', ''
        window.L.Icon.Default.imagePath = 'http:' + window.L.Icon.Default.imagePath
        @map = L.mapbox.map($(@html).find('.geojson-preview-map')[0], 'mickt.hdof2a3d').setView([0, 0],4);
        layer = L.mapbox.featureLayer(JSON.parse(contents)).addTo(@map);
        @map.fitBounds(layer.getBounds())

  getTitle: ->
    "#{path.basename(@getPath())} Preview"

  getUri: ->
    "geojson-preview://#{@getPath()}"

  getPath: ->
    @file.getPath()

  showError: (result) ->
    failureMessage = result?.message

    @html $$$ ->
      @h2 'Previewing GeoJSON Failed'
      @h3 failureMessage if failureMessage?

  showLoading: ->
    @html $$$ ->
      @div class: 'geojson-spinner', 'Loading Map...'

  createMap: (geojson) =>
    html = $("<div class='geojson-preview-map'></div>")
    html
