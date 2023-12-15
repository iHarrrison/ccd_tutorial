<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Harrison Dickens - LANDING</title>
    <style>
        body, html {
            height: 100%;
            margin: 0;
            font-family: Arial, sans-serif;
            box-sizing: border-box;
        }

        body {
            display: flex;
            justify-content: center;
            align-items: center;
            background-color: rgb(185, 92, 92);
        }

        .logo-container {
            text-align: center;
        }

        .logo {
            color: white;
            font-size: 2em;
        }
    </style>
</head>
<body>
    <?php
    // Database configuration
    $servername = "db-mysqlserver"; 
    $username = "mysqladmin";     
    $password = "ThisIsAPassword123!";
    $dbname = "db-mysql";

    // Create connection
    $conn = new mysqli($servername, $username, $password, $dbname);

    // Check connection
    if ($conn->connect_error) {
        die("Connection failed: " . $conn->connect_error);
    } else {
        echo "<div class='logo-container'>";
        echo "<img src='https://i.postimg.cc/kg2M0TF3/logo.png' alt='Logo'>";
        echo "<h1 class='logo'>HARRISON DICKENS</h1>";
        echo "<p>Connected to database successfully.</p>";
        echo "</div>";
    }

    // Close connection
    $conn->close();
    ?>
</body>
</html>