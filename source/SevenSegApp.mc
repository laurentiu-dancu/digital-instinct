using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;

class SevenSegApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary?) as Void {
    }

    function onStop(state as Lang.Dictionary?) as Void {
    }

    function getInitialView() {
        return [ new SevenSegView() ];
    }
}

function getApp() as SevenSegApp {
    return Application.getApp() as SevenSegApp;
}