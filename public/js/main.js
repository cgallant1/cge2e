// Used to allow external access to data
var caseList;
var stepList;

// A List of cells that have errors
var errorCells = {error_data:[]};
var errOverIdx;

var errorStepCells = {error_data:[]};
var errStepIdx;

var numbers = /^[0-9]+$/;
var caseExp = /^[a-zA-Z0-9-_&\s]+$/;
var appNameExp = /^[0-9]{1,6}\s-\s([0-9]|[a-z]|[A-Z]|[\.\/\(\)\s-:@_&,])*$/;
var execTypes = /^Automation$|^Manual$|^Both$/;
var testTypes = /^Regression$|^Functional$/;

/** drop target **/
var _target = document.getElementById('drop');

/** Spinner **/
var spinner;

var _workstart = function() { spinner = new Spinner().spin(_target); }
var _workend = function() { spinner.stop(); }

/** Alerts **/
var _badfile = function() {
  alertify.alert('This file does not appear to be a valid Excel file.', function(){});
};

var _pending = function() {
  alertify.alert('Please wait until the current file is processed.', function(){});
};

var _large = function(len, cb) {
  alertify.confirm("This file is " + len + " bytes and may take a few moments.  Your browser may lock up during this process.  Continue?", cb);
};

var _failed = function(e) {
  console.log(e, e.stack);
  alertify.alert('Failed to load the Excel file.', function(){});
};

/** Handsontable magic **/
var boldRenderer = function (instance, td, row, col, prop, value, cellProperties) {
  Handsontable.TextCell.renderer.apply(this, arguments);
  $(td).css({'font-weight': 'bold'});
  $(td).css({'background-color': 'yellow'});
};

var errorRenderer = function (instance, td, row, col, prop, value, cellProperties) { 
  var temp = '';

  Handsontable.TextCell.renderer.apply(this, arguments);
  // $(td).css({'font-weight': 'bold'});

  //console.log(row, prop);

  // Find the current error
  var i = 0;
  var errIdx = -1;
  while ( i <= errorCells.error_data.length - 1 ) {
    if (errorCells.error_data[i]['row'] == row && errorCells.error_data[i]['col'] == prop) {
      temp = temp + errorCells.error_data[i]['detail'] + '\n';
      //errIdx = i;
      //break;
    }
    i++; 
  }

  $(td).attr({'title': temp});    
  $(td).css({'background-color': 'pink'});
};

var errorStepRenderer = function (instance, td, row, col, prop, value, cellProperties) {
  var temp = '';

  Handsontable.TextCell.renderer.apply(this, arguments);
  // $(td).css({'font-weight': 'bold'});
  
  // Find the current error
  var i = 0;
  var errIdx = -1;
  while ( i <= errorStepCells.error_data.length - 1 ) {
    if (errorStepCells.error_data[i]['row'] == row && errorStepCells.error_data[i]['col'] == prop) {
      temp = temp + errorStepCells.error_data[i]['detail'] + '\n';
      //errIdx = i;
      //break;
    }
    i++; 
  }
  //alert(temp);

  $(td).attr({'title': temp});
  $(td).css({'background-color': 'pink'});
};

var normRenderer = function (instance, td, row, col, prop, value, cellProperties) {
  Handsontable.TextCell.renderer.apply(this, arguments);

  $(td).attr({'title': ''});
  $(td).css({'background-color': ''});
};

var $container, $parent, $window, availableWidth, availableHeight;
var calculateSize = function () {
  var offset = $container.offset();
  availableWidth = Math.max($window.width() - 400,600);
  availableHeight = Math.max($window.height() - 400, 400);
};

$(document).ready(function() {
  $container = $("#hot"); $parent = $container.parent();
  $window = $(window);
  $window.on('resize', calculateSize);
});

/* make the buttons for the sheets */
var make_buttons = function(sheetnames, cb) {
  var $buttons = $('#buttons');
  $buttons.html("");
  sheetnames.forEach(function(s,idx) {
    var button= $('<button/>').attr({ type:'button', name:'btn' +idx, text:s });
    button.append('<h8>' + s + '</h8>');
    button.click(function() { cb(idx); });
    $buttons.append(button);
    $buttons.append('<br/>');
  });
};

