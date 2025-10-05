rule Atomicorp_asp_file : webshell {
	meta:
		description = "Laudanum Injector Tools - file file.asp"
		author = "Michael Shinn"
		date = "2016-01-06"
	strings:
		$s1 = "' *** Written by Tim Medin <tim@counterhack.com>" fullword ascii
		$s2 = "Response.BinaryWrite(stream.Read)" fullword ascii
		$s3 = "Response.Write(Response.Status & Request.ServerVariables(\"REMOTE_ADDR\"))" fullword ascii /* PEStudio Blacklist: strings */
		$s4 = "%><a href=\"<%=Request.ServerVariables(\"URL\")%>\">web root</a><br/><%" fullword ascii /* PEStudio Blacklist: strings */
		$s5 = "set folder = fso.GetFolder(path)" fullword ascii
		$s6 = "Set file = fso.GetFile(filepath)" fullword ascii
	condition:
		uint16(0) == 0x253c and filesize < 30KB and 5 of them
}

rule Atomicorp_php_killnc : webshell {
	meta:
		description = "Laudanum Injector Tools - file killnc.php"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s1 = "if ($_SERVER[\"REMOTE_ADDR\"] == $IP)" fullword ascii /* PEStudio Blacklist: strings */
		$s2 = "header(\"HTTP/1.0 404 Not Found\");" fullword ascii
		$s3 = "<?php echo exec('killall nc');?>" fullword ascii /* PEStudio Blacklist: strings */
		$s4 = "<title>Laudanum Kill nc</title>" fullword ascii /* PEStudio Blacklist: strings */
		$s5 = "foreach ($allowedIPs as $IP) {" fullword ascii
	condition:
		filesize < 15KB and 4 of them
}

rule Atomicorp_asp_shell : webshell {
	meta:
		description = "Laudanum Injector Tools - file shell.asp"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s1 = "<form action=\"shell.asp\" method=\"POST\" name=\"shell\">" fullword ascii /* PEStudio Blacklist: strings */
		$s2 = "%ComSpec% /c dir" fullword ascii /* PEStudio Blacklist: strings */
		$s3 = "Set objCmd = wShell.Exec(cmd)" fullword ascii /* PEStudio Blacklist: strings */
		$s4 = "Server.ScriptTimeout = 180" fullword ascii /* PEStudio Blacklist: strings */
		$s5 = "cmd = Request.Form(\"cmd\")" fullword ascii /* PEStudio Blacklist: strings */
		$s6 = "' ***  http://laudanum.secureideas.net" fullword ascii
		$s7 = "Dim wshell, intReturn, strPResult" fullword ascii /* PEStudio Blacklist: strings */
	condition:
		filesize < 15KB and 4 of them
}

rule Atomicorp_settings : webshell {
	meta:
		description = "Laudanum Injector Tools - file settings.php"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s1 = "Port: <input name=\"port\" type=\"text\" value=\"8888\">" fullword ascii /* PEStudio Blacklist: strings */
		$s2 = "<li>Reverse Shell - " fullword ascii /* PEStudio Blacklist: strings */
		$s3 = "<li><a href=\"<?php echo plugins_url('file.php', __FILE__);?>\">File Browser</a>" ascii /* PEStudio Blacklist: strings */
	condition:
		filesize < 13KB and all of them
}

rule Atomicorp_asp_proxy : webshell {
	meta:
		description = "Laudanum Injector Tools - file proxy.asp"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s1 = "'response.write \"<br/>  -value:\" & request.querystring(key)(j)" fullword ascii /* PEStudio Blacklist: strings */
		$s2 = "q = q & \"&\" & key & \"=\" & request.querystring(key)(j)" fullword ascii /* PEStudio Blacklist: strings */
		$s3 = "for each i in Split(http.getAllResponseHeaders, vbLf)" fullword ascii
		$s4 = "'urlquery = mid(urltemp, instr(urltemp, \"?\") + 1)" fullword ascii /* PEStudio Blacklist: strings */
		$s5 = "s = urlscheme & urlhost & urlport & urlpath" fullword ascii /* PEStudio Blacklist: strings */
		$s6 = "Set http = Server.CreateObject(\"Microsoft.XMLHTTP\")" fullword ascii /* PEStudio Blacklist: strings */
	condition:
		filesize < 50KB and all of them
}

