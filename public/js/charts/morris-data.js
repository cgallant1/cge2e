// Morris.js Charts sample data for SB Admin template

$(function() {

    // Bar Chart
    chart = Morris.Bar({
        element: 'morris-bar-chart',
        data: [],
        columnH: 'label',
        xkey: 'device',
        ykeys: ['count'],
        labels: ['Related Projects'],
        barRatio: 0.4,
        xLabelAngle: 35,
        hideHover: 'auto',
        resize: true
    });


});
