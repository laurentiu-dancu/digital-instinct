using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;

class SevenSegApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as Array<Views or InputDelegates>? {
        return [ new SevenSegView() ] as Array<Views or InputDelegates>;
    }

}

function getApp() as SevenSegApp {
    return Application.getApp() as SevenSegApp;
}