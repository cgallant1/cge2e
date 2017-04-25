/*
    File used to store field validation functions for New/Edit Test Case pages
        - Field lengths and illegal characters
        - Required fields
*/

var _to_ascii = {
    '188': '44',
    '109': '45',
    '190': '46',
    '191': '47',
    '192': '96',
    '220': '92',
    '222': '39',
    '221': '93',
    '219': '91',
    '173': '45',
    '187': '61', //IE Key codes
    '186': '59', //IE Key codes
    '189': '45'  //IE Key codes
};

var shiftUps = {
    "96": "~",
    "49": "!",
    "50": "@",
    "51": "#",
    "52": "$",
    "53": "%",
    "54": "^",
    "55": "&",
    "56": "*",
    "57": "(",
    "48": ")",
    "45": "_",
    "61": "+",
    "91": "{",
    "93": "}",
    "92": "|",
    "59": ":",
    "39": "\"",
    "44": "<",
    "46": ">",
    "47": "?"
};

var lastCaseName = "";
var letters = /^[a-zA-Z0-9-_&\s]+$/;
var numbers = /^[0-9]+$/;

function getClipboardData(e){
    // Detect CRAPPY IE
    if (navigator.userAgent.match(/msie/i) || navigator.userAgent.match(/trident/i) ){
        return window.clipboardData.getData("text");
    }else {
        return e.originalEvent.clipboardData.getData('Text'); 
    }
}

function showNewError(obj, message){
    $("#tcname_warning").css('visibility', 'hidden');
    $("#ppm_warning").css('visibility', 'hidden');
    $("#project_warning").css('visibility', 'hidden');
    $("#owner_warning").css('visibility', 'hidden');
    $("#link_warning").css('visibility', 'hidden');

    if(message != "") {
      $(obj).text(message);  
    }
    $(obj).css('visibility', 'visible');
}

function checkPasteLength(obj, data, str, length){

    if (data.length + str.length > length) {
        showNewError(obj, 'Max Length exceeded = '+length+' characters');
        // $(obj).text('Max Length exceeded = '+length+' characters');
        // $(obj).css('visibility', 'visible');
        return false;
    }

    $(obj).css('visibility', 'hidden');
    return true;
}

function checkInputLength(evt, str, obj, length){
    var charCode = (evt.which) ? evt.which : event.keyCode
    var key = "";

    if (evt.ctrlKey == false){
        key = getTrueKey(evt, charCode);

        // Check field length is correct
        if (str.length >= length && charCode > 46 && (charCode < 91 || charCode > 145)) {
            return false;
        }
    }

    $(obj).css('visibility', 'hidden');  
    return true;
}

function getTrueKey(evt, charCode){
    var key = "";

    //normalize keyCode 
    if (_to_ascii.hasOwnProperty(charCode)) {
        charCode = _to_ascii[charCode];
    }

    if (!evt.shiftKey && (charCode >= 65 && charCode <= 90)) {
        key = String.fromCharCode(charCode + 32);
    } else if (evt.shiftKey && shiftUps.hasOwnProperty(charCode)) {
        //get shifted keyCode value
        key = shiftUps[charCode];
    } else {
        key = String.fromCharCode(charCode);
    }

    return key;
}

function nameFieldRules(evt, obj, str){
	var charCode = (evt.which) ? evt.which : event.keyCode
    var key = "";
       
    if (evt.ctrlKey == false){
        key = getTrueKey(evt, charCode);

        if (letters.test(key) == false && charCode > 46 && (charCode < 91 || charCode > 145)) {
            // Show the error message and cancel user input
            showNewError(obj, 'Illegal Key: Only Alphanumeric and [ & , _ , - ] allowed.');
            return false;
        }
    }        

    // Hide the error message 
	$(obj).css('visibility', 'hidden');
	return true;
}

function isNumberKey(evt, obj, str){
    var charCode = (evt.which) ? evt.which : event.keyCode

    if (evt.ctrlKey == false){
        if (evt.shiftKey) {return false;}
        if (charCode > 31 && (charCode < 48 || charCode > 57)  && (charCode < 91 || charCode > 145)) {
            showNewError(obj, 'Only numeric input accepted.');
            // $(obj).text('Only numeric input accepted.');
            // $(obj).css('visibility', 'visible');
            return false;
        }

        // Check field length
        // if (str.length >= length && charCode > 46 && (charCode < 91 || charCode > 145)) {
        //     // $(obj).text('PPM ID Length = 6 characters');
        //     // $(obj).css('visibility', 'visible');
        //     return false;
        // }

    } 

    $(obj).css('visibility', 'hidden');
    return true;
}

function checkRequiredFields(){
    var arrFail = [];
    var counter = 1;

    if ($('#test_case_name').val() == '' ){
        arrFail.push('Test Case Name');
    }
    if ($('#project_name').val() == '' ){
        arrFail.push('Project');
    }
    if ($('#ppm_id').val() == '' ){
        arrFail.push('PPM ID');
    }
    if ($('#owner').val() == '' ){
        arrFail.push('Owner');
    }
    if ($('input:radio[name=test_case_type]:checked').val() == null){
        arrFail.push('Test Case Type');
    }
    if ($('input:radio[name=exec_type]:checked').val() == null){
        arrFail.push('Execution Type');
    }

    return arrFail
}


