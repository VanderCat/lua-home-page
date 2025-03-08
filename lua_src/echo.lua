local contentLength = request["CONTENT_LENGTH"];
request.output:putString("Content-Type: text/html\n\r")
request.output:putString("\n\r")
request.output:putString("<title>FastCGI echo</title>\n")
request.output:putString("<h1>FastCGI echo</h1>\n")
RequestNum = (RequestNum or 0) + 1;
request.output:putString("Request number "..RequestNum..", Process ID: LUA\n")

local length = contentLength and tonumber(contentLength) or 0
if length <= 0 then
    request.output:putString("no data from standart input <p>\n")
else
    request.output:putString("Standart Input: <br>\n<pre>\n")
    for i = 0, length-1, 1 do
        local ch = request.input:getChar();
        if not ch then
            request.output:putString("Error: Not enough bytes received on standard input<p>\n");
            break;
        end
        request.output:putChar(ch);
    end
    request.output:putString("\n</pre></p>\n")
end
request.output:putString("env: <br>\n<pre>\n")
for key, value in pairs(request) do
    request.output:putString(key.."="..value.."\n");
end
request.output:putString("\n</pre></p>\n")

request.output:putString("hello my fellow user: "..request["HTTP_"])