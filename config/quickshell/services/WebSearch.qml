pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property var engines: [
        { id: "google", name: "Google", url: "https://www.google.com/search?q=%s" },
        { id: "duckduckgo", name: "DuckDuckGo", url: "https://duckduckgo.com/?q=%s" },
        { id: "brave", name: "Brave", url: "https://search.brave.com/search?q=%s" },
        { id: "bing", name: "Bing", url: "https://www.bing.com/search?q=%s" },
        { id: "startpage", name: "Startpage", url: "https://www.startpage.com/sp/search?query=%s" },
        { id: "ecosia", name: "Ecosia", url: "https://www.ecosia.org/search?q=%s" },
        { id: "custom", name: "Custom", url: "" }
    ]
    readonly property bool customValid: /^https?:\/\/\S+$/i.test(Settings.launcher.searchUrl.trim())
    readonly property var engine: {
        const found = engines.find(e => e.id === Settings.launcher.searchEngine);
        return found && (found.id !== "custom" || customValid) ? found : engines[0];
    }
    readonly property string name: engine.id === "custom" ? template.replace(/^https?:\/\/(www\.)?/i, "").replace(/[\/?#].*$/, "") : engine.name
    readonly property string template: engine.id === "custom" ? Settings.launcher.searchUrl.trim() : engine.url

    function address(text) {
        const t = text.trim();
        if (t === "" || /\s/.test(t))
            return "";
        if (/^[a-z][a-z0-9+.-]*:\/\/\S+$/i.test(t))
            return t;
        if (/^(localhost|(\d{1,3}\.){3}\d{1,3})(:\d+)?([\/?#]\S*)?$/i.test(t))
            return "http://" + t;
        if (/^([a-z0-9-]+\.)+[a-z]{2,}(:\d+)?([\/?#]\S*)?$/i.test(t))
            return "https://" + t;
        return "";
    }

    function searchUrl(text) {
        const q = encodeURIComponent(text.trim());
        return template.includes("%s") ? template.replace("%s", () => q) : template + q;
    }

    function search(text) {
        Apps.browser(searchUrl(text));
    }

    function open(text) {
        Apps.browser(address(text) || searchUrl(text));
    }
}
