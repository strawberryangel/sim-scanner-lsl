#include "sim-scanner-lsl/main.h"
	#include "lib/debug.lsl"

		string VERSION = "1.3.1";

integer DEVELOPMENT = TRUE;

string DEVELOPMENT_URL = "http://192.241.153.101:3000/api/agents/current";
string PRODUCTION_URL = "http://162.243.199.109:3000/api/agents/current";

string URL;
list HTTP_PARAMS; // Defined in state_entry() because can't typecast outside of a function.

string getPosition(key agent)
{
	list results = llGetObjectDetails(agent, [OBJECT_POS]);
	if(llGetListLength(results) == 0) return "";

	vector position = llList2Vector(results, 0);
	if(position == ZERO_VECTOR) return "";

	string result = (string)position;
	return llGetSubString(result, 1, -2);
}

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
		string position = getPosition(avatar);

		string pair = (string)avatar + "=" + llEscapeURL(username + BUNDLE_DELIMITER + display + BUNDLE_DELIMITER + position);
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
		debug_prefix = "xmtr";
		DEBUG = FALSE; // DEBUG_STYLE_LOCAL;
		
		if(DEVELOPMENT)
			URL = DEVELOPMENT_URL;
		else
			URL = PRODUCTION_URL;

		HTTP_PARAMS = [
			HTTP_METHOD, "POST",
			HTTP_MIMETYPE, "application/x-www-form-urlencoded;charset=utf-8",
			HTTP_BODY_MAXLENGTH, 16384,
			HTTP_CUSTOM_HEADER, INTERVAL_HEADER_NAME, (string)TIMER_INTERVAL
				];
	}

	http_response(key request_id, integer status, list metadata, string body)
	{
		debug("Status: " + (string)status);
	}

	link_message(integer sender_number, integer number, string message, key id)
	{
		if(number == LM_TRANSMITTER) send(message);

	}
}
