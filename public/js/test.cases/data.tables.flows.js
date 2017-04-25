/*
	Data Table Definition and functions- Flows
*/

function searchApp(x){
    var value=document.getElementById(x).value

    // Replace special characters
    value = value.replace(/\//g, "¶");
    value = value.replace(/\./g, "Ð");
    
    if (value==""){
        url = "/viewfullapplist"
    }else
    {
        url = "/submitjson/"+value
    }
    $.getJSON(url,function(data){
        $("#info").html("");
        $.each(data,function(i, item){
            $("#info").append(
                '<li class="list-group-item" id="'+item.id+':'+item.project_id+' - '+item.app_name+'" onclick=markSelect(this)>'+item.project_id+' - '+item.app_name+'</li>'
                );  
        })
    })
} 

function countAffectedSteps(){
    var seqid; 
    var tSteps = $('#steps').dataTable();
    var numAffected = 0;
    var dataTable = $('#flows').dataTable();

    $(dataTable.fnGetNodes()).filter(':has(:checkbox:checked)').each(function(index, value) {
        seqid = $(value).find('#seq_id').text();

        $(tSteps.fnGetNodes()).each(function(index, secValue){
            if ($(secValue).find('td').eq(2).text() == seqid) {  
                numAffected += 1;
            }
        });
    });
    return numAffected;
 }

 function countAffectedStepsByID(seqid){
    var tSteps = $('#steps').dataTable();
    var numAffected = 0;

    $(tSteps.fnGetNodes()).each(function(){
        if ($(this).find('td').eq(2).text() == seqid) {  
            numAffected += 1;
        }
    });

    return numAffected;
 }

$(function(){
    var currProduct;
    var currAppID;
    var currVal;
    var currAdd;
    var currSeqID;

	var tFlows = $('#flows').DataTable({
		"bFilter": true,
		"paging":   true,
        "ordering": false,
        "info":     true,
		"order": [[ 0, "asc" ]],
        "columnDefs": [{
                "targets": [ 0 ],
                "visible": true,
                "searchable": false,
                "orderable": false,
                "width": 1,
            },{
                "targets": [ 2 ],
                "width": "7.2%",
            },{
                "targets": [ 3 ],
                "width": "20%",
            },{
                "targets": [ 4 ],
                "width": "8%",
            },{
                "targets": [ 5 ],
                "width": "10%",
            },{
                "targets": [ 6 ],
                "width": "14%",
            },{
                "targets": [ 7 ],
                "width": "22%",
            },{
                "targets": [ 8 ],
                "width": "9%",
            },{
                "targets": [ 9 ],
                "width": "7%",
            },{
                "targets": [ 10 ],
                 "searchable": false,
            }				            
        ]        		
	});

    $('#addFlowRow').on( 'click', function(){
        // Sort the table to be sure before doing anything
        tFlows.order( [ 2, 'asc' ] ).draw(false);

        var dataTable = $('#flows').dataTable();
        var arrN = dataTable.fnGetNodes();
        var lastRow = arrN[arrN.length - 1];
        var nextRow = 1;
        var addDiv = "<div style='word-break:break-word; word-wrap: break-word; vertical-align: middle;' contenteditable></div>";

        // Auto-Step
        if (arrN.length > 0){ nextRow = parseInt($(lastRow).find('td').eq(2).text()) + 1; }else{ nextRow = 1; }
        tFlows.row.add( [    
            "<input type='checkbox'>",
            "", nextRow,"<button type='button' id='search_product' class='btn btn-info btn-xs pull-right' style='margin:2px;'>Search</button>",
            addDiv, addDiv, addDiv, addDiv, addDiv, 
            "<button type='button' id='addStepRow' class='btn btn-info btn-xs disabled' style='margin:2px;'>Add</button>",""
        ]);
        tFlows.draw(false);

        var dataTable = $('#flows').dataTable();
        var arrN = dataTable.fnGetNodes();
        var lastRow = arrN[arrN.length - 1];

        $(lastRow).find('td').eq(1).attr('id','id');
        $(lastRow).find('td').eq(2).attr('id','seq_id');
        $(lastRow).find('td').eq(3).attr('id','product');
        $(lastRow).find('td').eq(4).attr('id','portfolio');
        $(lastRow).find('td').eq(5).attr('id','env');
        $(lastRow).find('td').eq(6).attr('id','biz_proc');
        $(lastRow).find('td').eq(7).attr('id','cov_type');
        $(lastRow).find('td').eq(8).attr('id','com_code');
        $(lastRow).find('td').eq(9).attr('id','add_step');
        $(lastRow).find('td').eq(10).attr('id','app_id');

        //Find the last row, make id and app_id invisible
        $(lastRow).find('td').eq(3).css('line-height','30px');
        $(lastRow).find('td').eq(1).css('display','none');
        $(lastRow).find('td').eq(10).css('display','none'); 
        $(lastRow).find('td').eq(0).css('text-align','center');
        $(lastRow).find('td').eq(2).css('text-align','center');
        $(lastRow).find('td').eq(4).css('text-align','center');
        $(lastRow).find('td').eq(9).css('text-align','center');

        // Align all text and controls to the middle of the row vertically
        $(lastRow).find('td').each(function() {
            $(this).css('vertical-align','middle');
        });

        // $(lastRow).find('td').eq(0).css('vertical-align','middle');
        // $(lastRow).find('td').eq(2).css('vertical-align','middle');
        // $(lastRow).find('td').eq(3).css('vertical-align','middle');
        // $(lastRow).find('td').eq(4).css('vertical-align','middle');
        // $(lastRow).find('td').eq(5).css('vertical-align','middle');
        // $(lastRow).find('td').eq(6).css('vertical-align','middle');
        // $(lastRow).find('td').eq(7).css('vertical-align','middle');
        // $(lastRow).find('td').eq(8).css('vertical-align','middle');
        // $(lastRow).find('td').eq(9).css('vertical-align','middle');
        $(lastRow).find('td').eq(4).attr('contenteditable','true');
        $(lastRow).find('td').eq(5).attr('contenteditable','true');
        $(lastRow).find('td').eq(6).attr('contenteditable','true'); 
        $(lastRow).find('td').eq(7).attr('contenteditable','true');
        $(lastRow).find('td').eq(8).attr('contenteditable','true');                
    })  

    $('#deleteFlowRow').on( 'click', function(){
        var row;
        var sRow;
        var seqid; 
        var tSteps = $('#steps').dataTable();
        var deleteRow;
        var lastSeq;
        var numAffected = 0;

        // Count the number of effected steps
        numAffected = countAffectedSteps();
        if (numAffected > 0) {
            BootstrapDialog.show({
                type: BootstrapDialog.TYPE_DANGER,
                title: 'Confirm Flow Modification!',
                message: 'Removing elements of this flow will require removal of the linked steps.\n\nDo you want to continue?',
                buttons: [{
                    label: 'Yes',
                    cssClass: 'btn-danger',
                    action: function(dialogItself) {
                        dialogItself.close();
                        var dtFlows = $('#flows').dataTable();

                        $(dtFlows.fnGetNodes()).filter(':has(:checkbox:checked)').each(function(index, value) {
                            seqid = $(value).find('#seq_id').text();
                            row = tFlows.row($(value));
                            row.remove().draw(false);          

                            // Go through the step table delete any that have the same seqid as what we just removed
                            $(tSteps.fnGetNodes()).each(function(index, secValue){
                                if ($(secValue).find('td').eq(2).text() == seqid) {  
                                    //alert($(secValue).find('td').eq(2).text());       
                                    //tSteps.row($(secValue)).remove().draw();
                                    //$(secValue).remove();
                                    deleteRow = $(secValue).find('td').eq(0);
                                    $(deleteRow).find('input').prop( "checked", true );
                                }
                                $('#deleteStepRow').trigger('click');
                            });

                        }); 

                        // Sort again by SeqID after deletion
                        tFlows.order( [ 2, 'asc' ] ).draw(false);

                        // Make id invisible; auto-step id
                        // Renumber the steps seqid appropriately        
                        var counter = 1;
                        var dataTable = $('#flows').dataTable();
                        $(dataTable.fnGetNodes()).each(function(){
                            lastSeq = $(this).find('td').eq(2).text(); 
                            $(this).find('td').eq(2).text(counter);                     

                            $(tSteps.fnGetNodes()).each(function(index, secValue){
                                if ($(secValue).find('td').eq(2).text() == lastSeq) {
                                    $(secValue).find('td').eq(2).text(counter);
                                }  
                            });
                            counter++;
                        }); 

                        //uncheck the checkbox if all the flows are deleted --- Joseph
                        if ($(($('#flows').dataTable()).fnGetNodes()).filter(':has(:checkbox:checked)').length==0){
                            $('#checkAllProduct').prop("checked",false);
                        }                            
                    }
                }, {
                    label: 'No',
                    cssClass: 'btn-danger',
                    action: function(dialogItself){
                        dialogItself.close();
                    }
                }]
            });
        }else{

            // $('#flows tr').filter(':has(:checkbox:checked)').each(function(index, value) {
            //     row = tFlows.row($(value));
            //     row.remove().draw();         
            // }); 

            // Auto-step id
            // Renumber the steps seqid appropriately        
            var counter = 1;
            var dataTable = $('#flows').dataTable();

            $(dataTable.fnGetNodes()).filter(':has(:checkbox:checked)').each(function(index, value) {
                row = tFlows.row($(value));
                row.remove().draw(false);         
            }); 

            $(dataTable.fnGetNodes()).each(function(){
                lastSeq = $(this).find('td').eq(2).text(); 
                $(this).find('td').eq(2).text(counter);                     
                counter++;
            }); 
        }

        //set the checkbox unchecked if all the flows are deleted --- Joseph
        if ($(($('#flows').dataTable()).fnGetNodes()).filter(':has(:checkbox:checked)').length==0){
            $('#checkAllProduct').prop("checked",false);
        }                          
    })

    $('#flows_wrapper div.dataTables_filter input ').click(function () {
        var dataTable = $('#flows').dataTable();
        var divStart = "<div style='word-break:break-word; word-wrap: break-word; vertical-align: middle;' contenteditable>";
        var divEnd = "</div>";
        var checked = "<input type='checkbox' checked>";
        var unchecked = "<input type='checkbox'>";

        $(dataTable.fnGetNodes()).each(function(){
            // Create an array of data and update (ALL ROWS!!!!!!!!)
            var arrVals = [];
            $(this).find("td").each(function(){
                if (arrVals.length == 0) {
                    if ($(this).find('input').is(':checked')){
                        arrVals.push(checked);
                    }else{
                        arrVals.push(unchecked);
                    }
                }else{
                    // alert($(this)text());
                    arrVals.push($(this).html()); 
                }
            });

            // Get rid of junk data and add buttons
            // arrVals[3] = removeProductJunkData(arrVals[3]);
            // arrVals[3] = arrVals[3] + "<button type='button' id='search_product' class='btn btn-info btn-xs pull-right' style='margin:2px;'>Search</button>";
            // if ($(this).find('#addStepRow').hasClass('disabled')){
            //     arrVals[9] = "<button type='button' id='addStepRow' class='btn btn-info btn-xs disabled' style='margin:2px;'>Add</button>";
            // }else{
            //     arrVals[9] = "<button type='button' id='addStepRow' class='btn btn-info btn-xs' style='margin:2px;'>Add</button>";
            // }

            // Update Rows  
            dataTable.fnUpdate([arrVals[0],arrVals[1],arrVals[2],arrVals[3],divStart + arrVals[4] + divEnd,divStart + arrVals[5] + divEnd,divStart + arrVals[6] + divEnd,divStart + arrVals[7] + divEnd,divStart + arrVals[8] + divEnd,arrVals[9],arrVals[10]], $(this), null,false);

            // dataTable.fnUpdate(arrVals[2], $(this), 2, false );
            // dataTable.fnUpdate(arrVals[3], $(this), 3, false );
            // dataTable.fnUpdate(divStart + arrVals[4] + divEnd, $(this), 4, false );
            // dataTable.fnUpdate(divStart + arrVals[5] + divEnd, $(this), 5, false );
            // dataTable.fnUpdate(divStart + arrVals[6] + divEnd, $(this), 6, false );
            // dataTable.fnUpdate(divStart + arrVals[7] + divEnd, $(this), 7, false );
            // dataTable.fnUpdate(divStart + arrVals[8] + divEnd, $(this), 8, false );
            // dataTable.fnUpdate(arrVals[9], $(this), 9, false );
            // dataTable.fnUpdate(arrVals[10], $(this), 10, false );
        });
        //dataTable.fnDraw();
    })

    $("#flows thead").click(function() {
        var dataTable = $('#flows').dataTable();
        var divStart = "<div style='word-break:break-word; word-wrap: break-word; vertical-align: middle;' contenteditable>";
        var divEnd = "</div>";
        var checked = "<input type='checkbox' checked>";
        var unchecked = "<input type='checkbox'>";

        $(dataTable.fnGetNodes()).each(function(){
            // Create an array of data and update (ALL ROWS!!!!!!!!)
            var arrVals = [];
            $(this).find("td").each(function(){
                if (arrVals.length == 0) {
                    if ($(this).find('input').is(':checked')){
                        arrVals.push(checked);
                    }else{
                        arrVals.push(unchecked);
                    }
                }else{
                    //alert($(this).text());
                    // arrVals.push($(this).text());  
                    arrVals.push($(this).html());                   
                }
            });

            // Get rid of junk data and add buttons
            // arrVals[3] = removeProductJunkData(arrVals[3]);
            // arrVals[3] = arrVals[3] + "<button type='button' id='search_product' class='btn btn-info btn-xs pull-right' style='margin:2px;'>Search</button>";
            // if ($(this).find('#addStepRow').hasClass('disabled')){
            //     arrVals[9] = "<button type='button' id='addStepRow' class='btn btn-info btn-xs disabled' style='margin:2px;'>Add</button>";
            // }else{
            //     arrVals[9] = "<button type='button' id='addStepRow' class='btn btn-info btn-xs' style='margin:2px;'>Add</button>";
            // }          

            // Update Rows 
            dataTable.fnUpdate([arrVals[0],arrVals[1],arrVals[2],arrVals[3],divStart + arrVals[4] + divEnd,divStart + arrVals[5] + divEnd,divStart + arrVals[6] + divEnd,divStart + arrVals[7] + divEnd,divStart + arrVals[8] + divEnd,arrVals[9],arrVals[10]], $(this), null,false); 
            // dataTable.fnUpdate(arrVals[2], $(this), 2, false );
            // dataTable.fnUpdate(arrVals[3], $(this), 3, false );
            // dataTable.fnUpdate(divStart + arrVals[4] + divEnd, $(this), 4, false );
            // dataTable.fnUpdate(divStart + arrVals[5] + divEnd, $(this), 5, false );
            // dataTable.fnUpdate(divStart + arrVals[6] + divEnd, $(this), 6, false );
            // dataTable.fnUpdate(divStart + arrVals[7] + divEnd, $(this), 7, false );
            // dataTable.fnUpdate(divStart + arrVals[8] + divEnd, $(this), 8, false );
            // dataTable.fnUpdate(arrVals[9], $(this), 9, false );
            // dataTable.fnUpdate(arrVals[10], $(this), 10, false );
        });
        //dataTable.fnDraw();
    })

    $('#flows').on('click','#search_product',function(){
        currProduct = $(this).parent();
        currAppID =  $(this).closest('tr').find('#app_id');
        currSeqID = $(this).closest('tr').find('#seq_id').text();
        currVal = removeProductJunkData(currProduct.text());
        currAdd = $(this).closest('tr').find('#add_step').find('#addStepRow');


        // NEED TO CHOOSE THE OLD VALUE
        // Clear the selected value
        // if (currAppID.text() == ""){
        //  $('#info').children().removeClass("active");
        // }

        $('#myModal').modal('toggle');
    })

    $('#info').on('click', 'li', function(){
        // Mark the selection & set the value in the flow table
        $(this).addClass("active").siblings().removeClass("active");
        //$(temp).val(this.id);

        var data = this.id;
        var arr = data.split(':');
        // Product
        $(currProduct).html(arr[1] + "<button type='button' id='search_product' class='btn btn-info btn-xs pull-right' style='margin:2px;'>Search</button>");
        // App id
        $(currAppID).text(arr[0]);
    })

    $('#info').on('dblclick', 'li', function(){
        var tSteps = $('#steps').dataTable();
        var deleteRow;

        // Mark the selection & set the value in the flow table
        $(this).addClass("active").siblings().removeClass("active");
        //$(temp).val(this.id);

        var data = this.id;
        var arr = data.split(':');

        // if value <> newValue
        //    prompt + delete
        if (currVal != arr[1] && countAffectedStepsByID(currSeqID) > 0){

            BootstrapDialog.show({
                type: BootstrapDialog.TYPE_DANGER,
                title: 'Confirm Flow Modification!',
                message: 'Changing elements of this flow will require removal of the linked steps.\n\nDo you want to continue?',
                buttons: [{
                    label: 'Yes',
                    cssClass: 'btn-danger',
                    action: function(dialogItself) {
                        dialogItself.close();       

                        // Go through the step table delete any that have the same seqid as what we just removed
                        $(tSteps.fnGetNodes()).each(function(index, secValue){
                            if ($(secValue).find('td').eq(2).text() == currSeqID) {  
                                deleteRow = $(secValue).find('td').eq(0);
                                $(deleteRow).find('input').prop( "checked", true );
                            }
                            $('#deleteStepRow').trigger('click');
                        });
                        // Product
                        $(currProduct).html(arr[1] + "<button type='button' id='search_product' class='btn btn-info btn-xs pull-right' style='margin:2px;'>Search</button>");
                        // App id
                        $(currAppID).text(arr[0]);

                        // Enable the Add step button after a product is selected
                        $(currAdd).removeClass('disabled');
                        $('#select_product').trigger('click');
                    }
                }, {
                    label: 'No',
                    cssClass: 'btn-danger',
                    action: function(dialogItself){
                        dialogItself.close();
                        
                        $('#clear_product').trigger('click');
                    }
                }]
            });
        }else{
            // Product
            $(currProduct).html(arr[1] + "<button type='button' id='search_product' class='btn btn-info btn-xs pull-right' style='margin:2px;'>Search</button>");
            // App id
            $(currAppID).text(arr[0]);

            // Enable the Add step button after a product is selected
            $(currAdd).removeClass('disabled');
            $('#select_product').trigger('click');
        }
    })

    $('#select_product').click(function(){
        var tSteps = $('#steps').dataTable();
        var deleteRow;

        // Enable the Add step button after a product is selected
        if ($(currAppID).text() != "")
        {
            if (countAffectedStepsByID(currSeqID) > 0){

                BootstrapDialog.show({
                    type: BootstrapDialog.TYPE_DANGER,
                    title: 'Confirm Flow Modification!',
                    message: 'Changing elements of this flow will require removal of the linked steps.\n\nDo you want to continue?',
                    buttons: [{
                        label: 'Yes',
                        cssClass: 'btn-danger',
                        action: function(dialogItself) {
                            dialogItself.close();       

                            // Go through the step table delete any that have the same seqid as what we just removed
                            $(tSteps.fnGetNodes()).each(function(index, secValue){
                                if ($(secValue).find('td').eq(2).text() == currSeqID) {  
                                    deleteRow = $(secValue).find('td').eq(0);
                                    $(deleteRow).find('input').prop( "checked", true );
                                }
                                $('#deleteStepRow').trigger('click');
                            });

                            // Enable the Add step button after a product is selected
                            $(currAdd).removeClass('disabled');
                        }
                    }, {
                        label: 'No',
                        cssClass: 'btn-danger',
                        action: function(dialogItself){
                            dialogItself.close();

                            $('#info li').siblings().removeClass("active");
                            $('#clear_product').trigger('click');
                        }
                    }]
                });
            }else{
                // Enable the Add step button after a product is selected
                $(currAdd).removeClass('disabled');
            }
        }
    })

    // Clear Product values when user cancels
    $('#clear_product').click(function(){
        $(currProduct).html(currVal + "<button type='button' id='search_product' class='btn btn-info btn-xs pull-right' style='margin:2px;'>Search</button>");
        $(currAppID).text("");
    })
    $('#close_modal').click(function(){
        $(currProduct).html(currVal + "<button type='button' id='search_product' class='btn btn-info btn-xs pull-right' style='margin:2px;'>Search</button>");
        $(currAppID).text("");
    })      

})