selectFile = (scope,event,attributes,file) ->
  model  = attributes.ngModel.split('.')
  id     = scope[attributes.ngModel.split('.')[0]].id
  parent = null
  if attributes.ngContext
    parent = attributes.ngContext
  scope.uploadFiles(model,id,file,parent)
  event.preventDefault()

fileData = (scope,attributes) ->
  data = {}
  unparsedModel = attributes.ngModel.split('.')
  if scope[unparsedModel[0]]
    if scope[unparsedModel[0]][unparsedModel[1]]
      unparsed   = scope[unparsedModel[0]][unparsedModel[1]].location.split('/')
      name       = unparsed.pop()
      id         = unparsed.pop()
      mounted_as = unparsed.pop()
      model      = unparsed.pop()
      data.path  = scope[unparsedModel[0]][unparsedModel[1]].url
      data.name  = name
      data.thumb = scope[unparsedModel[0]].thumb.url if scope[unparsedModel[0]].thumb
  return data

uploadFiles = (scope,element,model,id,file,parent,timeout,callback) ->
  scope.progress = 0
  element.addClass('covered')
  route = Routes[element[0].attributes['ng-model'].value.split('.')[0] + '_path'](id: id) + '.json'
  formData = new FormData()
  formData.append model[0] + '[id]', id
  formData.append model[0] + '[' + model[1] + ']', file
  formData.append model[0] + '[' + parent + '_id]', $scope[parent].id if parent
  xhr = new XMLHttpRequest()
  xhr.upload.addEventListener "progress", (event) ->
    if event.lengthComputable
      scope.$apply ->
        scope.progress = Math.round(event.loaded * 100 / event.total)
  , false
  xhr.addEventListener "readystatechange", (event) ->
    if this.readyState == 4 && !(this.status > 399)
      data = JSON.parse(event.target.response)
      scope.$apply ->
        scope[model[0]][model[1]] = data[model[1]]
        scope[model[0]].thumb = data.thumb
        scope.progress = 100
        element.removeClass('covered')
        scope.$eval(callback) if callback
    else if this.readyState == 4 && this.status > 399
      failed()
  , false
  xhr.addEventListener "error", (event) ->
    failed()
  , false
  failed = ->
    element.addClass('failed')

    timeout ->
      element.removeClass('failed')
      element.removeClass('covered')
    , 2000

  xhr.open("PUT", route)
  csrf = null
  for tag in document.getElementsByTagName('meta')
    csrf = tag.content if tag.name == 'csrf-token'
  xhr.setRequestHeader('X-CSRF-Token', csrf)
  xhr.send(formData)

angular.module('NgUpload', [])

  .directive 'ngDropFile', ->
    restrict: 'A'
    require: 'ngModel'
    link: (scope, element, attributes) ->
      dragHovered = 0
      el = angular.element("<div class='hovered-cover'>Drop Files Here</div>")
      element.bind 'dragenter', (event) ->
        dragHovered += 1
        element.addClass('hovered') if dragHovered == 1
        element.append el if dragHovered == 1
        height = window.getComputedStyle(element[0]).height
        el.css('height', height)
        el.css('line-height',height)
        el.css('margin-top', '-' + height)
      element.bind 'dragleave', (event) ->
        dragHovered -= 1
        element.removeClass('hovered') if dragHovered == 0
        el.remove() if dragHovered == 0
      element.bind 'dragover', (event) ->
        event.preventDefault()
        event.stopPropagation()
      element.bind 'drop', (event) ->
        event.preventDefault()
        event.stopPropagation()
        element.removeClass('hovered')
        el.remove()
        dragHovered = 0
        file   = (event.originalEvent || event).dataTransfer.files[0]
        selectFile(scope,event,attributes,file)
      scope.file = ->
        fileData(scope,attributes)

    controller: ($scope, $element, $http, $timeout) ->
      callback = ->
        $element[0].attributes['ng-callback'].value if $element[0].attributes['ng-callback']
      $scope.uploadFiles = (model,id,file,parent) ->
        uploadFiles($scope,$element,model,id,file,parent,$timeout,callback())
      $scope.progress = 0
      $scope.uploadProgress = ->
        return $scope.progress
  .directive 'ngUpload',  ->
    restrict: 'E'
    replace: true,
    require: 'ngModel',
    template:
      '<span class="ng-upload">
        <div class="ng-progress-bar">
          <span class="bar" style="width: {{uploadProgress() || 0}}%;"></span><span class="text" style="margin-left: -{{uploadProgress() || 0}}%;">{{uploadProgress()}}%</span>
        </div>
        <input accept="{{accept()}}" ng-model="ngModel" type="file" ng-class="{image: show(&#39;image&#39;)}" /><img ng-show="show(&#39;image&#39;)" ng-src="{{file().thumb}}" />
        <div class="button" ng-show="show(&#39;button&#39;)">
          Select File
        </div>
        <a download="" href="{{file().path}}" ng-show="show(&#39;text&#39;)" target="_blank">{{file().name}}</a></span>'

    link: (scope, element, attributes) ->
      element.children('img').bind 'click', (event) ->
        this.parentElement.getElementsByTagName('input')[0].click()
      element.children('.button').bind 'click', (event) ->
        this.parentElement.getElementsByTagName('input')[0].click()
      element.children('input').bind 'click', (event) ->
        event.stopPropagation()
      element.children('input').bind 'change', (event) ->
        file   = event.target.files[0]
        selectFile(scope,event,attributes,file)
      scope.file = ->
        fileData(scope,attributes)
      scope.accept = ->
        return attributes.accept if attributes.accept
        return '*'
    controller: ($scope, $element, $http, $timeout) ->
      callback = ->
        $element[0].attributes['ng-callback'].value if $element[0].attributes['ng-callback']
      $scope.show = (type) ->
        options = $element[0].attributes['ng-upload-options'].value.replace('{','').replace('}','').split(',')
        for option in options
          if option.indexOf(type) > -1
            return true if option.indexOf('true') > -1
        return false
      $scope.uploadFiles = (model,id,file,parent) ->
        uploadFiles($scope,$element,model,id,file,parent,$timeout,callback())
