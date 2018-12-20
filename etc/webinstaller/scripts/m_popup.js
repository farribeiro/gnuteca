Miolo.popup = Class.create();

Miolo.popup.prototype = {
	initialize: function(xOffset,yOffset) {
        this.xOffset = xOffset;
        this.yOffset = yOffset;
	},
    getMousePosition: function( e ) {
        //is_ie = ( /msie/i.test(navigator.userAgent) && !/opera/i.test(navigator.userAgent) );
        var is_ie = document.all ? true : false;
        var posX;
        var posY;
        if ( is_ie ) 
        {
            posY = window.event.clientY + document.body.scrollTop;
            posX = window.event.clientX + document.body.scrollLeft;
        } else {
            posY = e.clientY + window.scrollY;
            posX = e.clientX + window.scrollX;
        }
        return new Array( posX, posY);
    },
    showPopup: function (targetObjectId, eventObj) {
        if(eventObj) {
            // hide any currently-visible popups
            if ( window.currentlyVisiblePopup == targetObjectId )
            {
                this.hideCurrentPopup();
                return;
            }
            this.hideCurrentPopup();
            // stop event from bubbling up any farther
            eventObj.cancelBubble = true;
            var mousePosition = this.getMousePosition(eventObj)
            // ho knows why, but it's needed otherwise it goes out of the expected bounds
            var newXCoordinate = mousePosition[0]-125;
            var newYCoordinate = mousePosition[1]-56;
            this.moveObject(targetObjectId, newXCoordinate, newYCoordinate);
            // and make it visible
            if( this.changeObjectVisibility(targetObjectId, 'visible') ) {
                // if we successfully showed the popup
                // store its Id on a globally-accessible object
                window.currentlyVisiblePopup = targetObjectId;
                return true;
            } else {
                // we couldn't show the popup, boo hoo!
                return false;
            }
        } else {
            // there was no event object, so we won't be able to position anything, so give up
            return false;
        }
    },
    hideCurrentPopup: function() {
        // note: we've stored the currently-visible popup on the global object window.currentlyVisiblePopup
        if(window.currentlyVisiblePopup) {
            this.changeObjectVisibility(window.currentlyVisiblePopup, 'hidden');
            window.currentlyVisiblePopup = false;
        }
    }, // hideCurrentPopup
    getStyleObject: function (objectId) {
        // cross-browser function to get an object's style object given its id
        if(document.getElementById && document.getElementById(objectId)) {
            // W3C DOM
            return document.getElementById(objectId).style;
        } else if (document.all && document.all(objectId)) {
            // MSIE 4 DOM
            return document.all(objectId).style;
        } else if (document.layers && document.layers[objectId]) {
            // NN 4 DOM.. note: this won't find nested layers
            return document.layers[objectId];
        } else {
            return false;
        }
    }, // getStyleObject
    changeObjectVisibility: function (objectId, newVisibility) {
        // get a reference to the cross-browser style object and make sure the object exists
        var styleObject = this.getStyleObject(objectId);
        if(styleObject) {
            styleObject.visibility = newVisibility;
            return true;
        } else {
            // we couldn't find the object, so we can't change its visibility
            return false;
        }
    }, // changeObjectVisibility
    moveObject: function (objectId, newXCoordinate, newYCoordinate) {
        // get a reference to the cross-browser style object and make sure the object exists
        var styleObject = this.getStyleObject(objectId);
        if(styleObject) {
            styleObject.left = newXCoordinate+'px';
            styleObject.top = newYCoordinate+'px';
            return true;
        } else {
            // we couldn't find the object, so we can't very well move it
            return false;
        }
    } // moveObject
}

miolo.popup = new Miolo.popup();