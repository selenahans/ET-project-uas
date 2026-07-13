<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$servername = "localhost"; 
$username = "flutter_160423025"; 
$password = "ubaya"; 
$dbname = "flutter_160423025"; 
$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    echo json_encode(array(
        'result' => 'ERROR',
        'message' => 'Koneksi database gagal: ' . $conn->connect_error
    ));
    exit();
}