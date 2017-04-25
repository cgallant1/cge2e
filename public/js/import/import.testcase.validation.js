/*
    File used to store level 2 validation functions for Import Test Case page
*/

// <script src="/js/main.js"></script>

function appNameCheck( callback ) {
    // Get json for the flow table
    var cases = getCases();
    //alert(cases);

    for (i = 0; i < cases.length; i++) {
        //console.log(JSON.stringify(cases[i]));
        //console.log(i);
        var row = cases[i];
        var app_name = row["Application Name"] 
        //console.log(appName);

        if (app_name != 'Application Name') {
            arrApp = app_name.split(' - ');
            prod_id = arrApp[0].trim();  
            appname = app_name.replace(prod_id + ' - ', '');    

            // Replace special characters
            appName = appname.replace(/\//g, "¶");
            appName = appName.replace(/\./g, "Ð");
            //console.log(prod_id);

            url = "/searchProjectApp/projectid=" + prod_id + "&appname=" + appName;
            // Check the DB to see if there is a record already with this project id
            $.getJSON(url, function(count){
                 if (count == "found") {
                    // console.log("found");
                    callback("found");
                 } else {
                    // url = "/searchAppName/appname=" + appName;
                    // console.log(count);
                    // Check the DB to see if there is a record already with this app name
                    // $.getJSON(url, function(count){
                    //      if (count > 0) {
                    //         callback("found");
                    //      } else { 
                    callback(count);
                    //      }
                    // })              
                 }
            })
        }        
    }

    // cases.forEach(function(row, i) {

    // })
}