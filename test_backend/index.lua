print("hello world");
return {
    headers = {
        ["Content-Type"] = "text/html"
    },
    contents =
[[
<html>
<head>
    <meta charset="UTF-8">
    <title>Hello from LUA >:з</title>
</head>
<body>
    <h1>This is actually in lua script</h1>
    <p>yea, really: <b></b> алсо ворк витх руссиан леттерс (and utf-8 in particular)</p>
    </body>
</html>]]
}