var _onsheet = function(json, json2, cols, cols2, sheetnames, select_sheet_cb) {
  var tableErrMsg = "";

  if (validateSheets(sheetnames)) {
    //console.log(cols);
    // Validate Case Overview headers
    if (validateOverviewHeaders(cols)) {

      // Validate Steps headers
      if (validateStepsHeaders(cols2)) {

        // make_buttons(sheetnames, select_sheet_cb);
        calculateSize();

        /* add header row for table */
        if(!json) json = [];
        json.unshift(function(head){var o = {}; for(i=0;i!=head.length;++i) o[head[i]] = head[i]; return o;}(cols));
        calculateSize();

        // Update the lists for external access
        caseList = json;
        stepList = json2;

        // New function to check the tables start at 1 for app index
        if (validateStartAppIdxOverview(json)) {
          // Validate Case Overview field lengths / requirements / formats
          validateOverviewReqLength(json);

          // Validate that data matches between the 2 tables for E2E Case Name / App name / App index
          validateTableRels(json, json2);
        }

        //if (validateStartAppIdxStep(json2)) {
        if (validateStartStepIdx(json2)) {  
          // Validate Case Steps field lengths / requirements / formats
          validateStepsReqLength(json2);
        }

        // Need a function here to check for duplicate Solo Test Cases
        checkDupeSoloCases(json2);
        // if (caseList != "") {
        //   alertify.alert('<span style="color: red;"><b>Warning:</b> This Excel file contains duplicate Solo Cases!</span><br><br>' + caseList + '<br>Please make sure the steps in these cases contain the same data. Duplicates will save over an existing case!<br>', function(){}); 
        // }

        if (errorCells.error_data.length > 0) { tableErrMsg = errorCells.error_data.length + ' - error(s) in the Case Overview table.';}  
        if (errorStepCells.error_data.length > 0) { tableErrMsg = tableErrMsg + '<br>' + errorStepCells.error_data.length + ' - error(s) in the Case Steps table.'; }             
        if (errorCells.error_data.length > 0 || errorStepCells.error_data.length > 0) {
          alertify.alert('Errors were found in the Excel file.<br>They are highlighted in pink below:<br><br>' + tableErrMsg, function(){}); 
          $('#submit_data').attr('disabled', true);
        }

/////////////////////////////////////////////
// DEBUG
/////////////////////////////////////////////
// console.log(errorCells.error_data);
// console.log(errorStepCells.error_data);
/////////////////////////////////////////////


        // Change the color of the file box to inform the user of the status of validation
        if (errorCells.error_data.length + errorStepCells.error_data.length > 0) {
          $('#drops').css('background-color',"#FFE0E0");
          $('#drop').css('background-color',"#FFE0E0");
        } else {
          $('#drops').css('background-color',"#DAFFDA");
          $('#drop').css('background-color',"#DAFFDA");          

        }

        errOverIdx = 0;
        /* showtime! */
        $("#hot").handsontable({
          data: json,
          startRows: 5,
          startCols: 3,
          fixedRowsTop: 1,
          stretchH: 'all',
          rowHeaders: true,
          columns: cols.map(function(x) { return {data:x}; }),
          colHeaders: cols.map(function(x,i) { return XLS.utils.encode_col(i); }),
          cells: function (r,c,p) {
            if(r === 0) {
              // Header cells
              this.renderer = boldRenderer;
            } else if (errorCells.error_data.length > 0) {
              var i = 0;
              var errIdx = -1;
              while ( i <= errorCells.error_data.length - 1 ) {
                if (errorCells.error_data[i]['row'] == r && errorCells.error_data[i]['col'] == p) {
                  errIdx = i;
                  break;
                }
                i++; 
              }  
              // Mark Error Cells
              if (errIdx != -1) { this.renderer = errorRenderer; } else { this.renderer = normRenderer; };
            } else {
              this.renderer = normRenderer;
            }
            var cellProperties = {};
            cellProperties.readOnly = true;
            return cellProperties; 
          },
          // width: function () { return availableWidth; },
          height: 310, //function () { return availableHeight; },
          //stretchH: 'all'
        });

        errStepIdx = 0;
        if(!json2) json2 = [];
        json2.unshift(function(head){var o = {}; for(i=0;i!=head.length;++i) o[head[i]] = head[i]; return o;}(cols2));
        $("#steps").handsontable({
          data: json2,
          startRows: 5,
          startCols: 3,
          fixedRowsTop: 1,
          stretchH: 'all',
          rowHeaders: true,
          columns: cols2.map(function(x) { return {data:x}; }),
          colHeaders: cols2.map(function(x,i) { return XLS.utils.encode_col(i); }),
          cells: function (r,c,p) {
            if(r === 0) {
              // Header cells
              this.renderer = boldRenderer;
            } else if (errorStepCells.error_data.length > 0) {
              var i = 0;
              var errIdx = -1;
              while ( i <= errorStepCells.error_data.length - 1 ) {
                if (errorStepCells.error_data[i]['row'] == r && errorStepCells.error_data[i]['col'] == p) {
                  errIdx = i;
                  break;
                }
                i++; 
              }  
              // Mark Error Cells
              if (errIdx != -1) { this.renderer = errorStepRenderer; } else { this.renderer = normRenderer; };
            } else {
              this.renderer = normRenderer;
            }
            var cellProperties = {};
            cellProperties.readOnly = true;
            return cellProperties;             
          },
          // width: function () { return availableWidth; },
          height: 310,
          stretchH: 'all'
        });         
      }    
    }
  }
};

