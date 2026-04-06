useEffect(() => {
  const handleUnload = () => {
    // If reload → skip logout
    if (performance.getEntriesByType("navigation")[0]?.type === "reload") {
      return;
    }

    navigator.sendBeacon("/logout");
  };

  window.addEventListener("unload", handleUnload);

  return () => {
    window.removeEventListener("unload", handleUnload);
  };
}, []);
