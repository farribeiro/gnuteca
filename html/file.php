<?php

//obtem miolo
$path       = '../';
$classPath  = '../classes';
$module     = $_REQUEST['module'];
$action     = $_REQUEST['action'];
$width      = $_REQUEST['width'];
$height     = $_REQUEST['height'];

include("$classPath/mioloconsole.class.php");

$MIOLOConsole = new MIOLOConsole();
$MIOLO = $MIOLOConsole->getMIOLOInstance($path, $module, false);
$MIOLOConsole->loadMIOLO();

//obtem business de arquivo
$MIOLO->getClass('gnuteca3', 'GnutecaBusiness');
$busFile = $MIOLO->getBusiness('gnuteca3', 'BusFile' );

//localiza o arquivo
$busFile->folder    = $_REQUEST['folder'];
$busFile->fileName  = $_REQUEST['file'];

$file = $busFile->searchFile(true);
$file = $file[0];

//define label, caso definida
$label = $_REQUEST['label'] ?  $_REQUEST['label'] : $file->basename;

if ( !file_exists($file->absolute) )
{
    die("Arquivo nao encontrado!");
}

ob_clean(); //remove echos que j� tenham sido executados

header("Pragma: public");
header("Expires: 0");
header("Cache-Control: must-revalidate, post-check=0, pre-check=0");
header("Cache-Control: private",false);
header("Content-type: $file->mimeContent");

if ( $file->type =='image' || $file->mimeContent = 'text/plain')
{
    header("Content-Disposition: inline; filename=\"$label\"");
}
else
{
    header("Content-Disposition: attachment; filename=\"$label\"");
}

//se for imagem e precisar redimensionar a l�gica � diferente
if ( ( $width || $height ) && $file->type ='image' )
{
    resizeImage($file, $width, $height, true);
}
else
{
    #header('Content-Transfer-Encoding: Binary' );
    header("Content-Length: ".filesize($file->absolute));
    readfile($file->absolute);
}

function resizeImage($file, $neededWidth, $neededHeight, $antiAlias = false)
{
    $filename = $file->absolute;

    // Carrega Imagem
    if ($file->mimeContent == 'image/jpeg')
    {
        $resultFunction = 'imagejpeg';
        $image = imagecreatefromjpeg($filename);
    }
    else if ($file->mimeContent == 'image/png')
    {
        $resultFunction = 'imagepng';
        $image = imagecreatefrompng($filename);
    }
    else if ($file->mimeContent == 'image/gif')
    {
        $resultFunction = 'imagegif';
        $image = imagecreatefromgif($filename);
    }
    else if ($file->mimeContent == 'image/bmp')
    {
        $resultFunction = 'imagewbmp';
        $image = imagecreatefromwbmp($filename);
    }

	// Pega os tamanhos originais
	$width  = imagesx($image);
	$height = imagesy($image);

	// Checa o redimensionamendo, se � feito por % ou px
	if (ereg("[0-9]{1,3}%",$neededWidth,$lixo))
    {
		$size = str_replace("%","",$neededWidth);
		settype($size, "integer");
		$percent = floatval($neededWidth);
		$percent /= 100;
		$newWidth = $width * $percent;
		$newHeight = $height * $percent;
	}
	else
    if  ( $neededWidth && !$neededHeight )
    {
		settype($neededWidth, "integer");
		$newWidth = floatval($neededWidth);
		$newHeight = $height * ($newWidth/$width);
		// Se apenas altura foi definida
	}
	else
    if ( $neededHeight && !$neededWidth )
    {
		settype($neededHeight, "integer");
		$newHeight = floatval($neededHeight);
		$newWidth  = $width * ($newHeight/$height);
		// Nova Largura e nova altura;
	}
	else
    {
		$newHeight = floatval($neededHeight);
		$newWidth = floatval($neededWidth);
	}

    $file->antiAlias    = $antiAlias;
    $file->width        = $width;
    $file->height       = $height;
    $file->newWidth     = $newWidth;
    $file->newHeight    = $newHeight;

    if ( $file->mimeContent == 'image/jpeg' )
    {
        $source = imagecreatefromjpeg($file->absolute);
        $thumb  = imagecreatetruecolor( $file->newWidth, $file->newHeight );

        if ($file->antiAlias == false)
        {
            imagecopyresized($thumb, $source, 0, 0, 0, 0, $file->newWidth, $file->newHeight, $file->width, $file->height );
        }
        else
        {
            imagecopyresampled($thumb, $source, 0, 0, 0, 0, $file->newWidth, $file->newHeight, $file->width, $file->height );
        }

        header("Content-type: {$file->mimeContent}");
        header("Content-Disposition: inline; filename={$file->absolute}"); //se por attachament ele abre o download
        imagejpeg($thumb, null, 100);
    }
    else
    if ( $file->mimeContent == 'image/png' )
    {
        $source = imagecreatefrompng($file->absolute);
        $file->trueColor = imageistruecolor($source);

        if ( $file->trueColor)
        {
            $thumb  = imagecreatetruecolor( $file->newWidth, $file->newHeight );
            imagealphablending($thumb, false);
            imagesavealpha  ( $thumb  , true );

            if ( $file->type == 'indexed')
            {
                imagetruecolortopalette  ( $source  ,  true , 256 );
            }
        }
        else
        {
            $thumb  = imagecreate( $file->newWidth, $file->newHeight );
            imagealphablending( $thumb, false );
            $transparent = imagecolorallocatealpha( $thumb, 0, 0, 0, 127 );
            imagefill( $thumb, 0, 0, $transparent );
            imagesavealpha( $thumb,true );
            imagealphablending( $thumb, true );
        }

        if ($file->antiAlias == false)
        {
            imagecopyresized($thumb, $source, 0, 0, 0, 0, $file->newWidth, $file->newHeight, $file->width, $file->height );
        }
        else
        {
            imagecopyresampled($thumb, $source, 0, 0, 0, 0, $file->newWidth, $file->newHeight, $file->width, $file->height );
        }

        imagepng($thumb);
    }
    else
    {
        $image_resized = imagecreatetruecolor($file->newWidth, $file->newHeight);
        imagecopyresampled($image_resized, $image, 0, 0, 0, 0, $file->newWidth, $file->newHeight, $width, $height);
        //Display resized image
        $resultFunction($image_resized);
    }

	imagedestroy($image_resize);
    imagedestroy($thumb);
    imagedestroy($source);
}
?>