function getCases(){
  return caseList;
}

function getSteps(){
  return stepList;
}

function validateSheets(sheetnames){
  // Validate the sheet are correct
  if (sheetnames.length >= 2) {
    if (sheetnames[0] != "E2E Test Cases" || sheetnames[1] != "Solo Test Cases") {
      alertify.alert('Excel Sheet Error: <br><br>The first sheet should be E2E Test Cases<br>The second sheet shoud be Solo Test Cases', function(){});
      enableDisablePage(false);
      return false;
    } else {
      // Sheets are correct
      enableDisablePage(true);
      return true;
    }    
  } else {
    alertify.alert('Excel Sheet Error: There should be 2 sheets in the file.<br>[Case Overview, Case Steps]', function(){});    
    return false;
  }    
}

function validateOverviewHeaders(cols) {
  var i = 0;
  var errors = [];
  //var header = ["PPMID", "E2E Project Name", "E2E Test Case Name","Execution Type", "Test Case Type", "Reference Link", "Owner", "Application Index", "Application Name", "Portfolio", "Environment Box", "Biz Process/T-Code",  "Key Document Type",  "Company Codes"];
  var header = ["PPMID", "E2E Project Name", "E2E Test Case Name","Business Flow (For Review)", "Application Index", "Application Name", "Environment Box", "Solo Test Cases", "Data Input/T-Code", "Key Document Type", "Company Codes","Execution Type","Test Case Type","Owner"];

  for (var i in header) {
    //console.log(cols[i], header[i]);
    if (cols[i] != header[i]) {
      console.log(cols[i]);
      errors.push(i);
    }
  }

  if (errors.length > 0) {
    alertify.alert('Case Overview; Header Error:<br><br>Please review the order and spelling of<br>your column headers.', function(){});
    enableDisablePage(false);
    return false;
  }else{
    enableDisablePage(true);
    return true;
  }  
}

