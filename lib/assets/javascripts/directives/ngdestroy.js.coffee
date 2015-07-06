angular.module 'NgDestroy', ['Factories']

  .directive 'ngDestroy', ($timeout, $compile) ->
    restrict: 'A'
    link: (scope, element, attributes) ->
      element.bind 'click', (event) ->
        scope.destroy(attributes.ngDestroy,attributes.ngContext)
    controller: ($scope, $injector) ->
      $scope.destroy = (modelName,listName) ->
        raw_factory = modelName.split('_')
        factory=[]
        for word in raw_factory
          factory.push(word.charAt(0).toUpperCase() + word.slice(1))
        factory = factory.join('')
        if listName
          list = $scope
          for scope in listName.split('.')
            list = list[scope]
        else
          list = $scope[factory]
        list.splice(list.indexOf($scope[modelName]),1)
        list = $injector.get(factory)
        object = {id: $scope[modelName].id}
        list.delete object
