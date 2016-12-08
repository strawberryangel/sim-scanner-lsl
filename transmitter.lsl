#include "sim-scanner-lsl/lib.lsl"
	#include "sim-scanner-lsl/main.h"
		#include "lib/avatar.lsl"
			#include "lib/channels.lsl"
				#include "lib/debug.lsl"
					#include "lib/http.lsl"
						#include "lib/whitelist.lsl"

							string VERSION = "1.6.1";

integer DEVELOPMENT = FALSE;

///////////////////////////////////////////////////
// HTTP Communication
///////////////////////////////////////////////////

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

string EVIL_NAME = "Progeny";
string detectProgeny(key avatar)
{
	list AttachedUUIDs = llGetAttachedList(avatar);

	integer count = llGetListLength(AttachedUUIDs);
	integer i = count;
	while (i-- > 0)
	{
		key uuid = llList2Key(AttachedUUIDs,i);
		list temp = llGetObjectDetails(uuid, [OBJECT_NAME]);
		string name = llList2String(temp,0);

		if(llSubStringIndex(name, EVIL_NAME) >= 0)
			return "1";
	}

	return "";
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
		string progeny = detectProgeny(avatar);

		list bundle = [username, display, position, progeny];

		string pair = (string)avatar + "=" + llEscapeURL(llDumpList2String(bundle, BUNDLE_DELIMITER));
		bodyValues += pair;
	}

	string body = llDumpList2String(bodyValues, "&");
	return body;
}

processResult(string body)
{
	list parts = llParseString2List(body, ["|"], []);
	integer count = llGetListLength(parts);
	while(count-- > 0)
	{
		string piece = llList2String(parts, count);
		list pieces = llParseString2List(piece, [","], []);
		if(llGetListLength(pieces) == 2 && llList2String(pieces, 0) == "P")
		{
			string target = llList2String(pieces, 1);
			debug("Instructing " + url_name((key)target) + " to receive a notecard.");
			llRegionSay(PROGENY_NOTECARD_GIVER_REGIONAL_CHANNEL, target);
		}
	}
}

send(string message)
{
	string body = createBody(message);
	llHTTPRequest(URL, HTTP_PARAMS, body);
}

///////////////////////////////////////////////////
// Misc. Functions
///////////////////////////////////////////////////

configure()
{
	string ip;

	if(DEVELOPMENT)
		ip = ADDRESS_DEVELOPMENT_SERVER;
	else
		ip = ADDRESS_PRODUCTION_SERVER;

	URL = "http:// "+ ip + ":" + PORT_AVATAR_SENSOR_LISTENER + "/api/agents/current";
}

report_version()
{
	send_report_version_message("Transmitter v" + VERSION);
	if(DEBUG)
		send_report_version_message(URL);

	if(DEVELOPMENT)
		send_report_version_message("Development");
	else
		send_report_version_message("Production");


	if(llGetOwner() == WL_Sophie)
	{
		// Do this to not let others freak out when they see me running around with a sensor package.
		send_report_version_message("** Deactivated **");
	}
}

send_report_version_message(string message)
{
	llMessageLinked(LINK_SET, LINK_COMMAND_REPORT_VERSION, SCRIPT_TRANSMITTER + "|" + message, NULL_KEY);
}


default
{
	state_entry()
	{
		debug_prefix = "xmtr";
		DEBUG = FALSE; // DEBUG_STYLE_LOCAL;

		configure();

		HTTP_PARAMS = [
			HTTP_METHOD, "POST",
			HTTP_MIMETYPE, "application/x-www-form-urlencoded;charset=utf-8",
			HTTP_BODY_MAXLENGTH, 16384,
			HTTP_CUSTOM_HEADER, INTERVAL_HEADER_NAME, (string)TIMER_INTERVAL
				];
	}

	http_response(key request_id, integer status, list metadata, string body)
	{
		if(llFloor(status / 100) == 2) processResult(body);
	}

	link_message(integer sender_number, integer number, string message, key id)
	{
		if(number == LM_TRANSMITTER) send(message);

		if(number == LINK_COMMAND_REPORT_VERSION && message == "")
			report_version();

		if(number == LINK_COMMAND_CONFIGURE_SERVER)
		{
			if(message == TRANSMITTER_CONFIG_DEVELOPMENT) DEVELOPMENT = TRUE;
			if(message == TRANSMITTER_CONFIG_PRODUCTION) DEVELOPMENT = FALSE;
			configure();
		}
	}
}
