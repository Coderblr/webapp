"use client";

import { useState, useEffect } from "react";
import { Menu } from "lucide-react";

import Sidebar from "./Sidebar";

// User Views
import HomeView from "./HomeView";
import CifCreationView from "./CifCreationView";

// Admin Views
import AdminDashboard from "../admin/AdminDashboard";
import UserManagement from "../admin/UserManagement";

const BASE_URL = process.env.NEXT_PUBLIC_API_URL;

const IS_ADMIN  = (user) => user?.userType === 1;
const IS_USER   = (user) => user?.userType === 3;

function AccessDenied() {
    return (
        <div style={styles.accessDenied}>
            <span>🔒 You don't have permission to view this page.</span>
        </div>
    );
}

export default function Dashboard({ user, onLogout }) {
    const [sidebarOpen,   setSidebarOpen]   = useState(true);
    const [activeService, setActiveService] = useState("home");
    const [selectedUser,  setSelectedUser]  = useState(null);

    // ── Redirect admin to their dashboard on first load ──────────
    useEffect(() => {
        if (IS_ADMIN(user)) {
            setActiveService("admin_dashboard");
        } else {
            setActiveService("home");
        }
    }, [user]);

    // ── Logout — calls backend to clear httpOnly cookie ──────────
    const handleLogout = async () => {
        try {
            await fetch(`${BASE_URL}/logout`, {
                method: "POST",
                credentials: "include",   // sends the httpOnly cookie so backend can blacklist it
            });
        } catch (err) {
            console.error("Logout error:", err);
        } finally {
            onLogout();   // parent clears state regardless
        }
    };

    // ── Content renderer ─────────────────────────────────────────
    const renderContent = () => {
        switch (activeService) {

            /* ── Regular User Views ── */
            case "home":
                return <HomeView user={user} />;

            case "cif":
                return IS_USER(user) || IS_ADMIN(user)
                    ? <CifCreationView />
                    : <AccessDenied />;

            /* ── Admin-only Views ── */
            case "admin_dashboard":
                return IS_ADMIN(user)
                    ? <AdminDashboard />
                    : <AccessDenied />;

            case "user_management":
                return IS_ADMIN(user) ? (
                    <UserManagement
                        onViewUser={(u) => {
                            setSelectedUser(u);
                            setActiveService("user_detail");
                        }}
                        onViewLogs={(u) => {
                            setSelectedUser(u);
                            setActiveService("activity_logs");
                        }}
                    />
                ) : <AccessDenied />;

            case "activity_logs":
                return IS_ADMIN(user) ? (
                    // <ActivityLogs
                    //     user={selectedUser}
                    //     onBack={() => setActiveService("user_management")}
                    // />
                    <div>Activity Logs — coming soon</div>
                ) : <AccessDenied />;

            case "user_detail":
                return IS_ADMIN(user) ? (
                    // <UserDetails
                    //     user={selectedUser}
                    //     onBack={() => setActiveService("user_management")}
                    // />
                    <div>User Details — coming soon</div>
                ) : <AccessDenied />;

            case "admin_create_user":
                return IS_ADMIN(user) ? (
                    // <CreateUser onBack={() => setActiveService("user_management")} />
                    <div>Create User — coming soon</div>
                ) : <AccessDenied />;

            case "reset_password":
                return IS_ADMIN(user) ? (
                    // <ResetPassword user={selectedUser} onBack={() => setActiveService("user_management")} />
                    <div>Reset Password — coming soon</div>
                ) : <AccessDenied />;

            default:
                return <HomeView user={user} />;
        }
    };

    return (
        <div style={styles.dashboardContainer}>

            {/* ── TOP NAV ── */}
            <nav style={styles.dashboardNav}>
                <div style={styles.dashNavLeft}>
                    <button
                        onClick={() => setSidebarOpen(!sidebarOpen)}
                        style={styles.menuBtn}
                    >
                        <Menu size={24} />
                    </button>

                    <div style={styles.navBrand}>
                        <img src="/dashboard/logo123.png" alt="SBI" style={styles.logo} />
                    </div>
                </div>

                <div style={styles.dashNavRight}>
                    {/* User badge */}
                    <div style={styles.userBadge}>
                        <span style={styles.userBadgeName}>
                            {user?.firstName} {user?.lastName}
                        </span>
                        <span style={styles.userBadgeRole}>
                            {IS_ADMIN(user) ? "Admin" : "User"}
                        </span>
                    </div>

                    {/* Logout button */}
                    <div style={styles.logoutWrapper} onClick={handleLogout} title="Logout">
                        <img
                            src="/dashboard/Rectangle 17817.svg"
                            alt="Logout"
                            style={styles.yellowBtn}
                        />
                        <img
                            src="/dashboard/Logout.svg"
                            alt="logout"
                            style={styles.logoutIcon}
                        />
                    </div>
                </div>
            </nav>

            {/* ── BODY ── */}
            <div style={styles.mainContainer}>
                <Sidebar
                    sidebarOpen={sidebarOpen}
                    activeService={activeService}
                    setActiveService={setActiveService}
                    user={user}           // Sidebar uses userType to show/hide menu items
                />

                <main style={styles.content}>
                    {renderContent()}
                </main>
            </div>

            {/* ── FOOTER ── */}
            <div style={styles.copyright_container}>
                <p style={styles.copyright_text}>
                    ©2026 Developed & Maintained by{" "}
                    <strong>IT-QA CoE, GITC, SBI v1.0</strong>
                </p>
            </div>
        </div>
    );
}