rule Atomicorp_cfm_shell : webshell {
	meta:
		description = "Laudanum Injector Tools - file shell.cfm"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s1 = "Executable: <Input type=\"text\" name=\"cmd\" value=\"cmd.exe\"><br>" fullword ascii /* PEStudio Blacklist: strings */
		$s2 = "<cfif ( #suppliedCode# neq secretCode )>" fullword ascii /* PEStudio Blacklist: strings */
		$s3 = "<cfif IsDefined(\"form.cmd\")>" fullword ascii
	condition:
		filesize < 20KB and 2 of them
}

rule Atomicorp_aspx_shell  : webshell{
	meta:
		description = "Laudanum Injector Tools - file shell.aspx"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s1 = "remoteIp = HttpContext.Current.Request.Headers[\"X-Forwarded-For\"].Split(new" ascii /* PEStudio Blacklist: strings */
		$s2 = "remoteIp = Request.UserHostAddress;" fullword ascii /* PEStudio Blacklist: strings */
		$s3 = "<form method=\"post\" name=\"shell\">" fullword ascii /* PEStudio Blacklist: strings */
		$s4 = "<body onload=\"document.shell.c.focus()\">" fullword ascii /* PEStudio Blacklist: strings */
	condition:
		filesize < 20KB and all of them
}

rule Atomicorp_php_shell  : webshell{
	meta:
		description = "Laudanum Injector Tools - file shell.php"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s1 = "command_hist[current_line] = document.shell.command.value;" fullword ascii /* PEStudio Blacklist: strings */
		$s2 = "if (e.keyCode == 38 && current_line < command_hist.length-1) {" fullword ascii /* PEStudio Blacklist: strings */
		$s3 = "array_unshift($_SESSION['history'], $command);" fullword ascii /* PEStudio Blacklist: strings */
		$s4 = "if (preg_match('/^[[:blank:]]*cd[[:blank:]]*$/', $command)) {" fullword ascii /* PEStudio Blacklist: strings */
	condition:
		filesize < 40KB and all of them
}

rule Atomicorp_php_reverse_shell : webshell {
	meta:
		description = "Laudanum Injector Tools - file php-reverse-shell.php"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s1 = "$process = proc_open($shell, $descriptorspec, $pipes);" fullword ascii /* PEStudio Blacklist: strings */
		$s2 = "printit(\"Successfully opened reverse shell to $ip:$port\");" fullword ascii /* PEStudio Blacklist: strings */
		$s3 = "$input = fread($pipes[1], $chunk_size);" fullword ascii /* PEStudio Blacklist: strings */
	condition:
		filesize < 15KB and all of them
}

rule Atomicorp_php_dns  : webshell{
	meta:
		description = "Laudanum Injector Tools - file dns.php"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s1 = "$query = isset($_POST['query']) ? $_POST['query'] : '';" fullword ascii /* PEStudio Blacklist: strings */
		$s2 = "$result = dns_get_record($query, $types[$type], $authns, $addtl);" fullword ascii /* PEStudio Blacklist: strings */
		$s3 = "if ($_SERVER[\"REMOTE_ADDR\"] == $IP)" fullword ascii /* PEStudio Blacklist: strings */
		$s4 = "foreach (array_keys($types) as $t) {" fullword ascii
	condition:
		filesize < 15KB and all of them
}

rule Atomicorp_WEB_INF_web  : webshell{
	meta:
		description = "Laudanum Injector Tools - file web.xml"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s1 = "<servlet-name>Command</servlet-name>" fullword ascii /* PEStudio Blacklist: strings */
		$s2 = "<jsp-file>/cmd.jsp</jsp-file>" fullword ascii
	condition:
		filesize < 1KB and all of them
}

rule Atomicorp_jsp_cmd : webshell {
	meta:
		description = "Laudanum Injector Tools - file cmd.war"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s0 = "cmd.jsp}" fullword ascii
		$s1 = "cmd.jspPK" fullword ascii
		$s2 = "WEB-INF/web.xml" fullword ascii /* Goodware String - occured 1 times */
		$s3 = "WEB-INF/web.xmlPK" fullword ascii /* Goodware String - occured 1 times */
		$s4 = "META-INF/MANIFEST.MF" fullword ascii /* Goodware String - occured 12 times */
	condition:
		uint16(0) == 0x4b50 and filesize < 2KB and all of them
}

