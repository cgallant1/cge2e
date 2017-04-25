/*
	Data Table Definition and functions- Steps
*/

function findCaseNameToCopy(seqid){
	var dataTable = $('#steps').dataTable();
	var arrN = dataTable.fnGetNodes();
	var name = "";

	$(arrN).each(function(){
		if ($(this).closest('tr').find('#seq_id').text() == seqid && name == "") {
			// Return the Case Name
			name = $(this).find('#case_name').text();
		}
	});
	return name;
}

function findNextStep(seqid){
    var dataTable = $('#steps').dataTable();
    var arrN = dataTable.fnGetNodes();
    var stepNum = -1;

    $(arrN).each(function(){
        if ($(this).closest('tr').find('#seq_id').text() == seqid) {
            // Return the Case Name
            stepNum = parseInt($(this).find('#step_id').text());
        }
    });

    return stepNum;
}

function updateStepTableDOM(){
    var dataTable = $('#steps').dataTable();
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
                arrVals.push($(this).html());                   
            }
        });

        dataTable.fnUpdate([arrVals[0],arrVals[1],arrVals[2],arrVals[3],divStart + arrVals[4] + divEnd,arrVals[5],divStart + arrVals[6] + divEnd,divStart + arrVals[7] + divEnd,divStart + arrVals[8] + divEnd,divStart + arrVals[9] + divEnd,arrVals[10],arrVals[11]], $(this), null,false);          
    });
}

