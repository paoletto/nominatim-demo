import QtQuick 2.8
import QtQuick.Window 2.2
import QtLocation 5.10
import QtPositioning 5.8
import QtQuick.Controls 2.2

Window {
    visible: true
    width: 640
    height: 480
    title: qsTr("Hello World")
    id: root

    property var initialCenter : QtPositioning.coordinate(45.8, 15.96)

    Map {
        id: map
        gesture.enabled: true
        anchors.fill: parent
        opacity: 1.0
        color: 'transparent'
        plugin: Plugin {
            name: "osm"
            PluginParameter { name: "osm.useragent"; value: "MyFooBar" }
            PluginParameter { name: "osm.places.debug.query"; value: true }
            PluginParameter { name: "osm.places.page_size"; value: 100 }
        }
        center: initialCenter
        zoomLevel: 11
        copyrightsVisible: false

        property var visRegion : QtPositioning.shape()

        function updateVisRegion() {
            if (map.mapReady) {
                map.visRegion = map.visibleRegion;
            }
        }

        onMapReadyChanged: {
            updateVisRegion()
            //searchModel.updateSearch()
        }
        onZoomLevelChanged: {
            updateVisRegion()
        }
        onCenterChanged: {
            updateVisRegion()
        }
        onBearingChanged: {
            updateVisRegion()
        }
        onTiltChanged: {
            updateVisRegion()
        }

        MapItemView {
            model: searchModel
            delegate: MapQuickItem {
                coordinate: place.location.coordinate

                anchorPoint.x: image.width * 0.5
                anchorPoint.y: image.height

                sourceItem: Column {
                    Image { id: image; source: "marker.png" }
                    Text { text: title; font.bold: true }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: map.forceActiveFocus()
        }

        Label {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 10
            anchors.leftMargin: 10
            font.pixelSize: 16
            font.bold: true
            color: 'firebrick'
            text: map.zoomLevel.toFixed(1)
        }
    }

    Rectangle {
        id: search
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        width: 240
        height: 36
        color: Qt.rgba(1,1,1,0.3)
        border.color: "black"
        z:10000
        TextField {
            anchors.fill: parent
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            placeholderText: "e.g., pizza"

            background: Rectangle {
                    implicitWidth: search.width
                    implicitHeight: search.height
                    color: "transparent"
                    border.color: "transparent"
                }

            onAccepted: {
                console.log(displayText)
                searchModel.searchTerm = displayText
                searchModel.updateSearch()
            }
        }
    }

    Rectangle {
        id: realCoords
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        width: 240
        height: 36
        color: Qt.rgba(1,1,1,0.3)
        border.color: "black"
        z:10000
        TextInput {
            anchors.fill: parent
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            text: coordinateToText(map.center)

            function coordinateToText(coord) {
                return coord.latitude.toFixed(5) +  ", " + coord.longitude.toFixed(5)
            }

            onAccepted: {
                var arr = text.split(',')
                if (arr.length != 2)
                    return
                var lat = parseFloat(arr[0])
                var lon = parseFloat(arr[1])
                if (isNaN(lat) || isNaN(lon))
                    return
                map.center = QtPositioning.coordinate(lat, lon)
                centerAnim.from = mapItems.center
            }
        }
    }

    Item {
        id: crossHair
        property var crossColor: "deepskyblue"
        property var thickness: 2
        width: 20
        height: 20
        anchors.centerIn: parent
        z: map.z + 1

        Rectangle {
            id: crossHairH
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.thickness
            color: parent.crossColor
            border.width: 0
        }
        Rectangle {
            id: crossHairV
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.thickness
            color: parent.crossColor
            border.width: 0
        }
    }

    Shortcut {
        sequence: "Ctrl+A"
        onActivated: {
            searchModel.updateSearch()
        }
    }

    PlaceSearchModel {
        id: searchModel

        plugin: map.plugin

        //searchTerm: "Pizza"
        searchArea: map.visRegion.boundingGeoRectangle()

        //Component.onCompleted: update()

        function updateSearch()
        {
            var term = searchModel.searchTerm
            searchModel.searchTerm = term // this effectively resets the request's context
            searchModel.update()
        }

        onStatusChanged: {
            if (status != 1) // 1 ready
                return;

            console.log("Ready")
            if (count > 0)
                console.log("Row ", count - 1, ":", data(count - 1, "place").extendedAttributes["requestUrl"].text)

            if (nextPagesAvailable) {
                incremental = true
                nextPage()
                update()
            } else {
                incremental = false
            }
        }
    }

    Connections {
        target: searchModel
        onStatusChanged: {
            if (searchModel.status == PlaceSearchModel.Error)
                console.log(searchModel.errorString());
        }
    }
}
