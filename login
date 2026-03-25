"use client";

import { useState } from "react";

export default function LoginPage({ onLoginSuccess, onNavigate }) {
    const [username, setUsername] = useState("");
    const [password, setPassword] = useState("");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const [showPassword, setShowPassword] = useState(false);

    const [usernameError, setUsernameError] = useState("");
    const [passwordError, setPasswordError] = useState("");

    const [userFocused, setUserFocused] = useState(false);
    const [passFocused, setPassFocused] = useState(false);

    const BASE_URL = process.env.NEXT_PUBLIC_API_URL;

    // ─── Simple client-side validation ───────────────────────────
    const validateUsername = (val) => {
        if (!val.trim()) return "Username is required.";
        if (val.trim().length < 3) return "Username must be at least 3 characters.";
        return "";
    };

    const validatePassword = (val) => {
        if (!val) return "Password is required.";
        if (val.length < 8) return "Password must be at least 8 characters.";
        return "";
    };

    // ─── Submit ───────────────────────────────────────────────────
    const handleLogin = async (e) => {
        e.preventDefault();
        setError("");

        // Validate before hitting the API
        const usernameErr = validateUsername(username);
        const passwordErr = validatePassword(password);
        setUsernameError(usernameErr);
        setPasswordError(passwordErr);
        if (usernameErr || passwordErr) return;

        setLoading(true);

        try {
            // ── Step 1: Login — backend sets httpOnly cookies automatically ──
            const response = await fetch(`${BASE_URL}/token`, {
                method: "POST",
                credentials: "include",                          // ← allows cookie to be received & stored
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded",
                },
                body: new URLSearchParams({ username, password }),
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.detail || "Login failed");
            }

            // ── Step 2: Handle force password change ──────────────────────
            if (data.force_password_change) {
                onNavigate("change-password");
                return;
            }

            // ── Step 3: Fetch user profile — cookie sent automatically ────
            const profileRes = await fetch(`${BASE_URL}/users/me`, {
                method: "GET",
                credentials: "include",                          // ← cookie sent automatically, no Bearer header needed
                headers: { Accept: "application/json" },
            });

            if (!profileRes.ok) {
                throw new Error("Failed to fetch user profile");
            }

            const userData = await profileRes.json();
            // userData.userType comes directly from DB — 1 = Admin, 3 = User
            // No localStorage, no manual token handling needed

            setUsername("");
            setPassword("");

            onLoginSuccess(userData);                            // ← pass full user object up

        } catch (err) {
            setError(err.message || "Something went wrong");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={styles.container}>
            {/* LEFT PANEL */}
            <div style={styles.leftPanel}>
                <div style={styles.leftContent}>
                    <img
                        src="/signin/Welcome Back.svg"
                        alt="Welcome Back"
                        style={styles.welcomeImg}
                    />

                    <img
                        src="/signin/Sign in to access your test data creation platform.svg"
                        alt="Sign in to access your test data creation platform"
                        style={styles.subtitleImg}
                    />

                    <div style={styles.featureLinks}>
                        <span style={styles.featureLink}>Automated CIF Generation</span>
                        <span style={styles.featureLink}>CCOD Account Creation</span>
                        <span style={styles.featureLink}>Deposit Management</span>
                    </div>

                    <button
                        style={styles.backBtn}
                        onClick={() => onNavigate("welcome")}
                    >
                        <img
                            src="/signin/Group 36286.svg"
                            alt="Back to Home"
                            style={styles.welcomeImg}
                        />
                    </button>
                </div>
            </div>

            {/* RIGHT PANEL */}
            <div style={styles.rightPanel}>
                <img
                    src="/signin/Mask Group 220.png"
                    alt=""
                    style={styles.rightBg}
                />

                <form onSubmit={handleLogin} style={styles.formCard}>
                    <img src="/dashboard/logo123.png" alt="SBI" style={styles.logo} />

                    <div style={styles.tag1}>Sign In to Continue</div>

                    {/* USERNAME */}
                    <div style={styles.fieldGroup}>
                        <img
                            src="/signin/Username.svg"
                            alt="Username"
                            style={styles.fieldLabelImg}
                        />
                        <input
                            type="text"
                            value={username}
                            onChange={(e) => {
                                setUsername(e.target.value);
                                if (usernameError) setUsernameError("");
                            }}
                            onBlur={() => setUsernameError(validateUsername(username))}
                            onFocus={() => setUserFocused(true)}
                            style={{
                                ...styles.input,
                                borderColor: usernameError ? "#b91c1c" : userFocused ? "#003478" : "#b8cfe8",
                            }}
                            autoComplete="username"
                            required
                        />
                        {usernameError && (
                            <div style={styles.inlineError}>{usernameError}</div>
                        )}
                    </div>

                    {/* PASSWORD */}
                    <div style={styles.fieldGroup}>
                        <img
                            src="/signin/Password.svg"
                            alt="Password"
                            style={styles.fieldLabelImg}
                        />
                        <div style={{ position: "relative" }}>
                            <input
                                type={showPassword ? "text" : "password"}
                                value={password}
                                onChange={(e) => {
                                    setPassword(e.target.value);
                                    if (passwordError) setPasswordError("");
                                }}
                                onBlur={() => setPasswordError(validatePassword(password))}
                                onFocus={() => setPassFocused(true)}
                                style={{
                                    ...styles.input,
                                    borderColor: passwordError ? "#b91c1c" : passFocused ? "#003478" : "#b8cfe8",
                                    paddingRight: "38px",
                                }}
                                autoComplete="current-password"
                                required
                            />
                            <span
                                onClick={() => setShowPassword(!showPassword)}
                                style={styles.eyeIcon}
                            >
                                {showPassword ? "🙈" : "👁️"}
                            </span>
                        </div>
                        {passwordError && (
                            <div style={styles.inlineError}>{passwordError}</div>
                        )}
                    </div>

                    {error && <div style={styles.errorMsg}>{error}</div>}

                    <button
                        type="submit"
                        style={{
                            ...styles.loginBtn,
                            opacity: loading ? 0.7 : 1,
                            cursor: loading ? "not-allowed" : "pointer",
                        }}
                        disabled={loading}
                    >
                        {loading ? "Signing in..." : "Login"}
                    </button>

                    <div style={styles.registerRow}>
                        <img
                            src="/signin/Don't have an account Click Here to Create Account.svg"
                            alt="Register"
                            style={styles.registerImg}
                            onClick={() => onNavigate("register")}
                        />
                    </div>

                    <div style={styles.developerStrip}>
                        ©2026 Developed & Maintained by IT-QA CoE, GITC, SBI v1.0
                    </div>
                </form>
            </div>
        </div>
    );
}

