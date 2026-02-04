<?php
// Tu cadena de conexión (Lo ideal es que esto venga de getenv('DATABASE_URL'))
$databaseUrl = "postgresql://postgres:sNqOAoQsYMPmGjOHkoZIzIqqklMMQexa@postgres.railway.internal:5432/railway";

// Parseamos la URL para extraer los componentes
$dbConfig = parse_url($databaseUrl);

// Extraemos los datos necesarios
$host   = $dbConfig['host'];
$user   = $dbConfig['user'];
$pass   = $dbConfig['pass'];
$port   = $dbConfig['port'] ?? 5432; // Puerto por defecto de Postgres
$dbname = ltrim($dbConfig['path'], '/');

// Construimos el DSN (Data Source Name)
$dsn = "pgsql:host=$host;port=$port;dbname=$dbname";

try {
    // Creamos la conexión PDO
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);

    echo "<h1>Conexión exitosa a PostgreSQL</h1>";

    // Consultamos la tabla 'users' que crea tu script init.sql
    $stmt = $pdo->query("SELECT id, name FROM users");
    $users = $stmt->fetchAll();

    if ($users) {
        echo "<h3>Cuentas de usuarios:</h3><ul>";
        foreach ($users as $user) {
            echo "<li>ID: " . $user['id'] . " - Nombre: " . htmlspecialchars($user['name']) . "</li>";
        }
        echo "</ul>";
    } else {
        echo "<p>No hay usuarios en la tabla.</p>";
    }

} catch (PDOException $e) {
    echo "<h1>Error de conexión</h1>";
    echo "<p>" . $e->getMessage() . "</p>";
}