$(function(){			

	var tSteps = $('#steps').DataTable({
		"bFilter": true,
		"paging":   true,
        "ordering": true,
        "info":     true,
		"order": [[ 2, "asc" ]],
        "columnDefs": [{
                "targets": [ 0 ],
                "visible": true,
                "searchable": false,
                "orderable": false,
                "width": 1,
            },{
                "targets": [ 1 ],
                "searchable": false,
            },{
                "targets": [ 2 ],
                "searchable": false,
            },{
                "targets": [ 3 ],
                "width": "11%",
                "orderable": false,
            },{
                "targets": [ 4 ],
                "width": "15%",
                "orderable": false,
            },{
                "targets": [ 5 ],
                "width": "7.2%",
                "orderable": false,
            },{
                "targets": [ 6 ],
                "width": "12.5%",
                "orderable": false,
            },{
                "targets": [ 7 ],
                "width": "20%",
                "orderable": false,
            },{
                "targets": [ 8 ],
                "width": "12%",
                "orderable": false,
            },{
                "targets": [ 9 ],
                "width": "20%",
                "orderable": false,
            },{
                "targets": [ 10 ],
            },{
                "targets": [ 11 ],
                "searchable": false,
            }				            
        ]        		
	});

    $('#flows').on('click','#addStepRow',function(){
        var dataTable = $('#steps').dataTable();
        var arrN = dataTable.fnGetNodes();
        var lastRow = arrN[arrN.length - 1];
        var nextRow = 1;
        var caseName = "";
        var addDiv = "<div style='word-break:break-word; word-wrap: break-word; vertical-align: middle;' contenteditable></div>";
        var addDivHalf = "<div style='word-break:break-word; word-wrap: break-word; vertical-align: middle;' contenteditable>";

        // Update the DOM to be sure we have the most recent data in memory
        updateStepTableDOM();

        // Get the product value for this row
        product = $(this).closest('tr').find('#product').text();
        product = removeProductJunkData(product);
        //arrProd = product.split('-');
        //product = arrProd[1].trim();

        // Get the app id that represents the product
        appid = $(this).closest('tr').find('td:last').text();
        seqid = $(this).closest('tr').find('#seq_id').text();

        // Auto-Step
        if (arrN.length > 0){ nextRow = parseInt(findNextStep(seqid) + 1); }else{ nextRow = 1; }
        // Case Name Copy
        if (nextRow != 1){ caseName = findCaseNameToCopy(seqid); } else { caseName = ""; }

        tSteps.row.add( [ "<input type='checkbox'>","",seqid,product,addDivHalf + caseName + "</div>",nextRow,addDiv,addDiv,addDiv,addDiv,addDiv,appid ] ).order( [ 2, 'asc' ], [5, 'asc'] ).draw(false); 

        // Apply sorting and reapply 
        // var dataTable = $('#steps').dataTable();
        // tSteps.order( [ 2, 'asc' ] ).draw();
        var counter = 1;
        seqid = -1;

        $(dataTable.fnGetNodes()).each(function(){
            if ($(this).find('td').eq(1).css('display') != 'none') {
                $(this).find('td').eq(1).attr('id','id');
                $(this).find('td').eq(2).attr('id','seq_id');
                $(this).find('td').eq(3).attr('id','product');
                $(this).find('td').eq(4).attr('id','case_name');
                $(this).find('td').eq(5).attr('id','step_id');
                $(this).find('td').eq(6).attr('id','proc_name');
                $(this).find('td').eq(7).attr('id','step_desc');
                $(this).find('td').eq(8).attr('id','data_input');
                $(this).find('td').eq(9).attr('id','expec_res');
                $(this).find('td').eq(10).attr('id','memo');
                $(this).find('td').eq(11).attr('id','app_id');

		        // Align all text and controls to the middle of the row vertically
		        $(this).find('td').each(function() {
		            $(this).css('vertical-align','middle');
		        });

                $(this).find('td').eq(0).css('text-align','center');
                $(this).find('td').eq(5).css('text-align','center');                
                $(this).find('td').eq(1).css('display','none');
                $(this).find('td').eq(2).css('display','none');
                $(this).find('td').eq(10).css('display','none');
                $(this).find('td').eq(11).css('display','none');
                $(this).find('td').eq(4).attr('contenteditable','true');
                $(this).find('td').eq(6).attr('contenteditable','true');
                $(this).find('td').eq(7).attr('contenteditable','true');
                $(this).find('td').eq(8).attr('contenteditable','true');
                $(this).find('td').eq(9).attr('contenteditable','true');
                $(this).find('td').eq(10).attr('contenteditable','true');                       
            }

            // Auto-step by Group
            if ($(this).find('#seq_id').text() == seqid){
                //Continue numbering
                // alert('new start: ' + counter);  
                $(this).find('#step_id').text(counter);
            }else{
                //Restart
                counter = 1;
                // Highlight the first row of a solocase
                $(this).css('background-color', '#F0F2FF');
                $(this).css('font-weight', 'bold'); 

                seqid = $(this).find('#seq_id').text();
                $(this).find('#step_id').text(counter);
            }
            counter += 1;
        });
    }) 

	$('#deleteStepRow').on( 'click', function(){
		var row; 
        var dataTable = $('#steps').dataTable();

        // Update the DOM to be sure we have the most recent data in memory
        updateStepTableDOM();
                
        $(dataTable.fnGetNodes()).filter(':has(:checkbox:checked)').each(function(index, value) {
            row = tSteps.row($(value));
            row.remove().draw(false);         
        }); 

	    // Apply sorting and reapply 
		// var dataTable = $('#steps').dataTable();
		tSteps.order( [ 2, 'asc' ] ).draw(false);
		var counter = 1;
		seqid = -1;

		$(dataTable.fnGetNodes()).each(function(){
			// Auto-step by Group
			if ($(this).find('#seq_id').text() == seqid){
				//Continue numbering
				$(this).find('#step_id').text(counter);
			}else{
				//Restart
				counter = 1;
                // Highlight the first row of a solocase
                $(this).css('background-color', '#F0F2FF');
                $(this).css('font-weight', 'bold'); 

				seqid = $(this).find('#seq_id').text();
				$(this).find('#step_id').text(counter);
			}
			counter += 1;
		});	
        //unckeck the checkbox when all the steps are deleted --- Joseph
        if ($($('#steps').dataTable().fnGetNodes()).filter(':has(:checkbox:checked)').length==0){
            $('#checkAllEdit').prop("checked",false);
        }                    
	})

	$('#steps_wrapper div.dataTables_filter input ').click(function () {
		var dataTable = $('#steps').dataTable();
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
                    arrVals.push($(this).html());                     
                }
			});
				
            dataTable.fnUpdate([arrVals[0],arrVals[1],arrVals[2],arrVals[3],divStart + arrVals[4] + divEnd,arrVals[5],divStart + arrVals[6] + divEnd,divStart + arrVals[7] + divEnd,divStart + arrVals[8] + divEnd,divStart + arrVals[9] + divEnd,arrVals[10],arrVals[11]], $(this), null,false);                					
			
   //          dataTable.fnUpdate(arrVals[2], $(this), 2, false );
			// dataTable.fnUpdate(arrVals[3], $(this), 3, false );
			// dataTable.fnUpdate(divStart + arrVals[4] + divEnd, $(this), 4, false );
			// dataTable.fnUpdate(arrVals[5], $(this), 5, false );
			// dataTable.fnUpdate(divStart + arrVals[6] + divEnd, $(this), 6, false );
			// dataTable.fnUpdate(divStart + arrVals[7] + divEnd, $(this), 7, false );
			// dataTable.fnUpdate(divStart + arrVals[8] + divEnd, $(this), 8, false );
			// dataTable.fnUpdate(divStart + arrVals[9] + divEnd, $(this), 9, false );
			// dataTable.fnUpdate(arrVals[10], $(this), 10, false );
		});
		//dataTable.fnDraw();
	})

	$("#steps thead").click(function() {
		var dataTable = $('#steps').dataTable();
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
                    arrVals.push($(this).html());                     
                }
			});

            dataTable.fnUpdate([arrVals[0],arrVals[1],arrVals[2],arrVals[3],divStart + arrVals[4] + divEnd,arrVals[5],divStart + arrVals[6] + divEnd,divStart + arrVals[7] + divEnd,divStart + arrVals[8] + divEnd,divStart + arrVals[9] + divEnd,arrVals[10],arrVals[11]], $(this), null,false); 
									
			// dataTable.fnUpdate(arrVals[2], $(this), 2, false );
			// dataTable.fnUpdate(arrVals[3], $(this), 3, false );
			// dataTable.fnUpdate(arrVals[4], $(this), 4, false );
			// dataTable.fnUpdate(arrVals[5], $(this), 5, false );
			// dataTable.fnUpdate(arrVals[6], $(this), 6, false );
			// dataTable.fnUpdate(arrVals[7], $(this), 7, false );
			// dataTable.fnUpdate(arrVals[8], $(this), 8, false );
			// dataTable.fnUpdate(arrVals[9], $(this), 9, false );
			// dataTable.fnUpdate(arrVals[10], $(this), 10, false );
		});
		//dataTable.fnDraw();
	})

	$("#steps").on("keyup","tr #case_name",function(e){
		var dataTable = $('#steps').dataTable();
		var appid = $(this).closest('tr').find('td:last').text();
        var seqid = $(this).closest('tr').find('#seq_id').text();
		var name = $(this).text();
		var stepid = $(this).closest('tr').find('#step_id').text();

		// Copy the Case name across all the group rows
		$(dataTable.fnGetNodes()).each(function(){
			if ($(this).closest('tr').find('#seq_id').text() == seqid && $(this).closest('tr').find('#step_id').text() != stepid) {
				$(this).find('#case_name').text(name);
			}

		});
	})
})