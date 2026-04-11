docker exec -it adminer php -r "
\$conn = new mysqli('mariadb', 'MYSQL_USER_ICI', 'MYSQL_PASSWORD_ICI', 'MYSQL_DATABASE_ICI');
echo \$conn->connect_error ? 'ERREUR: ' . \$conn->connect_error : 'CONNEXION OK';
"