/* ==================== STYLES ==================== */

const styles = {
    container: {
        display: "flex",
        minHeight: "100vh",
        width: "100%",
        fontFamily: "'Inter', 'Segoe UI', sans-serif",
        overflow: "hidden",
    },
    leftPanel: {
        backgroundColor: "#f0f5fb",
        display: "flex",
        alignItems: "center",
        padding: "48px 40px",
        flex: "0 0 22%",
        minWidth: "260px",
    },
    leftContent: {
        display: "flex",
        flexDirection: "column",
        gap: "12px",
    },
    welcomeImg: { width: "280px" },
    subtitleImg: { width: "300px" },
    featureLinks: {
        display: "flex",
        flexDirection: "column",
        gap: "6px",
        marginBottom: "20px",
    },
    featureLink: {
        color: "#00A9E0",
        fontSize: "18px",
        fontWeight: "500",
    },
    backBtn: {
        background: "none",
        border: "none",
        cursor: "pointer",
        padding: 0,
    },
    rightPanel: {
        flex: 1,
        position: "relative",
        display: "flex",
        alignItems: "center",
        justifyContent: "right",
    },
    rightBg: {
        position: "absolute",
        width: "100%",
        height: "100%",
        objectFit: "cover",
        zIndex: 0,
    },
    formCard: {
        position: "relative",
        zIndex: 2,
        backgroundColor: "white",
        borderRadius: "16px",
        padding: "36px 40px",
        width: "90%",
        maxWidth: "550px",
        boxShadow: "0 8px 40px rgba(0,0,0,0.18)",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        marginRight: "48px",
    },
    logo: { height: "52px", marginBottom: "8px" },
    tag1: {
        color: "#5c5c5c",
        fontFamily: "Roboto",
        fontSize: "14px",
        fontWeight: "700",
        letterSpacing: "0.5px",
        marginBottom: "8px",
    },
    fieldGroup: {
        width: "100%",
        marginBottom: "14px",
    },
    fieldLabelImg: {
        height: "16px",
        marginBottom: "6px",
        display: "block",
    },
    input: {
        width: "100%",
        padding: "10px 14px",
        border: "1.5px solid #b8cfe8",
        borderRadius: "6px",
        fontSize: "14px",
        outline: "none",
        boxSizing: "border-box",
    },
    inlineError: {
        fontSize: "12px",
        color: "#b91c1c",
        marginTop: "4px",
    },
    errorMsg: {
        width: "100%",
        backgroundColor: "#fee2e2",
        color: "#991b1b",
        padding: "10px 14px",
        borderRadius: "6px",
        marginBottom: "10px",
        fontSize: "13px",
    },
    loginBtn: {
        width: "100%",
        padding: "12px",
        backgroundColor: "#ffd60a",
        border: "none",
        borderRadius: "8px",
        fontWeight: "700",
        marginTop: "6px",
        marginBottom: "14px",
    },
    registerRow: {
        display: "flex",
        justifyContent: "center",
    },
    registerImg: {
        maxWidth: "270px",
        cursor: "pointer",
    },
    eyeIcon: {
        position: "absolute",
        right: "10px",
        top: "50%",
        transform: "translateY(-50%)",
        cursor: "pointer",
        userSelect: "none",
    },
    developerStrip: {
        marginTop: "15px",
        padding: "8px",
        width: "100%",
        textAlign: "center",
        fontSize: "12px",
        color: "#555",
        borderRadius: "10px 10px 10px 10px",
    },
};
