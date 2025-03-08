# Lua Home Page
WHAT IF LUA WAS PHP
I'M NOT KIDDING THIS IS LITERALLY PHP BUT LUA

WHY DID I MADE THIS

# Usage
build it and you got a fcgi server
```
zig build
```
it's expected to be run inside a folder with lua scripts

next connect it as usual to nginx/caddy ([example caddyfile](./test_backend/Caddyfile))

a script could be a lua function stuff that returns
```lua
{headers = {["Header"]="value"}, contents = ""}
```

or a lph file that similar to php
```php
<title><?lua print "text"?></title>
```

# Trivia
made in a few days, and based on an old concept of mine special for луапобеда.рф (may not work yet)