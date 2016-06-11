// This is a test to scan owned parcels for avatars.

scan()
{
	list agents = llGetAgentList(AGENT_LIST_PARCEL_OWNER, []);
	integer count = llGetListLength(agents);
	while(count-- > 0)
	{
		key agent = llList2Key(agents, count);
		string username = llGetUsername(agent);
		string display = llGetDisplayName(agent);
		llOwnerSay((string)agent + " - " + username + " - " + display);
	}
}

default
{
	touch_end(integer total_number)
	{
		scan();
	}
}
