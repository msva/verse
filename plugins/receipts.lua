local verse = require"verse";
local xmlns_receipts = "urn:xmpp:receipts";

function verse.plugins.receipts(stream)
	stream:add_plugin("disco");
	local function send_receipt(stanza)
		if stanza:get_child("request", xmlns_receipts) then
			stream:send(verse.reply(stanza)
				:tag("received", { xmlns = xmlns_receipts, id = stanza.attr.id }));
		end
	end
	--function stream:enable_receipts()
		stream:add_disco_feature(xmlns_receipts);
		stream:hook("message", send_receipt, 1000);
	--end
	--function stream:disable_receipts()
		--stream:remove_disco_feature(xmlns_receipts);
		--stream:unhook("message", send_receipt);
	--end
end