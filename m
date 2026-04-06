"use client";
import { useEffect } from "react";

export const useSessionManager = () => {
  useEffect(() => {
    const handleBeforeUnload = () => {
      // Mark that user is refreshing
      sessionStorage.setItem("isReload", "true");
    };

    const handleUnload = () => {
      const isReload = sessionStorage.getItem("isReload");

      if (isReload) {
        sessionStorage.removeItem("isReload");
        return; // ✅ skip logout on refresh
      }

      navigator.sendBeacon("/logout"); // ✅ logout only on tab close
    };

    window.addEventListener("beforeunload", handleBeforeUnload);
    window.addEventListener("unload", handleUnload);

    return () => {
      window.removeEventListener("beforeunload", handleBeforeUnload);
      window.removeEventListener("unload", handleUnload);
    };
  }, []);
};
