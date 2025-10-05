<?php


     	$whoami=`whoami`;
        echo 'I am ' . $whoami;
        $ls=shell_exec('ls /tmp');
        $test=shell_exec('touch /phpmmdrop/hi');
        $test2=shell_exec('ls /phpmmdrop');
?>
<pre>
<?php
     	echo 'ls ' . $ls;
        echo " \n";

        echo 'test2 ' . $test2;
?>
<pre>
<?php
	phpinfo();

?>