function validateStepsHeaders(cols) {
  var i = 0;
  var errors = [];
  //var header = [ "E2E Test Case Name","Application Index","Application Name","Solo Test Case Name","Step Index", "Process Name","Description","Expected Result","Data Input"];
  var header = [ "Subject", "Status", "Product", "BP Filter", "Test Script ID", "Application Name", "Solo Test Cases Name", "Solo Test Cases Description", "Step Name", "Description", "Expected Result", "Test Case Designer", "Memo"];

  for (var i in header) {
    //console.log(cols[i]);
    if (cols[i] != header[i]) {
      console.log(cols[i]);
      errors.push(i);
    }
  }

  if (errors.length > 0) {
    alertify.alert('Case Steps; Header Error:<br><br>Please review the order and spelling<br>of your column headers.', function(){});
      enableDisablePage(false);
      return false;
  }else{
      enableDisablePage(true); 
      return true;
  }  
}

function validateStartAppIdxOverview(json) {
  var overRow = json[1];
  var app_idxO = overRow['Application Index'];

  if (app_idxO != 1) {
    addOverviewError(1, "Application Index", "CRITICAL ERROR: Index must start at 1");
  }

  // Check the initial indexes are 1 for both tables; mark them on the grid if errors & return false
  if (app_idxO != 1) {
    return false;
  } else {
    return true;
  }
}

function validateStartAppIdxStep(json2) {
  var stepRow = json2[0];
  var app_idxS = stepRow['Application Index'];

  if (app_idxS != 1) {
    addStepError(1, "Application Index", "CRITICAL ERROR: Index must start at 1");
  }

  // Check the initial indexes are 1 for both tables; mark them on the grid if errors & return false
  if (app_idxS != 1) {
    return false;
  } else {
    return true;
  }
}

function validateStartStepIdx(json2) {
  var stepRow = json2[0];
  var step_idx = stepRow['Step Name'];

  if (step_idx != 1) {
    addStepError(1, "Step Name", "CRITICAL ERROR: Step Name must start at 1");
  }

  // Check the initial indexes are 1 for both tables; mark them on the grid if errors & return false
  if (step_idx != 1) {
    return false;
  } else {
    return true;
  }
}


