import { useEffect } from "react";

const BASE_URL = process.env.NEXT_PUBLIC_API_URL;

export function useSessionManager() {
    useEffect(() => {
        // On mount: if this is a reload, skip beacon by marking it
        const navEntry = performance.getEntriesByType("navigation")[0];
        const isReload = navEntry?.type === "reload";
        
        if (isReload) {
            sessionStorage.setItem("__skip_beacon", "1");
        }

        const handlePageHide = () => {
            const loggedIn = sessionStorage.getItem("sessionActive") === "true";
            if (!loggedIn) return;

            const skip = sessionStorage.getItem("__skip_beacon") === "1";
            sessionStorage.removeItem("__skip_beacon");
            if (skip) return;

            navigator.sendBeacon(
                `${BASE_URL}/logout-beacon`,
                new Blob([], { type: "application/json" })
            );
        };

        window.addEventListener("pagehide", handlePageHide);

        return () => {
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
