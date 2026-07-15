<?php
header("Content-Type: application/json");
require_once("connection.php");

$user_id = $_GET['user_id'];

$sql = "
SELECT cb.id, cb.judul, cb.poster, cb.views, cb.rating_avg, h.last_read
FROM comics_reading_history h
INNER JOIN comics_books cb
ON cb.id = h.comic_id
WHERE h.user_id = ?
AND cb.status='Published'
ORDER BY h.last_read DESC
LIMIT 10
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i",$user_id);
$stmt->execute();

$result = $stmt->get_result();
$data = [];

while($row = $result->fetch_assoc()){
    $data[] = $row;
}

echo json_encode([
    "result"=>"OK",
    "data"=>$data
]);
?>