function validateOverviewReqLength(json) {
  // Validate Case Overview required fields / index 1 vs index 2+ row differences
  //var error = new Object;
  var temp = "";
  //var data = json[0];
  var i = 0;
  var lastIdx = 0;

  json.forEach(function(row) {
    var ppmid = row["PPMID"]
    var project = row["E2E Project Name"]
    var casename = row["E2E Test Case Name"]
    var solo_case_name  = row["Solo Test Cases"]
    //var det_doc = row["Reference Link"]
    var app_idx = row["Application Index"]
    var app_name = row["Application Name"]
    //var portf = row["Portfolio"]
    var env_box = row["Environment Box"]
    var biz_proc = row["Data Input/T-Code"]
    var key_doc = row["Key Document Type"]
    var com_code = row["Company Codes"]
    var exec_type = row["Execution Type"]
    var test_type = row["Test Case Type"]    
    var owner = row["Owner"]

    if (i > 0) {
      if (app_idx == null) { 
        addOverviewError(i, "Application Index", "CRITICAL ERROR: Mandatory field!"); 
        lastIdx = parseInt(lastIdx) + 1; 
      } else if (app_idx == 0) {
        addOverviewError(i, "Application Index", "CRITICAL ERROR: Application Index cannot be 0!"); 
        lastIdx = -1
      } else if (numbers.test(app_idx) == false) {
        addOverviewError(i, "Application Index", "CRITICAL ERROR: Only number characters allowed as Indexes!");
        lastIdx = parseInt(lastIdx) + 1; 
      } else if (app_idx == 1 && lastIdx == 1) {
        addOverviewError(i, "Application Index", "CRITICAL ERROR: Flows must have at least 2 elements!");      
      } else if (app_idx == 1) {
        lastIdx = 1;

        // Check required fields for start of case
        if (ppmid == null) { addOverviewError(i, "PPMID", "Mandatory field"); } else { if (numbers.test(ppmid) == false) { temp = "Only number characters allowed"; }; if (ppmid.length > 6) { temp = temp + "\nMax Length: 6"; }; if (temp != "") { addOverviewError(i, "PPMID", temp); temp = ""; }; };
        if (project == null) { addOverviewError(i, "E2E Project Name", "Mandatory field"); } else { if (project.length > 256) { addOverviewError(i, "E2E Project Name", "Max Length: 256"); } };  
        if (casename == null) { addOverviewError(i, "E2E Test Case Name", "Mandatory field"); } else { if (caseExp.test(casename) == false) { temp = "Only AlphaNumeric and [ & , _ , - ] allowed"; }; if (casename.length > 64) { temp = temp + "\nMax Length: 64"; }; if (temp != "") { addOverviewError(i, "E2E Test Case Name", temp); temp = ""; }; };
        if (solo_case_name == null) { addOverviewError(i, "Solo Test Cases", "Mandatory field"); } else { if (caseExp.test(solo_case_name) == false) { temp = "Only AlphaNumeric and [ & , _ , - ] allowed"; }; if (solo_case_name.length > 125) { temp = temp + "\nMax Length: 125"; }; if (temp != "") { addOverviewError(i, "Solo Test Cases", temp); temp = ""; }; };        

        if (app_name == null) { addOverviewError(i, "Application Name", "Mandatory field"); } else { if (appNameExp.test(app_name) == false) { temp = "Only alphanumeric characters and [. / ( ) - : @ _ & ,] accepted..\nApp ID and App Name must also be separated by \" - \""; }; if (app_name.length > 140) { temp = temp + "\nMax Length: 140"; }; if (temp != "") { addOverviewError(i, "Application Name", temp); temp = ""; }; };
        
        //if (env_box == null) { addOverviewError(i, "Environment Box", "Mandatory field"); } else { if (env_box.length > 64) { addOverviewError(i, "Environment Box", "Max Length: 64"); } };     
        //if (biz_proc == null) { addOverviewError(i, "Biz Process/T-Code", "Mandatory field"); } else { if (biz_proc.length > 256) { addOverviewError(i, "Biz Process/T-Code", "Max Length: 256"); } };
        if (env_box != null) { if (env_box.length > 16) { addOverviewError(i, "Environment Box", "Max Length: 16"); } };     
        if (biz_proc != null) { if (biz_proc.length > 256) { addOverviewError(i, "Data Input/T-Code", "Max Length: 256"); } };

        //if (exec_type == null) { addOverviewError(i, "Execution Type", "Mandatory field"); } else { if (execTypes.test(exec_type) == false) {addOverviewError(i, "Execution Type", "Only [ Automation, Manual, Both ] allowed");} };
        //if (test_type == null) { addOverviewError(i, "Test Case Type", "Mandatory field"); } else { if (testTypes.test(test_type) == false) {addOverviewError(i, "Test Case Type", "Only [ Functional, Regression ] allowed");} };     
        
        // Set a default value for Execution Type & Test Case Type on load
        if (exec_type == null) { row["Execution Type"] = "Manual"; } else { if (execTypes.test(exec_type) == false) {addOverviewError(i, "Execution Type", "Only [ Automation, Manual, Both ] allowed");} };
        if (test_type == null) { row["Test Case Type"] = "Functional"; } else { if (testTypes.test(test_type) == false) {addOverviewError(i, "Test Case Type", "Only [ Functional, Regression ] allowed");} };     

        // Check other field lengths
        //if (portf != null) { if (portf.length > 8) { addOverviewError(i, "Portfolio", "Max Length: 8"); }; };
        //if (det_doc != null) { if (det_doc.length > 1024) { addOverviewError(i, "Reference Link", "Max Length: 1024"); }; };

        // Set a default value for owner on load
        if (owner == null) { row["Owner"] = "GRC QA Team" };
        if (owner != null) { if (owner.length > 32) { addOverviewError(i, "Owner", "Max Length: 32"); }; };
        if (key_doc != null) { if (key_doc.length > 256) { addOverviewError(i, "Key Document Type", "Max Length: 256"); }; };
        if (com_code != null) { if (com_code.length > 256) { addOverviewError(i, "Company Codes", "Max Length: 256"); }; };
      } else if (app_idx > 1) {
        // Validate that the index sequencing is correct 1,2,3...
        if (app_idx != parseInt(lastIdx) + 1 && parseInt(lastIdx) != -1) { addOverviewError(i,"Application Index", "Application Index Sequence is incorrect!\nLast index was: " + lastIdx + "\nThis index should be: " + (parseInt(lastIdx) + 1) ); lastIdx = parseInt(lastIdx) + 1;} else { lastIdx = app_idx; };

        // Confirm initial case fields are empty
        if (ppmid != null) { addOverviewError(i, "PPMID", "Field must be empty"); };
        if (project != null) { addOverviewError(i, "E2E Project Name", "Field must be empty"); };
        if (casename != null) { addOverviewError(i, "E2E Test Case Name", "Field must be empty"); };
        if (exec_type != null) { addOverviewError(i, "Execution Type", "Field must be empty"); };
        if (test_type != null) { addOverviewError(i, "Test Case Type", "Field must be empty"); };
        //if (det_doc != null) { addOverviewError(i, "Reference Link", "Field must be empty"); };
        if (owner != null) { addOverviewError(i, "Owner", "Field must be empty"); };

        // Check required fields for rest of case
        if (app_name == null) { addOverviewError(i, "Application Name", "Mandatory field"); } else { if (appNameExp.test(app_name) == false) { temp = "Only alphanumeric characters and [. / ( ) - : @ _ & ,] accepted..\nApp ID and App Name must also be separated by \" - \""; }; if (app_name.length > 140) { temp = temp + "\nMax Length: 140"; }; if (temp != "") { addOverviewError(i, "Application Name", temp); temp = ""; }; };
        //if (env_box != null) { if (env_box.length > 64) { addOverviewError(i, "Environment Box", "Max Length: 64"); } };
        //if (env_box == null) { addOverviewError(i, "Environment Box", "Mandatory field"); } else { if (env_box.length > 64) { addOverviewError(i, "Environment Box", "Max Length: 64"); } };     
        //if (biz_proc == null) { addOverviewError(i, "Biz Process/T-Code", "Mandatory field"); } else { if (biz_proc.length > 256) { addOverviewError(i, "Biz Process/T-Code", "Max Length: 256"); } };
        if (env_box != null) { if (env_box.length > 16) { addOverviewError(i, "Environment Box", "Max Length: 16"); } };   
        if (biz_proc != null) { if (biz_proc.length > 256) { addOverviewError(i, "Data Input/T-Code", "Max Length: 256"); } };

        //if (portf != null) { if (portf.length > 8) { addOverviewError(i, "Portfolio", "Max Length: 8"); }; };
        if (key_doc != null) { if (key_doc.length > 256) { addOverviewError(i, "Key Document Type", "Max Length: 256"); }; };
        if (com_code != null) { if (com_code.length > 256) { addOverviewError(i, "Company Codes", "Max Length: 256"); }; };
      }
    }

    i = i + 1;
  }) 
  //console.log(errorCells.error_data);
}

