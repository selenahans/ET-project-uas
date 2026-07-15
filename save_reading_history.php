<?php
header("Content-Type: application/json");
require_once("connection.php");

$user_id = $_POST['user_id'];
$comic_id = $_POST['comic_id'];

$cek = $conn->prepare("SELECT id FROM comics_reading_history WHERE user_id=? AND comic_id=?");
$cek->bind_param("ii",$user_id,$comic_id);
$cek->execute();
$hasil = $cek->get_result();

if($hasil->num_rows>0){
    $row = $hasil->fetch_assoc();

    $update = $conn->prepare(" UPDATE comics_reading_history SET last_read=NOW() WHERE id=?");
    $update->bind_param("i",$row['id']);
    $update->execute();

}else{
    $insert = $conn->prepare("
        INSERT INTO comics_reading_history(user_id,comic_id,last_read)
        VALUES(?,?,NOW())");
    $insert->bind_param("ii",$user_id,$comic_id);
    $insert->execute();
}

echo json_encode([
    "result"=>"OK"
]);
?>