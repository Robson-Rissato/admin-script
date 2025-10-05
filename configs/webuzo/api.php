<html><head><title>webuzo</title></head><body>

<?php

if(isset($_GET["sess"])) {
        if(preg_match("/^[a-zA-Z0-9]+$/", $_GET["sess"]) == 1) {
		if(isset($_GET["cookie"])) {

			if(!is_numeric($_GET["cookie"])){ die('Invalid cookie'); }
			$cookie=$_GET["cookie"];
                	$sess=$_GET["sess"];
			$softcookie='SOFTCookies' . $cookie .'_sid';
                	setcookie("$softcookie", "$sess", time()+30*24*60*60, '/');
                	echo "Redirecting to webuzo $softcookie $sess";
		} else {
			echo "No cookie passed";
		}

?>
        <meta http-equiv="refresh" content="0;url=index.php">
<?php

        } else { echo "no match $sess"; }
}

?>

</body>
</html>