function validateStepsReqLength(json2) {
  // Validate Case Steps required fields / index 1 vs idex 2+ row differences
  //var data = json2[0];
  var temp = "";
  var i = 1;
  var lastIdx = 1;  
  json2.forEach(function(row) {
    //var casename = row["E2E Test Case Name"]
    //var app_idx = row["Application Index"]
    var app_name = row["Application Name"]
    var solo_case_name = row["Solo Test Cases Name"]
    var step_idx = row["Step Name"]
    //var process = row["Process Name"]
    var desc = row["Description"]
    var expec_res = row["Expected Result"]
    //var data = row["Data Input"]

    if (i > 0) {
      if (step_idx == null) { 
        addStepError(i, "Step Name", "CRITICAL ERROR: Mandatory field!"); 
        lastIdx = parseInt(lastIdx) + 1; 
      } else if (step_idx == 0) {
        addStepError(i, "Step Name", "CRITICAL ERROR: Step Name cannot be 0!"); 
        lastIdx = -1
      } else if (numbers.test(step_idx) == false) {
        addStepError(i, "Step Name", "CRITICAL ERROR: Only number characters allowed as Indexes!");
        lastIdx = parseInt(lastIdx) + 1; 
      } else if (step_idx == 1) {
        //if (casename == null) { addStepError(i, "E2E Test Case Name", "Mandatory field"); } else { if (caseExp.test(casename) == false) { temp = "Only AlphaNumeric and [ & , _ , - ] allowed"; }; if (casename.length > 64) { temp = temp + "\nMax Length: 64"; }; if (temp != "") { addStepError(i, "E2E Test Case Name", temp); temp = ""; }; };   
        if (app_name == null) { addStepError(i, "Application Name", "Mandatory field; when Step Name = 1"); } else { if (appNameExp.test(app_name) == false) { temp = "Only alphanumeric characters and [. / ( ) - : @ _ & ,] accepted.\nApp ID and App Name must also be separated by \" - \""; }; if (app_name.length > 140) { temp = temp + "\nMax Length: 140"; }; if (temp != "") { addStepError(i, "Application Name", temp); temp = ""; }; };
        if (solo_case_name == null) { addStepError(i, "Solo Test Cases Name", "Mandatory field"); } else { if (caseExp.test(solo_case_name) == false) { temp = "Only AlphaNumeric and [ & , _ , - ] allowed"; }; if (solo_case_name.length > 125) { temp = temp + "\nMax Length: 125"; }; if (temp != "") { addStepError(i, "Solo Test Cases Name", temp); temp = ""; }; };
        if (desc == null) { addStepError(i, "Description", "Mandatory field"); } else { if (desc.length > 2014) { addStepError(i, "Description", "Max Length: 2014"); } };   
        //if (app_idx == null) { addStepError(i, "Application Index", "Mandatory field"); } else { if (numbers.test(app_idx) == false) {addStepError(i, "Application Index", "Only number characters allowed as Ixdexes!");} };

        // Check other field lengths
        //if (process != null) { if (process.length > 125) { addStepError(i, "Process Name", "Max Length: 125"); }; };
        if (expec_res != null) { if (expec_res.length > 1024) { addStepError(i, "Expected Result", "Max Length: 1024"); }; };
        //if (data != null) { if (data.length > 512) { addStepError(i, "Data Input", "Max Length: 512"); }; };
        lastIdx = 1;
      } else if (step_idx > 1) {
        // Validate that the index sequencing is correct 1,2,3...
        if (step_idx != parseInt(lastIdx) + 1 && parseInt(lastIdx) != -1) { addStepError(i, "Step Name", "Step Name Sequence is incorrect!\nLast index was: " + lastIdx + "\nThis index should be: " + (parseInt(lastIdx) + 1) ); lastIdx = parseInt(lastIdx) + 1;} else { lastIdx = step_idx; };

        //if (casename != null) { addStepError(i, "E2E Test Case Name", "Field must be empty"); };
        //if (app_idx != null) { addStepError(i, "Application Index", "Field must be empty"); };
        if (app_name != null) { addStepError(i, "Application Name", "Field must be empty"); };
        //if (solo_case_name != null) { addStepError(i, "Solo Test Cases Name", "Field must be empty"); };                  

        if (desc == null) { addStepError(i, "Description", "Mandatory field"); } else { if (desc.length > 2014) { addStepError(i, "Description", "Max Length: 2014"); } }; 
        if (expec_res != null) { if (expec_res.length > 1024) { addStepError(i, "Expected Result", "Max Length: 1024"); } };       
        //if (process != null) { if (process.length > 125) { addStepError(i, "Process Name", "Max Length: 125"); } };             
        //if (data != null) { if (data.length > 512) { addStepError(i, "Data Input", "Max Length: 512"); } };  
      }
    }

    i = i + 1;
  }) 
  //console.log(errorStepCells.error_data);
}

