Miolo.prototype.grid =
{
	check : function (chkRow, checkboxId)
	{
       var tr = miolo.getElementById('row' + checkboxId);
       if (chkRow.checked)
       {
          if (tr.className=='row1')
             tr.className='row1checked';
          else if (tr.className=='row2')
             tr.className='row2checked';
          else if (tr.className=='row0')
             tr.className='row0checked';
       }
       else
       {
          if (tr.className=='row1checked')
             tr.className='row1';
          else if (tr.className=='row2checked')
             tr.className='row2';
          else if (tr.className=='row0checked')
             tr.className='row0';
       }
    }

	,
	
	checkAll: function (chkAll, n, gridname)
	{
    	checked = chkAll.checked ? true : false;
    	
    	for( var i=0; i < n; i++ )
    	{
    		var chkRow = miolo.getElementById('select'+ gridname +'[' + i + ']');
          
    		if (chkRow)
    		{
    			chkRow.checked = checked;
    		}
       } 
    },
	checkEachRow: function (n, gridname)
	{
       for ( var i=0; i < n; i++ )
       {
          var chkRow = miolo.getElementById('select'+ gridname +'[' + i + ']');
          miolo.grid.check(chkRow, gridname +'[' + i + ']');
       } 
    }
    
    ,
    
	ajustSelect: function (className)
	{

    }
    ,
    
	ajustTHead: function ()
	{

	}
}
