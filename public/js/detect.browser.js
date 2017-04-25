function currentBrowser() {

    $.returnVal = "";

    var browserUserAgent = navigator.userAgent;

    if (browserUserAgent.indexOf("Firefox") > -1) {

        $.returnVal = { browser: "Firefox" };
    }

    else if (browserUserAgent.indexOf("Chrome") > -1) {

        $.returnVal = { browser: "Chrome" };
    }

    else if (browserUserAgent.indexOf("Safari") > -1) {

        $.returnVal = { browser: "Safari" };
    }

    else if (browserUserAgent.indexOf("MSIE") > -1 || browserUserAgent.indexOf("Trident/") > -1) {

        var splitUserAgent = browserUserAgent.split(";");

        for (var val in splitUserAgent) {

            if (splitUserAgent[val].match("MSIE")) {

                var IEVersion = parseInt(splitUserAgent[val].substr(5, splitUserAgent[val].length));
            }
        }

        $.returnVal = { browser: "IE", version: IEVersion };
    }

    else if (browserUserAgent.indexOf("Opera") > -1) {

        $.returnVal = { browser: "Opera" };
    }

    else {
        $.returnVal =
         { browser: "other" };
    }

    return $.returnVal;
}