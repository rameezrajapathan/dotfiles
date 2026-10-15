pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Weather from Open-Meteo (no API key): now, the next 24 hours, 7 days and air quality, refreshed
// every 15 minutes. The place is found from the IP address (ipinfo.io) until one is picked with
// search(); it and the unit live in ~/.local/state/quickshell/weather.json.
// WeatherPanel shows it; `qs ipc call weather toggle` opens it, `weather refresh` reloads.
Singleton {
    id: root

    signal panelToggleRequested()

    // Place and unit (saved)
    readonly property string place: settings.name
    readonly property string region: [settings.region, settings.country].filter(s => s).join(", ")
    readonly property bool autoLocation: settings.auto
    readonly property bool fahrenheit: settings.fahrenheit
    readonly property bool hasPlace: settings.latitude !== 0 || settings.longitude !== 0

    // Forecast; null until the first load
    property var current: null      // { temp, feels, humidity, code, isDay, wind, windDir, gusts, pressure, precipitation, cloud, visibility, uv, dewPoint }
    property var hourly: []         // next 24 h: { time: Date, temp, code, isDay, precip }
    property var daily: []          // 7 days: { date: Date, code, max, min, precip, sunrise: Date, sunset: Date, uv }
    property var air: null          // { aqi, pm25 }
    property date updated: new Date(0)
    property bool loading: false
    property string error: ""

    // Place search results: { name, region, latitude, longitude, country }
    property var results: []
    property bool searching: false

    readonly property bool ready: current !== null

    function unit(c) {
        return Math.round(fahrenheit ? c * 9 / 5 + 32 : c);
    }
    function temp(c) {
        return unit(c) + "°";
    }

    // WMO weather code → label and Material Symbols icon
    function label(code) {
        if (code === 0) return "Clear";
        if (code === 1) return "Mostly clear";
        if (code === 2) return "Partly cloudy";
        if (code === 3) return "Overcast";
        if (code === 45 || code === 48) return "Fog";
        if (code >= 51 && code <= 57) return "Drizzle";
        if (code === 61 || code === 80) return "Light rain";
        if (code === 63 || code === 81) return "Rain";
        if (code === 65 || code === 82) return "Heavy rain";
        if (code === 66 || code === 67) return "Freezing rain";
        if (code === 71 || code === 85) return "Light snow";
        if (code === 73 || code === 75 || code === 86) return "Snow";
        if (code === 77) return "Snow grains";
        if (code === 95) return "Thunderstorm";
        if (code === 96 || code === 99) return "Thunderstorm, hail";
        return "—";
    }
    function icon(code, isDay) {
        if (code <= 1) return isDay ? "sunny" : "dark_mode";
        if (code === 2) return isDay ? "partly_cloudy_day" : "partly_cloudy_night";
        if (code === 3) return "cloud";
        if (code === 45 || code === 48) return "foggy";
        if (code >= 51 && code <= 57) return "rainy_light";
        if (code === 61 || code === 80) return "rainy_light";
        if (code === 63 || code === 81) return "rainy";
        if (code === 65 || code === 82) return "rainy_heavy";
        if (code === 66 || code === 67) return "rainy_snow";
        if (code >= 71 && code <= 77 || code === 85 || code === 86) return "weather_snowy";
        if (code >= 95) return "thunderstorm";
        return "cloud";
    }
    // Broad sky kind for the panel's backdrop
    function sky(code, isDay) {
        const night = !isDay;
        if (code <= 1) return night ? "clear-night" : "clear";
        if (code <= 3) return night ? "cloudy-night" : "cloudy";
        if (code === 45 || code === 48) return "fog";
        if (code >= 71 && code <= 86 && !(code >= 80 && code <= 82)) return "snow";
        if (code >= 95) return "storm";
        return "rain";
    }

    function aqiLabel(aqi) {
        if (aqi <= 50) return "Good";
        if (aqi <= 100) return "Moderate";
        if (aqi <= 150) return "Unhealthy for some";
        if (aqi <= 200) return "Unhealthy";
        if (aqi <= 300) return "Very unhealthy";
        return "Hazardous";
    }
    function uvLabel(uv) {
        return uv < 3 ? "Low" : uv < 6 ? "Moderate" : uv < 8 ? "High" : uv < 11 ? "Very high" : "Extreme";
    }
    function compass(deg) {
        return ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][Math.round(deg / 45) % 8];
    }

    function setUnit(f) {
        settings.fahrenheit = f;
    }

    // Uses a search result as the place
    function choose(result) {
        settings.name = result.name;
        settings.region = result.region ?? "";
        settings.country = result.country ?? "";
        settings.latitude = result.latitude;
        settings.longitude = result.longitude;
        settings.auto = false;
        results = [];
        refresh();
    }

    // Off keeps the place found last and stops following the connection (Settings app)
    function setAutoLocation(on) {
        if (on)
            useMyLocation();
        else
            settings.auto = false;
    }

    // Back to the place from the IP address
    function useMyLocation() {
        settings.auto = true;
        locate();
    }

    function search(text) {
        const q = text.trim();
        if (q.length < 2) {
            results = [];
            return;
        }
        searching = true;
        get("https://geocoding-api.open-meteo.com/v1/search?count=6&language=en&format=json&name=" + encodeURIComponent(q), data => {
            searching = false;
            results = (data?.results ?? []).map(r => ({
                name: r.name,
                region: r.admin1 && r.admin1 !== r.name ? r.admin1 : "",
                country: r.country ?? "",
                latitude: r.latitude,
                longitude: r.longitude
            }));
        }, () => { searching = false; });
    }

    function locate() {
        loading = true;
        get("https://ipinfo.io/json", data => {
            const loc = (data?.loc ?? "").split(",");
            if (loc.length !== 2) {
                fail("Couldn't find your location");
                return;
            }
            settings.name = data.city ?? "Here";
            settings.region = data.region ?? "";
            settings.country = data.country ?? "";
            settings.latitude = Number(loc[0]);
            settings.longitude = Number(loc[1]);
            refresh();
        }, () => fail("Couldn't find your location"));
    }

    function refresh() {
        if (!hasPlace) {
            locate();
            return;
        }
        loading = true;
        const at = "latitude=" + settings.latitude + "&longitude=" + settings.longitude;
        get("https://api.open-meteo.com/v1/forecast?" + at + "&timezone=auto&forecast_days=7"
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,is_day,weather_code,"
            + "wind_speed_10m,wind_direction_10m,wind_gusts_10m,pressure_msl,precipitation,cloud_cover,"
            + "visibility,uv_index,dew_point_2m"
            + "&hourly=temperature_2m,weather_code,precipitation_probability,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,"
            + "sunrise,sunset,uv_index_max", data => parse(data), () => fail("Couldn't reach Open-Meteo"));
        get("https://air-quality-api.open-meteo.com/v1/air-quality?" + at + "&current=us_aqi,pm2_5", data => {
            const c = data?.current;
            air = c && c.us_aqi !== null ? { aqi: Math.round(c.us_aqi), pm25: c.pm2_5 } : null;
        }, () => {});
    }

    function parse(data) {
        const c = data?.current;
        if (!c) {
            fail("Unexpected answer from Open-Meteo");
            return;
        }
        // Open-Meteo gives local times without a zone ("2026-10-15T18:00"); its offset makes them real
        const offset = data.utc_offset_seconds ?? 0;
        const toDate = s => new Date(Date.parse(s + "Z") - offset * 1000);

        current = {
            temp: c.temperature_2m, feels: c.apparent_temperature, humidity: c.relative_humidity_2m,
            code: c.weather_code, isDay: c.is_day === 1, wind: c.wind_speed_10m, windDir: c.wind_direction_10m,
            gusts: c.wind_gusts_10m, pressure: c.pressure_msl, precipitation: c.precipitation,
            cloud: c.cloud_cover, visibility: c.visibility, uv: c.uv_index, dewPoint: c.dew_point_2m
        };

        const h = data.hourly;
        const now = Date.now() - 3600 * 1000;
        const hours = [];
        for (let i = 0; i < h.time.length && hours.length < 25; i++) {
            const t = toDate(h.time[i]);
            if (t.getTime() < now)
                continue;
            hours.push({ time: t, temp: h.temperature_2m[i], code: h.weather_code[i], isDay: h.is_day[i] === 1, precip: h.precipitation_probability[i] ?? 0 });
        }
        hourly = hours;

        const d = data.daily;
        const days = [];
        for (let i = 0; i < d.time.length; i++)
            days.push({
                date: toDate(d.time[i] + "T12:00"), code: d.weather_code[i], max: d.temperature_2m_max[i],
                min: d.temperature_2m_min[i], precip: d.precipitation_probability_max[i] ?? 0,
                sunrise: toDate(d.sunrise[i]), sunset: toDate(d.sunset[i]), uv: d.uv_index_max[i]
            });
        daily = days;

        updated = new Date();
        loading = false;
        error = "";
    }

    function fail(message) {
        loading = false;
        error = message;
    }

    function get(url, done, failed) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    done(JSON.parse(xhr.responseText));
                    return;
                } catch (e) {}
            }
            failed();
        };
        xhr.open("GET", url);
        xhr.send();
    }

    // Reloads when it's been a while (the panel calls this when it opens)
    function refreshIfStale() {
        if (!loading && Date.now() - updated.getTime() > 10 * 60 * 1000)
            refresh();
    }

    IpcHandler {
        target: "weather"
        function toggle(): void { root.panelToggleRequested(); }
        function refresh(): void { root.refresh(); }
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.autoLocation ? root.locate() : root.refresh()
    }

    Timer {
        id: saveTimer
        interval: 200
        onTriggered: file.writeAdapter()
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/quickshell/weather.json"
        printErrors: false
        // Saved once after a batch of changes: writing on every property drops some of them
        onAdapterUpdated: saveTimer.restart()
        onLoaded: root.autoLocation || !root.hasPlace ? root.locate() : root.refresh()
        onLoadFailed: root.locate()

        JsonAdapter {
            id: settings
            property string name: ""
            property string region: ""
            property string country: ""
            property real latitude: 0
            property real longitude: 0
            property bool auto: true
            property bool fahrenheit: false
        }
    }
}