function validateTableRels(json, json2){
  var found = false;
  var seq_cnt = 1;



  for (j = 0; j < json.length; j++){
    var flowRow = json[j];
    var app_nameS = flowRow["Application Name"]
    var casenameS = flowRow["Solo Test Cases"]
    //var app_idxS = flowRow["Application Index"]
    //var casenameS = flowRow["E2E Test Case Name"]
    
    if (app_nameS != "Application Name") {
      found = false;
      for (i = 0; i < json2.length; i++){
        var stepRow = json2[i];
        //var app_idx = stepRow["Application Index"]
        var app_name = stepRow["Application Name"]
        //var casename = stepRow["E2E Test Case Name"]
        var casename = stepRow["Solo Test Cases Name"]
        var step_idx = stepRow["Step Name"]
        if (step_idx == 1) {  

          if (casename == casenameS && app_name == app_nameS) {
            found = true; 
            break; 
          }

        }
      }

      // If no match then mark an error
      if (!found) {
        addOverviewError(j, "Solo Test Cases", "Table Relationship is incorrect!\n\nPlease check that this Application Name, and Solo Test Case combination exists in the Case Steps table.");
        //addStepError(i + 1, "E2E Test Case Name", "Table Relationship is incorrect!\n\nPlease check the E2E Test Case Name, Application Name, and Application Index columns match between tables.");
      }
    }
  }    
  //console.log(app_idx);

  // Check the the Sequencing is correct [1,2,3,4...1,2...1,2,3...]
  // if (app_idx == 1 && seq_cnt > 2) {
  //   seq_cnt = 1;
  // }
  // if (app_idx != seq_cnt) {
  //   addStepError(i + 1, "Application Index", "Table index is incorrect! The order should be [1,2,3,...]");
  // } else {
  //   seq_cnt++;
  // }

  // Keep track of previous row since the file format can have empty row data
  //if (casenameS != null) { lastCase = casenameS; };
  //if (casenameS == null) { casenameS = lastCase; };

  // Check for a match in the Flow table
  // if (casename == casenameS && app_idx == app_idxS && app_name == app_nameS) {
  //   found = true; 
  //   break; 
  // }
}

