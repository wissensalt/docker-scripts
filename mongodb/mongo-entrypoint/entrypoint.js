var db = connect("mongodb://admin:password@localhost:27017/admin");

db = db.getSiblingDB('tix_member_external'); // we can not use "use" statement here to switch db

db.createUser(
    {
        user: "user",
        pwd: "password",
        roles: [ { role: "readWrite", db: "tix_member_external"} ],
        passwordDigestor: "server",
    }
)