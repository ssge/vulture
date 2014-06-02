root = this;



mapCenter =
    lat: 46.1227
    lng: -72.6169
    zoom: 7

getLocalStorageCenter = () ->
    JSON.parse(localStorage.getItem("mapCenter"))



getSingleDataUrl = (routeParams) ->
    url = "/api/#{ routeParams.server }/#{ routeParams.database }/#{ routeParams.collection }"
    if routeParams.query
        url = "#{url}/query/#{ routeParams.query }" 
    return "#{ url }/idx/#{ Number(routeParams.idx) - 1 }"

getAllDataUrl = (routeParams) ->
    url = "/api/#{ routeParams.server }/#{ routeParams.database }/#{ routeParams.collection }"
    if routeParams.query
        url = "#{url}/query/#{ routeParams.query }" 
    return "#{ url }/all"

getDocumentUrl = (routeParams, id) ->
    return "/#{ routeParams.server }/#{ routeParams.database }/#{ routeParams.collection }/_id/#{ id }"

transformListOfGeoJsonToGeometryCollection = (resData, routeParams) ->
    ret =
        type: "FeatureCollection"
        features: []
    for doc in resData.document
        geojson = doc[routeParams.key]
        if not geojson.properties
            geojson.properties = {}
        geojson.properties["_vulture_url_link"] = getDocumentUrl(routeParams, doc._id)
        feature =
            type: "Feature"
            geometry: geojson,
            properties: geojson.properties
        ret.features.push(feature)
    return ret
    

root.controllers.controller('geojsonmapCtrl', ['$scope', '$routeParams', '$location', 'util', ($scope, $routeParams, $location, util) ->
    $scope.geojson = {}
    $scope.geojsonData = {}
    $scope.idx = Number($routeParams.idx)
    $scope.center = getLocalStorageCenter()
    
    $scope.$watch 'center', () ->
        localStorage.setItem("mapCenter", JSON.stringify($scope.center))
    
    $scope.getAggredatedUrl = () ->
        url = "#/#{ $routeParams.server }/#{ $routeParams.database }/#{ $routeParams.collection }/idx/all"
        if $routeParams.query
            url = "#{url}/query/#{$routeParams.query}"
        "#{url}/geojson/#{$routeParams.key}"
        

    $scope.previousDocumentUrl = () ->
        url = "#/#{ $routeParams.server }/#{ $routeParams.database }/#{ $routeParams.collection }/idx/#{$scope.idx - 1}"
        if $routeParams.query
            url = "#{url}/query/#{$routeParams.query}"
        "#{url}/geojson/#{$routeParams.key}"

    $scope.nextDocumentUrl = () ->
        url = "#/#{ $routeParams.server }/#{ $routeParams.database }/#{ $routeParams.collection }/idx/#{$scope.idx + 1}"
        if $routeParams.query
            url = "#{url}/query/#{$routeParams.query}"
        "#{url}/geojson/#{$routeParams.key}"

    $scope.hasPreviousDocument = () ->
        $scope.idx > 1
    
    $scope.$on "leafletDirectiveMap.geojsonClick", (ev, featureSelected, leafletEvent) ->
        $location.url(featureSelected.properties._vulture_url_link);
        
    $scope.setStyleOnFeature = (feature, element) ->
        if feature.properties and feature.properties.style
            element.setStyle(feature.properties.style)
        
    
    
    $scope.initSingleDocument = ()->
        url = getSingleDataUrl($routeParams)
        util.get(url).then (res) ->
            geojson = res.data.document[$routeParams.key]
            if not geojson.properties
                geojson.properties = {}
            geojson.properties["_vulture_url_link"] = getDocumentUrl($routeParams, res.data.document._id)
            $scope.meta = res.data.meta
            $scope.geojsonData =
                data: geojson
                style: geojson.properties.style or undefined
                resetStyleOnMouseout: true

    $scope.initAllDocuments = () ->
        url = getAllDataUrl($routeParams)
        util.get(url).then (res) ->
            $scope.meta = res.data.meta
            geojson = transformListOfGeoJsonToGeometryCollection(res.data, $routeParams)
            $scope.geojsonData =
                data: geojson
                onEachFeature: $scope.setStyleOnFeature
                resetStyleOnMouseout: true
    
    if $routeParams.idx
        $scope.mode = 'single_document'
        $scope.initSingleDocument()
    else
        $scope.mode = 'all'
        $scope.initAllDocuments()
])

