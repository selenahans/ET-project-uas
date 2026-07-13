<?php
// Hapus baris tulisan bebas yang merusak sintaks PHP
require_once("connection.php");

if (isset($_POST['username']) && isset($_POST['password'])) {
    $username = $_POST['username'];
    $password = $_POST['password'];

    $stmt = $conn->prepare("SELECT id, username, password FROM comics_users WHERE username = ?");
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        
        if (password_verify($password, $user['password']) || $password == $user['password']) {
            echo json_encode(array(
                'result' => 'OK',
                'message' => 'Login berhasil',
                'user_id' => (int)$user['id'], // Cast ke INT agar aman di Flutter
                'username' => $user['username']
            ));
        } else {
            echo json_encode(array('result' => 'ERROR', 'message' => 'Password salah'));
        }
    } else {
        echo json_encode(array('result' => 'ERROR', 'message' => 'Username tidak ditemukan'));
    }
    $stmt->close();
} else {
    echo json_encode(array('result' => 'ERROR', 'message' => 'Parameter tidak lengkap'));
}
$conn->close();
?>