function checkRequiredFlowFields(){
    var arrFail = [];
    counter = 1;            
    var tFlows = $('#flows').dataTable();

    $(tFlows.fnGetNodes()).each(function(){
        if ($(this).find('td').eq(3).text() == ""){

            arrFail.push(counter);
        }                   
        counter++;
    });

    return arrFail
}

function checkRequiredStepFields(){
    var arrFail = [];
    counter = 1;
    var tSteps = $('#steps').dataTable();
    var curID = "";

    $(tSteps.fnGetNodes()).each(function(){
        // if ($(this).find('td').eq(4).text() == "" || $(this).find('td').eq(6).text() == "" || $(this).find('td').eq(7).text() == "" || $(this).find('td').eq(9).text() == ""){        
        if ($(this).find('td').eq(4).text() == "" || $(this).find('td').eq(7).text() == ""){
            
            if ($(this).find('td').eq(3).text() != curID) { 
                curID = $(this).find('td').eq(3).text();
                arrFail.push("\n" + $(this).find('td').eq(3).text() + " => Rows: " + $(this).find('td').eq(5).text()); 
            } else {
                arrFail.push("," + $(this).find('td').eq(5).text());
            }

            //arrFail.push($(this).find('td').eq(3).text() + " > " + $(this).find('td').eq(5).text() + "\n");
        }                   
        //counter++;
    });

    return arrFail
}


