local verse = require "verse";

local xmlns_time = "urn:xmpp:time";

function verse.plugins.time(stream)
	stream:hook("iq/"..xmlns_time, function (stanza)
		if stanza.attr.type ~= "get" then return; end
		local reply = verse.reply(stanza)
			:tag("time", { xmlns = xmlns_time });
		reply:tag("utc"):text(tostring(os.date("!%FT%TZ"))):up();
		reply:tag("tzo"):text(tostring(os.date("%z"):gsub("(%d%d)(%d%d)","%1:%2"))):up();
		stream:send(reply);
		return true;
	end);

	function stream:query_time(target_jid, callback)
		callback = callback or function (time) return stream:event("time/response", time); end
		stream:send_iq(verse.iq({ type = "get", to = target_jid })
			:tag("time", { xmlns = xmlns_time }),
			function (reply)
				local time = reply:get_child("time", xmlns_time);
				if reply.attr.type == "result" then
					local utc = time:get_child_text("utc");
					if not utc then
						callback({
							error = true;
							condition = "service-unavailable";
							type = "cancel";
							text = "Remote client doesn't support XEP-0202";
							});
					else
						local tzo = time:get_child_text("tzo") or "+00:00";
						local utc_year, utc_month, utc_day, utc_hour, utc_min, utc_sec = utc:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+).?%d*Z");
						local offset_sign, offset_hour, offset_min = tzo:match("([+%-])(%d%d):?(%d*)");
						local offset = tonumber(offset_sign..(offset_hour or 0) * 60 * 60 + (offset_min or 0) * 60);
						local r_utcstamp = os.time({year = utc_year; month = utc_month; day = utc_day; hour = utc_hour; min = utc_min; sec = utc_sec; isdst = false;});
						callback({
							utc = r_utcstamp or nil;
							offset = offset or nil;
							});
					end
				else
					local type, condition, text = reply:get_error();
					callback({
						error = true;
						condition = condition;
						text = text;
						type = type;
						});
				end
			end);
	end
	return true;
end
