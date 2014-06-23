// http://kb.mozillazine.org/User.js_file

// The meek-http-helper extension uses dump to write its listening port number
// to stdout.
user_pref("browser.dom.window.dump.enabled", true);

// 0 is "No proxy".
user_pref("network.proxy.type", 0);

// Allow unproxied DNS.
// https://trac.torproject.org/projects/tor/ticket/11183#comment:6
user_pref("network.proxy.socks_remote_dns", false);

// Enable TLS session tickets (disabled by default in Tor Browser). Otherwise
// there is a missing TLS extension.
// https://trac.torproject.org/projects/tor/ticket/11183#comment:9
user_pref("security.enable_tls_session_tickets", true);

// Disable safe mode. In case of a crash, we don't want to prompt for a
// safe-mode browser that has extensions disabled and no proxy.
// https://support.mozilla.org/en-US/questions/951221#answer-410562
user_pref("toolkit.startup.max_resumed_crashes", -1);

user_pref("extensions.enabledAddons", "meek-http-helper@bamsoftware.com:1.0");
