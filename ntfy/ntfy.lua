local expect = require("cc.expect").expect

function send(topic, message, title)
    expect(1, topic, "string")
    expect(2, message, "string")
    expect(3, title, "string", "nil")
    if not title then
        title = os.computerLabel()
    end
    http.post("http://ntfy.sh/" .. topic, message, {["Title"] = title})
end

return { send = send }