/* ==================== STYLES ==================== */

const styles = {
    dashboardContainer: {
        display: "flex",
        flexDirection: "column",
        minHeight: "100vh",
        backgroundColor: "#f8fafc",
        fontFamily: "'Inter', 'Segoe UI', sans-serif",
    },
    dashboardNav: {
        backgroundColor: "white",
        padding: "1rem 2rem",
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        borderBottom: "1px solid #e2e8f0",
        boxShadow: "0 1px 3px rgba(0,0,0,0.05)",
        position: "sticky",
        top: 0,
        zIndex: 1000,
    },
    dashNavLeft: {
        display: "flex",
        alignItems: "center",
        gap: "12px",
    },
    dashNavRight: {
        display: "flex",
        alignItems: "center",
        gap: "16px",
    },
    menuBtn: {
        background: "none",
        border: "none",
        cursor: "pointer",
        display: "flex",
        alignItems: "center",
        padding: "4px",
        borderRadius: "6px",
        color: "#334155",
    },
    navBrand: {
        display: "flex",
        alignItems: "center",
    },
    logo: {
        height: "46px",
        objectFit: "contain",
    },
    userBadge: {
        display: "flex",
        flexDirection: "column",
        alignItems: "flex-end",
        lineHeight: 1.2,
    },
    userBadgeName: {
        fontSize: "13px",
        fontWeight: "600",
        color: "#1e293b",
    },
    userBadgeRole: {
        fontSize: "11px",
        color: "#64748b",
        textTransform: "uppercase",
        letterSpacing: "0.5px",
    },
    logoutWrapper: {
        position: "relative",
        cursor: "pointer",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
    },
    yellowBtn: {
        height: "34px",
    },
    logoutIcon: {
        position: "absolute",
        top: "50%",
        left: "50%",
        transform: "translate(-50%, -50%)",
        height: "18px",
    },
    mainContainer: {
        display: "flex",
        flex: 1,
        overflow: "hidden",
    },
    content: {
        flex: 1,
        overflowY: "auto",
        padding: "24px",
    },
    accessDenied: {
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        height: "300px",
        fontSize: "15px",
        color: "#b91c1c",
        backgroundColor: "#fee2e2",
        borderRadius: "12px",
        fontWeight: "500",
    },
    copyright_container: {
        textAlign: "center",
        padding: "12px",
        borderTop: "1px solid #e2e8f0",
        backgroundColor: "white",
    },
    copyright_text: {
        fontSize: "12px",
        color: "#64748b",
        margin: 0,
    },
};