function checkDupeSoloCases(json){
  // var dupes = "";
  var unique_values = {};
  var list_of_values = []; 
  for (j = 0; j < json.length; j++){
    var item = json[j];
    if (item["Solo Test Cases Name"] != null) {
      if ( ! unique_values[item["Application Name"] + "," + item["Solo Test Cases Name"]] ) {
          unique_values[item["Application Name"] + "," + item["Solo Test Cases Name"]] = true;
          list_of_values.push(item["Application Name"] + "," + item["Solo Test Cases Name"]);
      } else {
          // dupes = item["Application Name"] + " : " + item["Solo Test Cases Name"] + "<br>";
          addStepError(j + 1,"Solo Test Cases Name", "Duplicate Solo Case for this Application. Please remove it from your Excel file or choose another name if it's a new case.");
      }      
    }

  }
  // return dupes;

}

function addOverviewError(i, col, detail){
  var error = new Object;

  error['row'] = i; 
  error['col'] = col; 
  error['detail'] = detail;
  errorCells.error_data.push(error); 
}

function addStepError(i, col, detail){
  var error = new Object;

  error['row'] = i; 
  error['col'] = col; 
  error['detail'] = detail;  
  errorStepCells.error_data.push(error); 
}

function enableDisablePage(enable){
  if (enable == false) {
    $('#submit_data').attr('disabled', true);
    $('#hot').css('display', 'none');
    $('#steps').css('display', 'none');
    $('#drops').val('');
    $('#drops').css('background-color',"#FFE0E0");
    $('#drop').css('background-color',"#FFE0E0");
  }else{
    $('#submit_data').attr('disabled', false);
    $('#hot').css('display', 'block');
    $('#steps').css('display', 'block');    
  } 
}


/** Drop it like it's hot **/
DropSheet({
  drop: _target,
  on: {
    workstart: _workstart,
    workend: _workend,
    sheet: _onsheet,
    foo: 'bar'
  },
  errors: {
    badfile: _badfile,
    pending: _pending,
    failed: _failed,
    large: _large,
    foo: 'bar'
  }
})
