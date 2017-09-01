<?php
    // Author:          Peter Stone
    // Organisation:    University of Waikato
    // Department:      Library Systems Team
    // Purpose:         Acts as a simple API. Insert or displays user details associated with USB devices from data stored in a database compared to USB metadata
    // Date:            2017-04-13

    /* Configuration */
    $db_host = 'tui.liby.waikato.ac.nz';
    $db_user = 'usbuser';
    $db_password = 'example';
    /* End configuration */
?>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8"/>
        <title>USB API</title>
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta/css/bootstrap.min.css" integrity="sha384-/Y6pD6FV/Vv2HJnA6t+vslU6fwYXjCFtcEpHbNJ0lyAFsXTsjBbfaDjzALeQsN6M" crossorigin="anonymous">
    </head>
    <body>
            <nav class="navbar navbar-expand-md navbar-dark static-top bg-dark">
                <a class="navbar-brand" href="<?= strtok($_SERVER["REQUEST_URI"],'?') ?>">USB API</a>
            </nav>
<?php
    if (isset($_GET["action"]) == true){
        // Establish the database connection
        $mysqli = new mysqli($db_host, $db_user, $db_password);
        if ($mysqli->connect_error) {die('Connect Error (' . $mysqli->connect_errno . ') ' . $mysqli->connect_error);}
        
        // LOAD data    	
        if ($_GET["action"] == "loaddb") {
            // prepare and bind (Prepared statement!)
            $stmt = $mysqli->prepare("INSERT INTO usb_device.storage (serialnum, deviceid, mediatype, caption, sizebytes, computername, username, date, time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
            $stmt->bind_param("sssssssss", $serialnum, $deviceid, $mediatype, $caption, $sizebytes, $computername, $username, $date, $time);
            // set parameters and execute
            // A legacy problem for some older "rubbish" USBs is that they do not provide a sensible value in the serial number field of the WMI query
            // To avoid the issue we are only using this field if more than 2 digits are present...
            if (strlen($_GET["serialnum"]) > 2) {$serialnum = $_GET["serialnum"];} else {$serialnum = NULL;}
            $deviceid = $_GET["deviceid"];
            $mediatype = $_GET["mediatype"];
            $caption = $_GET["caption"];
            $sizebytes = $_GET["sizebytes"];
            $computername = $_GET["computername"];
            $username = $_GET["username"];
            $date = date("Y-m-d");
            $time = date("H:i:s");
            $stmt->execute();
            echo "New record created successfully";
            $stmt->close();
        }
        
        // RETURN/DISPLAY data (ALSO RECORDING SEARCH SUCCESS OR FAILURE)
        if ($_GET["action"] == "querydb") {
            // A legacy problem for some older USBs is that they do not return a sensible value in the serial number field, from the original WMI query
            // To avoid the issue, we are only using this field if more than 2 digits are present...
            if (strlen($_GET["serialnum"]) > 2) {$serialnum = $_GET["serialnum"];} else {$serialnum = NULL;}
            $deviceid = $_GET["deviceid"];
            $mediatype = $_GET["mediatype"];
            $caption = $_GET["caption"];
            $sizebytes = $_GET["sizebytes"];
?>
<div class="container pt-sm-3">
<h1>Querying the USB database</h1>

<div class="jumbotron p-sm-3">
<?php if (strlen($serialnum) > 2) { ?>
<dl>
<dt>Serial Number</dt><dd><?= $serialnum ?></dd>
<?php } ?>

<dt>Device ID</dt><dd><?= $deviceid ?></dd>
<dt>Caption</dt><dd><?= $caption ?></dd>
<dt>Reported Size <small>(not used for matching as varies between computers)</small></dt><dd><?= number_format($sizebytes) ?> bytes (<?= round(($sizebytes / 1000 / 1000 / 1000), 1, PHP_ROUND_HALF_UP) ?> GB / <?= round(($sizebytes / 1024 /1024 /1024), 1, PHP_ROUND_HALF_UP) ?> <a href="https://en.wikipedia.org/wiki/Gibibyte" target="_blank" nofollow>GiB</a>)</dd>
</dl>
</div>

<?php
            $mysqli = new mysqli($db_host, $db_user, $db_password);
            if ($mysqli->connect_error) {die('Connect Error (' . $mysqli->connect_errno . ') ' . $mysqli->connect_error);}
            // Check connection
            if ($mysqli->connect_error) {die("Connection failed: " . $mysqli->connect_error);}
            
            // Using the "incoming" variables, form the query to use in a prepared statement, adjusting the query for valid/invalid serial number. 
            // NOT using the sizebytes field as different OS's (even different version of the same OS) calculate this value differently!!!!
            if (strlen($serialnum) > 2) {
                // prepare and bind (Prepared statement!)
                $stmt = $mysqli->prepare("SELECT computername, username, fullname, date, time FROM usb_device.storage WHERE serialnum = ? AND deviceid = ? AND caption = ? ORDER BY date, time");
                $stmt->bind_param( "sss", $serialnum, $_GET["deviceid"], $caption); 
            } else {
                // prepare and bind (Prepared statement!)
                $stmt = $mysqli->prepare("SELECT computername, username, fullname, date, time FROM usb_device.storage WHERE deviceid = ? AND caption = ? ORDER BY date, time");
                $stmt->bind_param( "ss", $deviceid, $caption); 
            }
            // execute statement and bind results to it
            $stmt->execute();
            $stmt->bind_result($computername, $username, $fullname, $date, $time);
            
            // surface the values (if any) returned
            $cnt =  0;
			echo '<table class="table table-hover table-sm devicelist text-nowrap"><thead class="thead-default"><tr><th>Date</th><th>Time</th><th>Computer</th><th>Username</th><th>Full Name</th></tr></thead>';
            while ($stmt->fetch()) {
                // Intialise the $usernamecompare variable
                if ($cnt == 0) {$usernamecompare = $username;}
                // If the $usernamecompare variable should change populate the $multipleusername variable
                if ($usernamecompare != $username) {$multipleusername = "Multiple usernames dectected!";}
                // Output the user interaction details for this usb
			if ($cnt == 10) {
				echo '<tr data-toggle="collapse" data-target=".collapse" class="collapse show text-center alert-link"><td colspan="5"><a href=#">Show all records</a></td></tr>';
			}
?>
<tr class="<?= $cnt >= 10 ? "collapse" : "" ?>">
<td><?= $date ?></td>
<td><?= $time ?></td>
<td class="text-lowercase"><?= $computername ?></td>
<td class="text-lowercase"><?= $username ?></td>
<td><?= $fullname ?></td>
</tr>
<?php                
                $cnt = $cnt + 1;
            }
            $stmt->close();
			echo '</table>';

            
            // Display and record comfirmation that the USB device is NOT recorded
            if ($cnt == 0) {
?>
<div class="alert alert-danger" role="alert">No matching entries for this device were found in the database.</div>
<div class="alert alert-warning"><strong>Note</strong> Records are retained for 3 months only.</div>
<?php
                // Insert a record of this query into the usb_device.returned table - $ownership = "False"
                if (strlen($serialnum) > 2) {
                    // prepare and bind (Prepared statement!)
                    $stmt = $mysqli->prepare("INSERT INTO usb_device.returned (serialnum, deviceid, mediatype, caption, sizebytes, date, time, ownership) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
                    $stmt->bind_param("ssssssss", $serialnum, $deviceid, $mediatype, $caption, $sizebytes, $date, $time, $ownership);
                    // set parameters and execute
                    // A legacy problem for some older "rubbish" USBs is that they do not provide a sensible value in the serial number field of the WMI query
                    // To avoid the issue we are only using this field if more than 2 digits are present...
                    if (strlen($_GET["serialnum"]) > 2) {$serialnum = $_GET["serialnum"];} else {$serialnum = NULL;}
                    $deviceid = $_GET["deviceid"];
                    $mediatype = $_GET["mediatype"];
                    $caption = $_GET["caption"];
                    $sizebytes = $_GET["sizebytes"];
                    $date = date("Y-m-d");
                    $time = date("H:i:s");
                    $ownership = "False";
                    $stmt->execute();
                    $stmt->close();                        
                }
            }
            
            // Display and record comfirmation that the USB device is on record - $ownership = "True"
            if ($cnt >= 1) {
                
                // Insert a record of this query into the usb_device.returned table
                if (strlen($serialnum) > 2) {
                    // prepare and bind (Prepared statement!)
                    $stmt = $mysqli->prepare("INSERT INTO usb_device.returned (serialnum, deviceid, mediatype, caption, sizebytes, date, time, ownership) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
                    $stmt->bind_param("ssssssss", $serialnum, $deviceid, $mediatype, $caption, $sizebytes, $date, $time, $ownership);
                    // set parameters and execute
                    // A legacy problem for some older "rubbish" USBs is that they do not provide a sensible value in the serial number field of the WMI query
                    // To avoid the issue we are only using this field if more than 2 digits are present...
                    if (strlen($_GET["serialnum"]) > 2) {$serialnum = $_GET["serialnum"];} else {$serialnum = NULL;}
                    $deviceid = $_GET["deviceid"];
                    $mediatype = $_GET["mediatype"];
                    $caption = $_GET["caption"];
                    $sizebytes = $_GET["sizebytes"];
                    $date = date("Y-m-d");
                    $time = date("H:i:s");
                    $ownership = "True";
                    $stmt->execute();
                    $stmt->close();
                }
            }
            echo "<p>Query returned <strong>" . $cnt . "</strong> records</p>";
        }
        mysqli_close ($mysqli);
        echo '</div>';

    } else {
        // README - Explanation and instructions to display if there is no valid defined GET variable action (either "querydb" or "loaddb")
?>
      <div class="jumbotron">
        <div class="container">
          <h1 class="display-3">USB API documentation</h1>
          <img class="float-right px-4 ml-5" alt="USB Thumb Drive" height="300" width="300" src="data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPCEtLSBHZW5lcmF0b3I6IEFkb2JlIElsbHVzdHJhdG9yIDIxLjEuMCwgU1ZHIEV4cG9ydCBQbHVnLUluIC4gU1ZHIFZlcnNpb246IDYuMDAgQnVpbGQgMCkgIC0tPgo8c3ZnIHZlcnNpb249IjEuMSIgaWQ9IkxheWVyXzEiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiIHg9IjBweCIgeT0iMHB4IgoJIHZpZXdCb3g9IjAgMCA2OC4zIDY4LjMiIHN0eWxlPSJlbmFibGUtYmFja2dyb3VuZDpuZXcgMCAwIDY4LjMgNjguMzsiIHhtbDpzcGFjZT0icHJlc2VydmUiPgo8Zz4KCTxwYXRoIGQ9Ik05LjMsNTljMTEuNywxMS43LDE4LjUsNC4zLDE4LjUsNC4zczE3LjYtMTcuNiwxOS41LTE5LjVjMS45LTEuOSwxLjktMy45LDAuNC01LjRTMzEuNCwyMi4xLDI5LjksMjAuNgoJCWMtMS41LTEuNS0zLjUtMS41LTUuNCwwLjRDMjIuNiwyMi45LDUsNDAuNSw1LDQwLjVTLTIuNSw0Ny4zLDkuMyw1OXoiLz4KCTxwYXRoIGQ9Ik01MS4xLDAuNGMwLjYtMC42LDEuNS0wLjYsMi4xLDBsMTQuNywxNC43YzAuNiwwLjYsMC42LDEuNSwwLDIuMUw1MC4xLDM0LjljLTAuNiwwLjYtMS41LDAuNi0yLjEsMEwzMy40LDIwLjIKCQljLTAuNi0wLjYtMC42LTEuNSwwLTIuMUw1MS4xLDAuNHogTTQ4LjksMjEuN2MtMC4zLDAuMy0wLjMsMC43LDAsMWw0LjcsNC43YzAuMywwLjMsMC43LDAuMywxLDBsMi41LTIuNWMwLjMtMC4zLDAuMy0wLjcsMC0xCgkJbC00LjctNC43Yy0wLjMtMC4zLTAuNy0wLjMtMSwwTDQ4LjksMjEuN3ogTTQ2LjgsMjcuM2MtMC4xLDAuMS0wLjEsMC4zLDAsMC40bDEuOCwxLjhjMC4xLDAuMSwwLjMsMC4xLDAuNCwwbDEtMQoJCWMwLjEtMC4xLDAuMS0wLjMsMC0wLjRsLTEuOC0xLjhjLTAuMS0wLjEtMC4zLTAuMS0wLjQsMEw0Ni44LDI3LjN6IE00MS45LDIwLjVjMC4xLTAuMSwwLjEtMC4zLDAtMC40bC0xLjgtMS44CgkJYy0wLjEtMC4xLTAuMy0wLjEtMC40LDBsLTEsMWMtMC4xLDAuMS0wLjEsMC4zLDAsMC40bDEuOCwxLjhjMC4xLDAuMSwwLjMsMC4xLDAuNCwwTDQxLjksMjAuNXogTTQ5LjEsMTYuOWMwLjMtMC4zLDAuMy0wLjcsMC0xCgkJbC00LjctNC43Yy0wLjMtMC4zLTAuNy0wLjMtMSwwbC0yLjUsMi41Yy0wLjMsMC4zLTAuMywwLjcsMCwxbDQuNyw0LjdjMC4zLDAuMywwLjcsMC4zLDEsMEw0OS4xLDE2Ljl6Ii8+Cgk8cGF0aCBkPSJNNy43LDY0LjJjMC4xLDAuMSwwLjIsMC40LTAuMSwwLjdjLTAuMiwwLjItMi4xLDEuMy0zLjgtMC40Yy0xLjctMS43LTAuNi0zLjUtMC40LTMuOGMwLjItMC4yLDAuNS0wLjIsMC43LTAuMQoJCUM0LjMsNjAuNyw3LjYsNjQsNy43LDY0LjJ6IE0yLjksNTYuNGMtMi4yLDIuNi00LjYsNi44LTEuMiwxMC4yYzMuNCwzLjQsNy43LDEsMTAuMy0xLjJjMC44LTAuNywwLjItMS4yLTAuMi0xLjQKCQljLTEuMy0xLTIuNy0yLjEtNC0zLjVjLTEuMy0xLjMtMi41LTIuNy0zLjQtNEMzLjcsNTUuNiwzLjEsNTYsMi45LDU2LjR6Ii8+CjwvZz4KPC9zdmc+Cg==">
            <p class="lead">This API is for updating a database with user data and the metadata of their USB storage devices or querying the database to match a USB device metadata to a user.</p>
            <hr>
              <p>This API uses GET array variables to transfer values either INTO the database or to query FROM the database.</p>
              <p>When used in conjunction with a script that is able to interogate for metadata from a local USB device and user session, this service acts as an intermediary between the database and the user session script.</p>
              <p>Abstracting the database access details and using prepared statements within the API, means that the local script is simpler to code and the database is inherently more secure.</p>
              <p><a class="btn btn-primary btn-lg" href="https://github.com/university-of-waikato-library/usb" role="button">View on GitHub »</a> <a class="btn btn-success btn-lg" rel="nofollow" href="https://github.com/university-of-waikato-library/usb/archive/master.zip" role="button">Download .zip</a></p>
              </div>
          </div>
          <div class="container">
            <div class="row">
              <div class="col-md-6">
                <h2>Recording a device</h2>
                <p>To record a device call the API with the parameters below.</p>
                <table class="table table-sm">
                  <thead class="thead-default"><tr><th>Parameter</th><th class="text-center">Required</th><th>Comments</th></tr></thead>
                  <tr><td>action</td><td class="text-center">✓</td><td>Must be <strong>loaddb</strong></td></tr>
                  <tr><td>serialnum</td><td></td><td>Used if it is more than 2 characters</td></tr>
                  <tr><td>deviceid</td><td class="text-center">✓</td><td></td></tr>
                  <tr><td>caption</td><td class="text-center">✓</td><td></td></tr>
                  <tr><td>sizebytes</td><td></td><td></td></tr>
                  <tr><td>username</td><td class="text-center">✓</td><td></td></tr>
                  <tr><td>computername</td><td class="text-center">✓</td><td></td></tr>
                </table>
                <p>
                  <button type="button" class="btn btn-info" role="button" data-toggle="modal" data-target="#insertExample">Show example</button>
                </p>
              </div>
              <div class="col-md-6">
                <h2>Querying for devices</h2>
                <p>To query a device open the API in a browser with the parameters below.</p>
                <table class="table table-sm">
                    <thead class="thead-default"><tr><th>Parameter</th><th class="text-center">Required</th><th>Comments</th></tr></thead>
                    <tr><td>action</td><td class="text-center">✓</td><td>Must be <strong>querydb</strong></td></tr>
                    <tr><td>serialnum</td><td></td><td>Used if it is more than 2 characters</td></tr>
                    <tr><td>deviceid</td><td class="text-center">✓</td><td></td></tr>
                    <tr><td>caption</td><td class="text-center">✓</td><td></td></tr>
                    <tr><td>mediatype</td><td></td><td></td></tr>
                    <tr><td>sizebytes</td><td></td><td>Not recommended for matching as reported capacity may vary between computers</td></tr>
                </table>
                <p>
                    <button type="button" class="btn btn-info" role="button" data-toggle="modal" data-target="#queryExample">Show example</button>
                </p>
              </div>
            </div>
            <hr>
            <footer>
            <p><small>Developed and maintained by the University of Waikato <a href="http://www.waikato.ac.nz/library/about/organisation/library-teams/library-systems-team">Library Systems Team</a> © 2017. <span class="text-muted"><a href="https://thenounproject.com/term/usb-flash-drive/50441/">USB drive icon</a> created by Alexandr Cherkinsky for The Noun Project.</span></small></p>
            </footer>
            </div>
            <!-- Modals for link previews -->
            <div class="modal fade" id="insertExample" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
              <div class="modal-dialog" role="document">
                <div class="modal-content">
                  <div class="modal-header">
                    <h5 class="modal-title" id="exampleModalLabel">Example record insertion URL</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                      <span aria-hidden="true">&times;</span>
                    </button>
                  </div>
                  <div class="modal-body" style="overflow: scroll">https://<?= $_SERVER['HTTP_HOST'] . strtok($_SERVER["REQUEST_URI"],'?') ?>?<br>
                    &nbsp;&nbsp;&nbsp;<strong>action</strong>=loaddb&<br>
                    &nbsp;&nbsp;&nbsp;<strong>serialnum</strong>=6B0FA34143C9&<br>
                    &nbsp;&nbsp;&nbsp;<strong>deviceid</strong>=USBSTOR%5CDISK%26VEN_KINGSTON%26PROD_DATATRAVELER_3.0%26REV_PMAP%5C60A44C425294BF3139824519%260&<br>
                    &nbsp;&nbsp;&nbsp;<strong>caption</strong>=Kingston%20DataTraveler%203.0%20USB%20Device&<br>
                    &nbsp;&nbsp;&nbsp;<strong>sizebytes</strong>=62931617280&<br>
                    &nbsp;&nbsp;&nbsp;<strong>computername</strong>=LIBY-COG2&<br>
                    &nbsp;&nbsp;&nbsp;<strong>username</strong>=WAIKATO%5Cpstone</div>
                  <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                    <a class="btn btn-primary" href="https://library.waikato.ac.nz<?= strtok($_SERVER["REQUEST_URI"],'?') ?>?action=loaddb&serialnum=6B0FA34143C9&deviceid=USBSTOR%5CDISK%26VEN_KINGSTON%26PROD_DATATRAVELER_3.0%26REV_PMAP%5C60A44C425294BF3139824519%260&caption=Kingston%20DataTraveler%203.0%20USB%20Device&sizebytes=62931617280&computername=LIBY-COG2&username=WAIKATO%5Cpstone">Try it »</a>
                  </div>
                </div>
              </div>
            </div>

            <div class="modal fade" id="queryExample" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
                <div class="modal-dialog" role="document">
                  <div class="modal-content">
                    <div class="modal-header">
                      <h5 class="modal-title" id="exampleModalLabel">Example query URL</h5>
                      <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                      </button>
                    </div>
                    <div class="modal-body" style="overflow: scroll">https://<?= $_SERVER['HTTP_HOST'] .  strtok($_SERVER["REQUEST_URI"],'?') ?>?<br>
                        &nbsp;&nbsp;&nbsp;<strong>action</strong>=querydb&<br>
                        &nbsp;&nbsp;&nbsp;<strong>serialnum</strong>=6B0FA34143C9&<br>
                        &nbsp;&nbsp;&nbsp;<strong>deviceid</strong>=USBSTOR%5CDISK%26VEN_KINGSTON%26PROD_DATATRAVELER_3.0%26REV_PMAP%5C60A44C425294BF3139824519%260&<br>
                        &nbsp;&nbsp;&nbsp;<strong>caption</strong>=Kingston%20DataTraveler%203.0%20USB%20Device&<br>
                        &nbsp;&nbsp;&nbsp;<strong>sizebytes</strong>=62931617280</div>
                    <div class="modal-footer">
                      <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                      <a class="btn btn-primary" href="https://library.waikato.ac.nz<?= strtok($_SERVER["REQUEST_URI"],'?') ?>?action=querydb&serialnum=6B0FA34143C9&deviceid=USBSTOR%5CDISK%26VEN_KINGSTON%26PROD_DATATRAVELER_3.0%26REV_PMAP%5C60A44C425294BF3139824519%260&caption=Kingston%20DataTraveler%203.0%20USB%20Device&sizebytes=62931617280">Try it »</a>
                    </div>
                  </div>
                </div>
              </div>
<?php
}
?>
        <script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN" crossorigin="anonymous"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.11.0/umd/popper.min.js" integrity="sha384-b/U6ypiBEHpOf/4+1nzFpr53nxSS+GLCkfwBdFNTxtclqqenISfwAzpKaMNFNmj4" crossorigin="anonymous"></script>
        <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta/js/bootstrap.min.js" integrity="sha384-h0AbiXch4ZDo7tp9hKZ4TsHbi047NrKGLO3SEJAg45jXxnGIfYzk4Si90RDIqNm1" crossorigin="anonymous"></script>
        <script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN" crossorigin="anonymous"></script>
    </body>
</html>
