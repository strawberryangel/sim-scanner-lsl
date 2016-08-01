#include "sim-scanner-lsl/main.h"

string URL = "http://162.243.199.109:3000/api/agents/current";
list HTTP_PARAMS; // Defined in state_entry() because can't typecast outside of a function.

string createBody(string message)
{
	list avatars = llParseStringKeepNulls(message, [BUNDLE_DELIMITER], []);
	integer count = llGetListLength(avatars);
	list bodyValues = [];
	while(count-- > 0)
	{
		key avatar = llList2Key(avatars, count);

		string username = llGetUsername(avatar);
		string display = llGetDisplayName(avatar);

		string pair = (string)avatar + "=" + llEscapeURL(username + BUNDLE_DELIMITER + display);
		bodyValues += pair;
	}

	string body = llDumpList2String(bodyValues, "&");
	return body;
}

send(string message)
{
	string body = createBody(message);
	llHTTPRequest(URL, HTTP_PARAMS, body);
}


default
{
	state_entry()
	{
		HTTP_PARAMS = [
			HTTP_METHOD, "POST",
			HTTP_MIMETYPE, "application/x-www-form-urlencoded;charset=utf-8",
			HTTP_BODY_MAXLENGTH, 16384,
			HTTP_CUSTOM_HEADER, INTERVAL_HEADER_NAME, (string)TIMER_INTERVAL
		];
	}
	http_response(key request_id, integer status, list metadata, string body)
	{
		#ifdef DEBUG
			llOwnerSay("Status: " + (string)status);
		#endif
	}
	link_message(integer sender_number, integer number, string message, key id)
	{
		if(number == LM_TRANSMITTER) send(message);

	}
}
