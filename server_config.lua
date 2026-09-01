-- Central server configuration. Put devserver.flag next to the executable to
-- select the local profile. Without that flag the distributed client uses
-- the public profile. Changing either host does not require recompilation.
return {
    public = {
        loginUrl = "https://108.165.230.133/login.php",
        webUrl = "https://108.165.230.133",
        loginPort = 443,
        protocol = 1530
    },
    localServer = {
        loginUrl = "http://127.0.0.1/login.php",
        webUrl = "http://127.0.0.1",
        loginPort = 80,
        protocol = 1530
    }
}
