package main

import (
	"fmt"
	"net/http"

	"database/sql"
	"log"

	_ "github.com/lib/pq"
)

const (
	// TODO fill this in directly or through environment variable
	// Build a DSN e.g. postgres://username:password@url.com:5432/dbName
	DB_DSN = "postgres://postgres:pgadmin@db:5432/test_db?sslmode=disable"
)

type User struct {
	ID       int
	Email    string
	Password string
}

func main() {
	http.HandleFunc("/", index)

	http.ListenAndServe(":8081", nil)
}

func index(rw http.ResponseWriter, req *http.Request) {
	fmt.Fprintf(rw, "Go Lang Application is Running \n")

	// Create DB pool
	db, err := sql.Open("postgres", DB_DSN)
	if err != nil {
		log.Fatal("Failed to open a DB connection: ", err)
	}
	defer db.Close()

	userSql := "SELECT id, email, password FROM users"
	rows, err := db.Query(userSql)
	if err != nil {
		log.Fatal("Failed to execute query: ", err)
	}

	for rows.Next() {
		var myUser User
		rows.Scan(&myUser.ID, &myUser.Email, &myUser.Password)
		fmt.Fprintf(rw, "User ID %d, Email %s Pasword %s \n", myUser.ID, myUser.Email, myUser.Password)
	}
}