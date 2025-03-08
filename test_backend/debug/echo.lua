---@type Response
local response = {
    headers = {
        ["Content-Type"] = "text/html"
    },
    contents = ""
}
local contentLength = request["CONTENT_LENGTH"];
response.contents=response.contents.."<title>FastCGI echo</title>\n"
response.contents=response.contents.."<h1>FastCGI echo</h1>\n"
RequestNum = (RequestNum or 0) + 1;
response.contents=response.contents.."Request number "..RequestNum..", Process ID: LUA\n"

local length = contentLength and tonumber(contentLength) or 0
if length <= 0 then
    response.contents=response.contents.."no data from standart input <p>\n"
else
    response.contents=response.contents.."Standart Input: <br>\n<pre>\n"
    for i = 0, length-1, 1 do
        local ch = request.input:getChar();
        if not ch then
            response.contents=response.contents.."Error: Not enough bytes received on standard input<p>\n";
            break;
        end
        request.output:putChar(ch);
    end
    response.contents=response.contents.."\n</pre></p>\n"
end
response.contents=response.contents.."env: <br>\n<pre>\n"
for key, value in pairs(request) do
    response.contents=response.contents..key.."="..value.."\n";
end
response.contents=response.contents.."\n</pre></p>\n"

response.contents=response.contents.."headers: <br>\n<pre>\n"
for key, value in pairs(Headers) do
    response.contents=response.contents..key.."="..value.."\n";
end
response.contents=response.contents.."\n</pre></p>\n"

response.contents=response.contents.."hello my fellow user: "..request["HTTP_USER_AGENT"]

return response;