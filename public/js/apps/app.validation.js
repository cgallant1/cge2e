/*
    File used to store field validation functions for App Create page
        - Field lengths and illegal characters
        - Required fields
*/

function checkRequiredFields(){
    var arrFail = [];

    if ($('#projectid').val() == '' ){
        arrFail.push('Project ID');
    }
    if ($('#appname').val() == '' ){
        arrFail.push('App Name');
    }

    return arrFail
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

function isNumberKey(evt, obj, str){
    var charCode = (evt.which) ? evt.which : event.keyCode

    if (evt.ctrlKey == false){
        if (evt.shiftKey) {return false;}
        if (charCode > 31 && (charCode < 48 || charCode > 57)  && (charCode < 91 || charCode > 145)) {
            showNewError(obj, 'Only numeric input accepted.');
            return false;
        }
    } 

    $(obj).css('visibility', 'hidden');
    return true;
}


function duplicateDataCheck( callback ) {
    projectid = $('#projectid').val();
    appname = $('#appname').val();

    // Replace special characters
    appname = appname.replace(/\//g, "¶");
    appname = appname.replace(/\./g, "Ð");

    url = "/searchProjectID/projectid=" + projectid;
    // Check the DB to see if there is a record already with this project id
    $.getJSON(url, function(count){
         if (count > 0) {
            callback("ppmid");
         } else {
            url = "/searchAppName/appname=" + appname;
            // Check the DB to see if there is a record already with this app name
            $.getJSON(url, function(count){
                 if (count > 0) {
                    callback("appname");
                 } else { 
                    callback("ok");
                 }
            })              
         }
    })
}

function getClipboardData(e){
    // Detect CRAPPY IE
    if (navigator.userAgent.match(/msie/i) || navigator.userAgent.match(/trident/i) ){
        return window.clipboardData.getData("text");
    }else {
        return e.originalEvent.clipboardData.getData('Text'); 
    }
}

/*
* check in APP Name* field the inputing characters if meets the requirement.
* Can Accept Characters:
*    Alphabet Characters: A - Z
*    Number Characters: 0 - 9
*    Special Characters:  . / ( ) - : @ _ & ,
*/
function validCharacters(evt, obj, str){
    var keyCode = (evt.which) ? evt.which : event.keyCode
    if(evt.ctrlKey){
        return true;
    }
    if (evt.ctrlKey == false){
        if (keyCode == 16) { return true; }
        var ctrlKey = (evt.ctrlKey) ? evt.ctrlKey : false;
        var shiftKey = (evt.shiftKey) ? evt.shiftKey : false;
        if (!valid(ctrlKey, shiftKey, keyCode)) {
            showNewError(obj, 'Only alphanumeric characters and [. / ( ) - : @ _ & ,] accepted.');
            return false;
        }
    } 
    $(obj).css('visibility', 'hidden');
    return true;
}

function valid(ctrlKey, shiftKey, keyCode) {
    console.log(ctrlKey + "_" + shiftKey + "_" + keyCode);

    // click numberic key is valid
    if (!shiftKey && keyCode >= 48 &&  keyCode <= 57) {
        return true;
    }

    // click Alphabet key is valid
    if (keyCode >= 65 && keyCode <= 90) {
        return true;
    }
    
    // . !shiftKey && keyCode == 190
    // / !shiftKey && keyCode == 191
    // - !shiftKey && keyCode = 189
    // , !shiftKey && keyCode = 188
    //  click characters . / - , key is valid
    if (!shiftKey && (keyCode == 190 || keyCode == 191 || keyCode == 189 || keyCode == 188)) {
        return true;
    }

    // ( shiftKey && keyCode == 57
    // ) shiftKey && keyCode = 48
    // : shiftKey && keyCode  = 186
    // @ shiftKey && keyCode = 50
    // _ shiftKey && keyCode = 189
    // & shiftKey && keyCode = 55
    // click shift key and another key to input: ( ) : @ _ & is valid
    if (shiftKey && (keyCode == 57 || keyCode == 48 || keyCode  == 186 || keyCode == 50 || keyCode == 189 || keyCode == 55)) {
        return true;
    }

    // click Ctrl and shift key is valid
    if (keyCode == 8 || keyCode == 16) {
        return true;
    }
    
    // on numberic keyboard,the numberic key and . / * - key is valid
    if((keyCode >=96 && keyCode <=106)|| (keyCode >=109 && keyCode == 111)){
        return true;
    }

    if(keyCode == 32) {
        return true;
    }

    // All other keys is wrong input
    return false;
}



$(function(){ 

    $('#projectid').bind('paste', function(e) {
        var data = getClipboardData(e);
        var str = $('#projectid').val();

        if ($.isNumeric(data) == false)
        {
            showNewError('#ppm_warning', 'Only numeric input accepted.');
            return false;                   
        }

        $('#ppm_warning').css('visibility', 'hidden');
        return true;
    }) 

    $('#appname').bind('paste',function(e){
        var data=getClipboardData(e);
        var reg=/^([1-9]|[a-z]|[A-Z]|[\.\/\(\)\s-:@_&,])*$/;      
      // in the regular expression characters is valid,others are wrong inputing
      // input invalid the warning will be showed
      if(!reg.test(data)||data.indexOf('+')!=-1){
           showNewError('#appname_warning', 'Only alphanumeric characters and [. / ( ) - : @ _ & ,] accepted.');
           return false;
       }
       // input valid the Warninig will be hidded
       $('#appname_warning').css('visibility', 'hidden');
       return  true;
    })

}) 