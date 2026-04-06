import { useEffect } from "react";

const BASE_URL = process.env.NEXT_PUBLIC_API_URL;

export function useSessionManager() {
    useEffect(() => {
        const handleBeforeUnload = () => {
            sessionStorage.setItem("__unload_ts", Date.now().toString());
        };

        const handlePageHide = () => {
            const loggedIn = sessionStorage.getItem("sessionActive") === "true";
            if (!loggedIn) return;

            navigator.sendBeacon(
                `${BASE_URL}/logout-beacon`,
                new Blob([], { type: "application/json" })
            );
        };

        // On mount: check if previous unload was a reload or close
        // If sessionStorage has __unload_ts, it was a reload (sessionStorage persists on reload)
        // If sessionStorage is empty, it was a tab close (sessionStorage is cleared on close)
        const unloadTs = sessionStorage.getItem("__unload_ts");
        sessionStorage.removeItem("__unload_ts");

        window.addEventListener("beforeunload", handleBeforeUnload);
        window.addEventListener("pagehide", handlePageHide);

        return () => {
            window.removeEventListener("beforeunload", handleBeforeUnload);
            window.removeEventListener("pagehide", handlePageHide);
        };
    }, []);
}

export function setSessionActive() {
    sessionStorage.setItem("sessionActive", "true");
}

export function clearSessionActive() {
    sessionStorage.removeItem("sessionActive");
}
