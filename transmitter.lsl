#include "sim-scanner-lsl/lib.lsl"
#include "sim-scanner-lsl/main.h"
#include "lib/avatar.lsl"
#include "lib/channels.lsl"
#include "lib/debug.lsl"
#include "lib/profiling.lsl"
#include "lib/whitelist/blackpaw-avatars.lsl"

string VERSION = "2.0.0";

integer DEVELOPMENT = FALSE;

///////////////////////////////////////////////////
// HTTP Communication
///////////////////////////////////////////////////

string URL;
list HTTP_PARAMS; // Defined in state_entry() because can't typecast outside of a function.

string getPosition(key agent)
{
	list results = llGetObjectDetails(agent, [OBJECT_POS]);
	vector position = llList2Vector(results, 0);

	return llList2Json(JSON_OBJECT, [
		"x", position.x,
		"y", position.y,
		"z", position.z
	]);
}

string EVIL_NAME = "Progeny";
integer detectProgeny(key avatar)
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
			return 1;
	}

	return 0;
}

string to_transmit;
string body;
createBody()
{
	list avatars = llParseStringKeepNulls(to_transmit, [BUNDLE_DELIMITER], []);
	integer count = llGetListLength(avatars);
	list bodyValues = [];
	while(count-- > 0)
	{
		key avatar = llList2Key(avatars, count);

		// string username = llGetUsername(avatar);
		// string display = llGetDisplayName(avatar);
		string position = getPosition(avatar);
		integer progeny = detectProgeny(avatar);

		bodyValues += llList2Json(JSON_OBJECT, [
			"uuid", (string)avatar,
			"pos", position,
			"pv", progeny
		]);
	}

	body = "[" + llDumpList2String(bodyValues, ",") + "]";
	bodyValues = []; // Force release.
}

processResult(string body)
{
	/*
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
	*/
}

send()
{
	createBody();
	llHTTPRequest(URL, HTTP_PARAMS, body);
}

///////////////////////////////////////////////////
// Misc. Functions
///////////////////////////////////////////////////

configure()
{
	if(DEVELOPMENT)
		URL = ADDRESS_DEVELOPMENT_SERVER;
	else
		URL = ADDRESS_PRODUCTION_SERVER;
}

report_version()
{
	send_report_version_message("Transmitter v" + VERSION);
	#ifdef DEBUG
		send_report_version_message(URL);
	#endif

	if(DEVELOPMENT)
		send_report_version_message("Development");
	else
		send_report_version_message("Production");


	if(llGetOwner() == WL_Sophie)
	{
		// Do this to not let others freak out when they see me running around with a sensor package.
		// send_report_version_message("** Deactivated **");
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

		configure();

		HTTP_PARAMS = [
			HTTP_METHOD, "POST",
			HTTP_MIMETYPE, "application/json;charset=utf-8",
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
		if(number == LM_TRANSMITTER) {
			start_profiling();
			to_transmit = message;
			send();
			stop_profiling();
			return;
		}

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
