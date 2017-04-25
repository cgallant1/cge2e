define(['./Drawing', 'underscore', '../util'], function (Drawing, _, util) {
    "use strict";
    var Chart = function () {
        this.id = _.uniqueId('Chart');
        this.chartId = util.uniqueId('Chart');   
		this.chartName = null;
		this.x = 0;
		this.y = 0;
		this.cx = 0;
		this.cy = 0;
		this.uri = 'http://schemas.openxmlformats.org/drawingml/2006/chart';
		this.rid = '';
    };
	Chart.prototype = new Drawing();
	
    _.extend(Chart.prototype, {
        setChartOffset: function (x,y) {
            this.x = x;
			this.y = y;
        },		
        setChartName: function (name) {
            this.chartName = name;
        },	
        setRelationshipId: function (rId) {
            this.rId = rId;
        },
        getMediaType: function () {
            return 'chart';
        },
        getMediaData: function () {
            return [['1','2']];
        },
        toXML: function (xmlDoc) {
            var chartNode = util.createElement(xmlDoc, 'xdr:graphicFrame');

            var nonVisibleProperties = util.createElement(xmlDoc, 'xdr:nvGraphicFramePr');
            
            var nameProperties = util.createElement(xmlDoc, 'xdr:cNvPr', [
                ['id', this.chartId],
                ['name', this.chartName]
            ]);		
            nonVisibleProperties.appendChild(nameProperties);
				
            var nvChartProperties = util.createElement(xmlDoc, 'xdr:cNvGraphicFramePr');
            nonVisibleProperties.appendChild(nvChartProperties);
            chartNode.appendChild(nonVisibleProperties);
			
            var transform2d = util.createElement(xmlDoc, 'a:xfrm');	
            transform2d.appendChild(util.createElement(xmlDoc, 'a:off', [
                ['x', this.x ],
                ['y', this.y ]
            ]));
            transform2d.appendChild(util.createElement(xmlDoc, 'a:ext', [
                ['cx', this.cx ],
                ['cy', this.cy ]
            ]));	
			chartNode.appendChild(transform2d);
			
			var graphNode = util.createElement(xmlDoc, 'a:graphic');	
            var graphData = util.createElement(xmlDoc, 'a:graphicData', [
                ['uri', this.uri]
            ]);	
            var chart = util.createElement(xmlDoc, 'c:chart', [
                ['xmlns:c', this.uri],
				['xmlns:r', util.schemas.relationships],
				['r:id', this.rId]
            ]);	
			graphData.appendChild(chart);
			graphNode.appendChild(graphData);
			chartNode.appendChild(graphNode);

			// <xdr:graphicFrame macro="">
			// 	 <xdr:nvGraphicFramePr>
			// 		<xdr:cNvPr id="2" name="Chart 1" />
			// 		<xdr:cNvGraphicFramePr />
			// 	 </xdr:nvGraphicFramePr>
			// 	 <xdr:xfrm>
			// 		<a:off x="0" y="0" />
			// 		<a:ext cx="0" cy="0" />
			// 	 </xdr:xfrm>
			// 	 <a:graphic>
			// 		<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/chart">
			// 		   <c:chart xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" r:id="rId1" />
			// 		</a:graphicData>
			// 	 </a:graphic>
			// </xdr:graphicFrame>			
         
            return this.anchor.toXML(xmlDoc, chartNode);
        }       
    });
    return Chart;
});