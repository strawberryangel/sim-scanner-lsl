// This is a test to see if I can send data to an external server.

default
{
	http_response(key request_id, integer status, list metadata, string body)
	{
		llOwnerSay("Status: " + (string)status);
	}
	touch_end(integer total_number)
	{
		string url = "http://162.243.199.109:3000/api/agents/current";
		list params = [
			HTTP_METHOD, "POST",
			HTTP_MIMETYPE, "application/x-www-form-urlencoded;charset=utf-8"
				];
		string body = "d695b17a-6504-4697-a945-0b71c53e4771=asdf" +
			"&" +
			"38843c91-07e9-416f-a2d7-fce0ae13dad6=crash";
		llHTTPRequest(url, params, body);
	}
}
