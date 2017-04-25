/*
    File used to store field validation functions for Flow Create page
        - Field lengths and illegal characters
        - Required fields
*/

function checkRequiredFields(){
    // var arrFail = [];

    // if ($('#projectid').val() == '' ){
    //     arrFail.push('Project ID');
    // }
    // if ($('#appname').val() == '' ){
    //     arrFail.push('App Name');
    // }

    // return arrFail
}

function duplicateDataCheck( callback ) {
    var url = "";

    // alert(flowName);

    // // Get an array of the selected Apps
    // var options = $('#select2 option');
    // var apps = $.map(options ,function(option) {
    //     return option.value;
    // });

   // for (var i = 0; i < apps.length; i++) {
   //     flow_name += apps[i] + "|";
   // };
   // flow_name = flowName.substring(0, flowName.length - 1);
   // alert(flow_name);
    // var flowName = "";
    // var temp = "";
    // $('#select2 option').each(function() {
    //     // Get the value and mark the separation of the PPMID and Name (cannot use - since it can exist in name also)
    //     temp = $(this).text();
    //     temp = temp.replace(' - ', 'œ');
    //     // Cut the PPM ID off
    //     arrTemp = temp.split('œ'); 
    //     flowName += arrTemp[1] + " > ";
    // });
    // flow_name = flowName.substring(0, flowName.length - 3);AS


    // Replace special characters
    flow_name = flowName;
    flow_name = flow_name.replace(/\//g, "¶");
    flow_name = flow_name.replace(/\./g, "Ð");

    url = "/submitFlowName/flowname=" + flow_name;

    // Check the DB to see if there is a record already with this flow name
    $.getJSON(url, function(count){
         callback(count);
    })
}