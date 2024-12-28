terraform {
  backend "pg" {
    conn_str    = "postgres://terraform:terraform@192.168.88.69:5432/terraform?sslmode=disable"
    schema_name = "backblaze"
  }
}