rule Atomicorp_laudanum : webshell {
	meta:
		description = "Laudanum Injector Tools - file laudanum.php"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s1 = "public function __activate()" fullword ascii
		$s2 = "register_activation_hook(__FILE__, array('WP_Laudanum', 'activate'));" fullword ascii /* PEStudio Blacklist: strings */
	condition:
		filesize < 5KB and all of them
}

rule Atomicorp_php_file  : webshell{
	meta:
		description = "Laudanum Injector Tools - file file.php"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s1 = "$allowedIPs =" fullword ascii /* PEStudio Blacklist: strings */
		$s2 = "<a href=\"<?php echo $_SERVER['PHP_SELF']  ?>\">Home</a><br/>" fullword ascii /* PEStudio Blacklist: strings */
		$s3 = "$dir  = isset($_GET[\"dir\"])  ? $_GET[\"dir\"]  : \".\";" fullword ascii
		$s4 = "$curdir .= substr($curdir, -1) != \"/\" ? \"/\" : \"\";" fullword ascii
	condition:
		filesize < 10KB and all of them
}

rule Atomicorp_warfiles_cmd : webshell {
	meta:
		description = "Laudanum Injector Tools - file cmd.jsp"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s1 = "Process p = Runtime.getRuntime().exec(request.getParameter(\"cmd\"));" fullword ascii /* PEStudio Blacklist: strings */
		$s2 = "out.println(\"Command: \" + request.getParameter(\"cmd\") + \"<BR>\");" fullword ascii /* PEStudio Blacklist: strings */
		$s3 = "<FORM METHOD=\"GET\" NAME=\"myform\" ACTION=\"\">" fullword ascii
		$s4 = "String disr = dis.readLine();" fullword ascii
	condition:
		filesize < 2KB and all of them
}

rule Atomicorp_asp_dns  : webshell{
	meta:
		description = "Laudanum Injector Tools - file dns.asp"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s1 = "command = \"nslookup -type=\" & qtype & \" \" & query " fullword ascii /* PEStudio Blacklist: strings */
		$s2 = "Set objCmd = objWShell.Exec(command)" fullword ascii /* PEStudio Blacklist: strings */
		$s3 = "Response.Write command & \"<br>\"" fullword ascii /* PEStudio Blacklist: strings */
		$s4 = "<form name=\"dns\" method=\"POST\">" fullword ascii /* PEStudio Blacklist: strings */
	condition:
		filesize < 21KB and all of them
}

rule Atomicorp_php_reverse_shell_2  : webshell{
	meta:
		description = "Laudanum Injector Tools - file php-reverse-shell.php"
		author = "Michael Shinn"
		
		date = "2016-01-06"
	strings:
		$s1 = "$process = proc_open($shell, $descriptorspec, $pipes);" fullword ascii /* PEStudio Blacklist: strings */
		$s7 = "$shell = 'uname -a; w; id; /bin/sh -i';" fullword ascii /* PEStudio Blacklist: strings */
	condition:
		filesize < 10KB and all of them
}