$(function(){ 

    // $('#test_case_name').on('input',function(e){
    //     if($(this).data("lastval")!= $(this).val()){
    //         $(this).data("lastval",$(this).val());
    //         if ($('#tc_name_sect').hasClass('has-feedback')){
    //             if ($(this).val() == ''){
    //                 $('#tc_name_sect').removeClass("has-success has-feedback");
    //                 $('#tc_name_inSect').find('span').remove();
    //                 $('#tc_name_sect').addClass('has-error has-feedback');
    //                 $('#tc_name_inSect').append('<span class="glyphicon glyphicon-remove form-control-feedback"></span>');
    //             }else{
    //                 $('#tc_name_sect').removeClass("has-error has-feedback");
    //                 $('#tc_name_inSect').find('span').remove();
    //                 $('#tc_name_sect').addClass('has-success has-feedback');
    //                 $('#tc_name_inSect').append('<span class="glyphicon glyphicon-ok form-control-feedback"></span>');
    //             }
    //         }                   
    //     };
    // });

    $('#ppm_id').bind('paste', function(e) {
        var data = getClipboardData(e);
        var str = $('#ppm_id').val();

        if ($.isNumeric(data) == false)
        {
            showNewError('#ppm_warning', 'Only numeric input accepted.');
            // $('#ppm_warning').text('Only numeric input accepted.');
            // $('#ppm_warning').css('visibility', 'visible');
            return false;                   
        }

        // if (data.length + str.length  > 6) {
        //     showNewError('#ppm_warning', 'Max Length exceeded = 6 characters');
        //     // $('#ppm_warning').text('Max Length exceeded = 6 characters');
        //     // $('#ppm_warning').css('visibility', 'visible');
        //     return false;
        // }

        $('#ppm_warning').css('visibility', 'hidden');
        return true;
    })  

    $('#test_case_name').bind('paste', function(e) {
        var data = getClipboardData(e);
        var str = $('#test_case_name').val();

        if (letters.test(data) == false) {
            showNewError('#tcname_warning', 'Illegal Key: Only Alphanumeric and [ & , _ , - ] allowed.');
            // $('#tcname_warning').css('visibility', 'visible');
            return false;
        }

        // if (data.length + str.length  > 64) {
        //     showNewError('#tcname_warning', 'Max Length exceeded = 64 characters');
        //     // $('#tcname_warning').text('Max Length exceeded = 64 characters');
        //     // $('#tcname_warning').css('visibility', 'visible');
        //     return false;
        // }

        $('#tcname_warning').css('visibility', 'hidden');
        return true;
    }) 

    // $('#owner').bind('paste', function(e) {
    //     var data = getClipboardData(e);
    //     var str = $(this).val();

    //     return checkPasteLength('#owner_warning', data, str, 32);
    // })

    // $('#project_name').bind('paste', function(e) {
    //     var data = getClipboardData(e);
    //     var str = $(this).val();

    //     return checkPasteLength('#project_warning', data, str, 256);
    // })

    // $('#hyperlink').bind('paste', function(e) {
    //     var data = getClipboardData(e);
    //     var str = $(this).val();

    //     return checkPasteLength('#link_warning', data, str, 1024);
    // })

    $('#flows').on('keydown', '#portfolio',function(e){
        var str = $(this).text();

        if (checkInputLength(e, str, "", 8) == false) {
            return false;
        }
    })
    $('#flows').on('input', '#portfolio', function(e) {
        var str = $(this).text();

        if (str.length > 8) {
             $(this).html("<div style='word-break:break-word; word-wrap: break-word; vertical-align: middle;' contenteditable>" +str.substring(0,8)+ "</div>" );
        }
    })
    
    $('#flows').on('keydown', '#env',function(e){
        var str = $(this).text();

        if (checkInputLength(e, str, "", 16) == false) {
            return false;
        }
    })
    $('#flows').on('input', '#env', function(e) {
        var str = $(this).text();

        if (str.length > 16) {
             $(this).html("<div style='word-break:break-word; word-wrap: break-word; vertical-align: middle;' contenteditable>" +str.substring(0,16)+ "</div>" );
        }
    })

    $('#flows').on('keydown', '#biz_proc',function(e){
        var str = $(this).text();

        if (checkInputLength(e, str, "", 256) == false) {
            return false;
        }
    })
    $('#flows').on('input', '#biz_proc', function(e) {
        var str = $(this).text();

        if (str.length > 256) {
             $(this).html("<div style='word-break:break-word; word-wrap: break-word; vertical-align: middle;' contenteditable>" +str.substring(0,32)+ "</div>" );
        }
    })

    $('#flows').on('keydown', '#cov_type',function(e){
        var str = $(this).text();

        if (checkInputLength(e, str, "", 256) == false) {
            return false;
        }
    })
    $('#flows').on('input', '#cov_type', function(e) {
        var str = $(this).text();

        if (str.length > 256) {
            $(this).html("<div style='word-break:break-word; word-wrap: break-word; vertical-align: middle;' contenteditable>" +str.substring(0,256)+ "</div>" );
        }
    })

    $('#flows').on('keydown', '#com_code',function(e){
        var str = $(this).text();

        if (checkInputLength(e, str, "", 256) == false) {
            return false;
        }
    })
    $('#flows').on('input', '#com_code', function(e) {
        var str = $(this).text();

        if (str.length > 256) {
             $(this).html("<div style='word-break:break-word; word-wrap: break-word; vertical-align: middle;' contenteditable>" +str.substring(0,32)+ "</div>" );
        }
    })

    $('#steps').on('keydown', '#proc_name',function(e){
        var str = $(this).text();

        if (checkInputLength(e, str, "", 125) == false) {
            return false;
        }
    })
    $('#steps').on('input', '#proc_name', function(e) {
        var str = $(this).text();

        if (str.length > 125) {
             $(this).html("<div style='word-break:break-word; word-wrap: break-word; vertical-align: middle;' contenteditable>" +str.substring(0,125)+ "</div>" );
        }
    })

    $('#steps').on('keydown', '#step_desc',function(e){
        var str = $(this).text();   

        if (checkInputLength(e, str, "", 2014) == false) {
            return false;
        }
    })
    $('#steps').on('input', '#step_desc', function(e) {
        var str = $(this).text();

        if (str.length > 2014) {
             $(this).html("<div style='word-break:break-word; word-wrap: break-word; vertical-align: middle;' contenteditable>" +str.substring(0,2014)+ "</div>" );
        }
    })

    $('#steps').on('keydown', '#data_input',function(e){
        var str = $(this).text();   

        if (checkInputLength(e, str, "", 512) == false) {
            return false;
        }
    })
    $('#steps').on('input', '#data_input', function(e) {
        var str = $(this).text();

        if (str.length > 512) {
             $(this).html("<div style='word-break:break-word; word-wrap: break-word; vertical-align: middle;' contenteditable>" +str.substring(0,512)+ "</div>" );
        }
    })

    $('#steps').on('keydown', '#expec_res',function(e){
        var str = $(this).text();   

        if (checkInputLength(e, str, "", 1024) == false) {
            return false;
        }
    })
    $('#steps').on('input', '#expec_res', function(e) {
        var str = $(this).text();

        if (str.length > 1024) {
             $(this).html("<div style='word-break:break-word; word-wrap: break-word; vertical-align: middle;' contenteditable>" +str.substring(0,1024)+ "</div>" );
        }
    })   

    $('#steps').on('keydown', '#case_name',function(e){
        var str = $(this).text();

        if (e.ctrlKey == false){
            if (nameFieldRules(e, '', str, 125) == false) {
                return false;
            }            
        }
        lastCaseName = str;
    })
    $('#steps').on('input', '#case_name', function(e) {
        var str = $(this).text();

        if (letters.test(str) == false && str != "") {
            // alert(str);
            // alert(lastCaseName);
            $(this).text(lastCaseName);
        }

        // Check field length is correct
        if (str.length >= 125) {
            $(this).html("<div style='word-break:break-word; word-wrap: break-word; vertical-align: middle;' contenteditable>" +str.substring(0,125)+ "</div>" );
        }

        lastCaseName = str;
    })     
})