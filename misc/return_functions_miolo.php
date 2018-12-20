<?php
    #
    # Author: Rafael Dutra
    # Updated: Vilson C. Gartner
    #

function lcfirst($str) 
{
    return strtolower(substr($str, 0, 1)) . substr($str, 1);
}
    
    $arr_subs = array("this", "static", "function", "{", "}", ";", "public", "private");
    $nothing  = " ";
    
    $file = file("/tmp/arq_functions.txt");
    for($i=0;$i<count($file);$i++)
    {
        $line = $file[$i];
    
        if(preg_match_all("/function/",$line,$function))
        {
            $final_str  = str_replace($arr_subs, $nothing, $line);
            //echo "<pre>";
	    // some functions we dont want...
	    $final_str = trim($final_str);

	    if ( substr($final_str, 0, 1) != '_' &&
                 substr($final_str, 0, 1) != '/' &&
		 substr($final_str, 0, 1) != '?' &&
	         substr($final_str, 0, 1) != '*' &&
 	         substr($final_str, 0, 1) != '#' &&
		 substr($final_str, 0, 1) != '$' &&
		 substr($final_str, 0, 3) != 'if ' &&
                 substr($final_str, 0, 8) != 'abstract' 
                )
	    {
		    $final_str = str_replace('& ', '', $final_str);
		    $final_str = str_replace('&', '', $final_str);

		    if ( ! in_array($final_str, $array_lines) )
                    {
	                $array_lines[] = $final_str;
                    }
    		    //print_r ("$final_str\n");
            }
            //echo "</pre>";
    	}
    }

    sort($array_lines);
    foreach( $array_lines as $line )
    {
        $line = lcfirst($line);
        print_r ("$line\n");
    }

?>
