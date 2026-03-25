"use client";

import { useState, useEffect } from "react";
import Welcome from "./components/Welcome";
import LoginPage from "./components/auth/LoginPage";
import RegisterPage from "./components/auth/RegisterPage";
import Dashboard from "./components/dashboard/Dashboard";

export default function SBIApp() {
  const [currentPage, setCurrentPage] = useState("welcome");
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [loading, setLoading] = useState(true);   // start true to check session
  const [user, setUser] = useState(null);

  const BASE_URL = process.env.NEXT_PUBLIC_API_URL;

  /* =========================
     RESTORE SESSION — no token needed, cookie is sent automatically
  ========================== */
  useEffect(() => {
    fetchUserProfile();
  }, []);

  /* =========================
     FETCH USER PROFILE
  ========================== */
  const fetchUserProfile = async () => {
    try {
      setLoading(true);

      const response = await fetch(`${BASE_URL}/users/me`, {
        method: "GET",
        credentials: "include",        // ← sends the httpOnly cookie automatically
        headers: { Accept: "application/json" },
        // NO manual Authorization header needed
      });

      if (!response.ok) throw new Error("Not authenticated");

      const userData = await response.json();
      setUser(userData);
      setIsLoggedIn(true);
      setCurrentPage("dashboard");

    } catch {
      // No valid session — send to welcome
      setUser(null);
      setIsLoggedIn(false);
      setCurrentPage("welcome");
    } finally {
      setLoading(false);
    }
  };

  /* =========================
     LOGIN SUCCESS
     Backend already set the cookie — just fetch the profile
  ========================== */
  const handleLoginSuccess = async () => {
    await fetchUserProfile();   // ← no token parameter needed
  };

  /* =========================
     LOGOUT — call backend to clear cookie + blacklist token
  ========================== */
  const handleLogout = async () => {
    try {
      await fetch(`${BASE_URL}/logout`, {
        method: "POST",
        credentials: "include",    // ← sends cookie so backend can blacklist it
      });
    } catch {
      // ignore network errors on logout
    } finally {
      setUser(null);
      setIsLoggedIn(false);
      setCurrentPage("welcome");
    }
  };

  /* =========================
     LOADING SCREEN
  ========================== */
  if (loading) {
    return (
      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", height: "100vh" }}>
        <p>Loading...</p>
      </div>
    );
  }

  /* =========================
     ROUTING
  ========================== */
  if (currentPage === "welcome" && !isLoggedIn)
    return <Welcome onNavigate={setCurrentPage} />;

  if (currentPage === "login" && !isLoggedIn)
    return <LoginPage onLoginSuccess={handleLoginSuccess} onNavigate={setCurrentPage} />;

  if (currentPage === "register" && !isLoggedIn)
    return <RegisterPage onNavigate={setCurrentPage} />;

  if (isLoggedIn && user)
    return <Dashboard user={user} onLogout={handleLogout} />;

  return null;
}
