/*
    File used to store level 2 validation functions for Test Case pages
*/

function getFlowLst() {
    var flowList = "";
    var dataTable = $('#flows').dataTable();

    $(dataTable.fnGetNodes()).each(function(){   
        // Get the seq id and app ip from the row
        //seq_id = $(this).find("td").get(2);
        app_id = $(this).find('td[id=app_id]').text();

        //temp = seq_id + "," + app_id;
        flowList = flowList + app_id + "|";
    }); 

    // Remove the last character |
    flowList = flowList.substring(0, flowList.length - 1);

    return flowList;
}

function flowNameCheck( callback ) {
    // Get json for the flow table
    var flowList = getFlowLst();
    var tc_name = $('#test_case_name').val();

    console.log(flowList);

    // Check if the flow exists; if it does check if it has this test case name
    // call a function to return true/false....return true/false here to the calling function
    url = "/searchFlowTC/flow=" + flowList + "&tc=" + tc_name ;

    // Check the DB to see if there is a record already with this project id
    $.getJSON(url, function(data){    
        // console.log(data);
        callback(data);
    })
}

function getSoloList() {
    var soloList = "";
    var lastName = "";
    var dataTable = $('#steps').dataTable();

    $(dataTable.fnGetNodes()).each(function(){ 
        soloName = $(this).find('td[id=case_name]').text();
        app_id = $(this).find('td[id=app_id]').text();

        if (lastName == "" || lastName != soloName) {
            lastName = soloName;
            soloList = soloName + "¶" + app_id + "|";
        }
    });

    // Remove the last character |
    soloList = soloList.substring(0, soloList.length - 1);

    return soloList;
}

function soloNameCheck( callback ) {
    // Get a list of solo case names and their app ids
    var soloList = getSoloList();

    console.log("Solo List: ", soloList);

    url = "/searchSoloName/soloList=" + soloList 

    $.getJSON(url, function(data){    
        callback(data);
    })
}