rule Atomicorp_php_anuna
{
    meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "Catches a PHP Trojan"
    strings:
        $a = /<\?php \$[a-z]+ = '/
        $b = /\$[a-z]+=explode\(chr\(\([0-9]+[-+][0-9]+\)\)/
        $c = /\$[a-z]+=\([0-9]+[-+][0-9]+\)/
        $d = /if \(!function_exists\('[a-z]+'\)\)/
    condition:
        all of them
}
rule Atomicorp_php_in_image
{
    meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "Finds image files w/ PHP code in images"
    strings:
        $gif = /^GIF8[79]a/
        $jfif = { ff d8 ff e? 00 10 4a 46 49 46 }
        $png = { 89 50 4e 47 0d 0a 1a 0a }

        $php_tag = "<?php"
    condition:
        (($gif at 0) or
        ($jfif at 0) or
        ($png at 0)) and

        $php_tag
}
rule Atomicorp_chinese_spam_spreader : webshell
{
    meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "Catches chinese PHP spam files (autospreaders)"
    strings:
        $a = "User-Agent: aQ0O010O"
        $b = "<font color='red'><b>Connection Error!</b></font>"
        $c = /if ?\(\$_POST\[Submit\]\) ?{/
    condition:
        all of them
}

rule Atomicorp_chinese_spam_echoer : webshell
{
    meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "Catches chinese PHP spam files (printers)"
    strings:
        $a = "set_time_limit(0)"
        $b = "date_default_timezone_set('PRC');"
        $c = "$Content_mb;"
        $d = "/index.php?host="
    condition:
        all of them
}
rule Atomicorp_php_webshell : webshell
{
    meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "Obfuscated PHP webshell"
    strings:
        $a = "eval(\"\\x65\\x76\\x61\\x6C\\x28\\x67\\x7A\\x69\\x6E\\x66\\x6C\\x61"
        $b = "yc0CJYb+O//Xgj9/y+U/dd//vkf'\\x29\\x29\\x29\\x3B\")"
    condition:
        all of them
}
rule Atomicorp_generic_malicious_php_rce_loader : Malware
{
meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "PHP RCE Loader Detection"

strings:
        $rce_loader = /eval\(\"if\(isset\(\\\$_REQUEST.*md5\(.*isset\(\\\$_REQUEST\['.*eval\(\\\$_REQUEST.*exit\(/i

condition:
        $rce_loader
}
rule Atomicorp_php_injektor : Malware
{
    meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "Obfuscated PHP webshell"
    strings:
        $a = "safem0de = @ini_get"
        $b = "Upload Success"
    condition:
        all of them
}

rule Atomicorp_php_obfuscated_malware_2 : Malware
{
    meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "Obfuscated PHP webshell"
    strings:
        $a = "<?php //"
        $b = "__FILE__"
        $c = /eval ?\(\$/i
        $d = /\" ?\) ?\) ?\) ?:/
        $e = /==\" ?\) ?\) ?\) ?\) ?\;/
    condition:
        all of them
}

rule Atomicorp_php_obfuscated_malware_3 : Malware
{
    meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "Obfuscated PHP webshell"
    strings:
        $a = "= mail(base64_decode("
        $b = "base64_decode("
        $c = "base64_decode("
    condition:
        all of them
}

rule Atomicorp_php_obfuscated_malware_4 : Malware
{
    meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "Obfuscated PHP webshell"
    strings:
        $eval_ob = /eval\(\$[A-Za-z0-9]+\(\$[A-Za-z0-9]+\(\$[A-Za-z0-9]+\(/
    condition:
        $eval_ob
}
rule Atomicorp_php_obfuscated_malware_5 : Malware
{
    meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "Obfuscated PHP webshell"
    strings:
        $a = "fwrite($fp,base64_decode("
        $b = "$fp=fopen"
        $c = "fclose($fp);"

    condition:
        all of them
}
rule Atomicorp_php_obfuscated_malware_6 : Malware
{
    meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "Obfuscated PHP webshell"
    strings:
        $a = "<? $GLOBALS"
        $b = "'),base64_decode('"
        $c = "fclose($fp);"

    condition:
        all of them
}
rule Atomicorp_php_upload_shell_2 : Malware
{
    meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "Obfuscated PHP webshell"
    strings:
        $a = "if(isset($_GET["
        $b = ".php_uname"
        $c = "@ini_get"
        $d = "@copy($_FILES"
        $e = "if($_POST"

    condition:
        all of them
}
rule Atomicorp_php_upload_shell_3 : Malware
{
    meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "Obfuscated PHP malware"
    strings:
        $a =  /= \"chr\";/
        $b =  /= \"strlen\";/
        $c =  /= \"strpos\";/
        $d =  /= \"substr\";/
        $d =  /= \"base64_decode\";/
        $d =  /= \"gzinflate\";/


    condition:
        all of them
}
rule Atomicorp_php_upload_shell_4 : Malware
{
    meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "Obfuscated PHP malware"
    strings:
        $encoded_eval =  /\$[a-zA-Z0-9]+\(@\$[a-zA-Z0-9]+\(@\$[a-zA-Z0-9]+\(\$_POST/

    condition:
        $encoded_eval
}
rule Atomicorp_php_upload_shell_5 : Malware
{
    meta:
        author = "Michael Shinn"
        date = "2016-01-06"
        description = "Obfuscated PHP malware"
    strings:
        $a =  /function [a-zA-Z0-9]+\(\$[a-zA-Z0-9]+, \$[a-zA-Z0-9]+/
	$b =  /\$[a-zA-Z0-9]+ .= isset\(\$[a-zA-Z0-9]+/
	$c =  /return base64_decode\(\$[a-zA-Z0-9]+/
	$d =  /for \(\$[a-zA-Z0-9]+ = 0; \$[a-zA-Z0-9]+ < strlen\(\$[a-zA-Z0-9]+\)/

    condition:
        all of them
}
