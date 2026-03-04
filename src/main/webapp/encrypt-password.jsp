<%@ page import="java.sql.*, db.DBConnection, db.AESEncryption" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%
    // Disable caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String action = request.getParameter("action");
    String userId = request.getParameter("userId");
    String plainPassword = request.getParameter("plainPassword");
    String branchCode = request.getParameter("branchCode");
    String encryptedPassword = null;
    String message = null;
    String messageType = null; // "success" or "error"

    // Handle password encryption
    if ("encrypt".equals(action) && userId != null && plainPassword != null && branchCode != null) {
        try {
            // Encrypt the password using AES
            encryptedPassword = AESEncryption.encrypt(plainPassword);
            message = "Password encrypted successfully! Copy the encrypted password below.";
            messageType = "success";
        } catch (Exception e) {
            message = "Encryption Error: " + e.getMessage();
            messageType = "error";
        }
    }

    // Handle password storage in database
    if ("store".equals(action) && userId != null && encryptedPassword != null && branchCode != null) {
        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DBConnection.getConnection();
            
            // Update the password in the USERREGISTER table
            String sql = "UPDATE ACL.USERREGISTER SET PASSWD = ? WHERE USER_ID = ? AND BRANCH_CODE = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, encryptedPassword);
            pstmt.setString(2, userId);
            pstmt.setString(3, branchCode);
            
            int rowsUpdated = pstmt.executeUpdate();
            
            if (rowsUpdated > 0) {
                message = "✓ Password updated successfully in the database for user: " + userId;
                messageType = "success";
                userId = null;
                plainPassword = null;
                encryptedPassword = null;
                branchCode = null;
            } else {
                message = "✗ User not found. Please check User ID and Branch Code.";
                messageType = "error";
            }
        } catch (Exception e) {
            message = "Database Error: " + e.getMessage();
            messageType = "error";
        } finally {
            try { if (pstmt != null) pstmt.close(); } catch (Exception ignored) {}
            try { if (conn != null) conn.close(); } catch (Exception ignored) {}
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Encrypt Password - Bank CBS Admin</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">
    <style>
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }

        .container-wrapper {
            max-width: 900px;
            margin: 0 auto;
        }

        .header-section {
            background: white;
            padding: 20px;
            border-radius: 8px 8px 0 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            border-left: 5px solid #667eea;
        }

        .header-section h1 {
            color: #333;
            margin: 0;
            font-size: 28px;
            font-weight: 600;
        }

        .header-section p {
            color: #666;
            margin: 5px 0 0 0;
            font-size: 14px;
        }

        .content-section {
            background: white;
            padding: 30px;
            border-radius: 0 0 8px 8px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }

        .step-container {
            margin-bottom: 30px;
        }

        .step-header {
            background: #f8f9fa;
            padding: 12px 15px;
            border-left: 4px solid #667eea;
            margin-bottom: 15px;
            border-radius: 4px;
        }

        .step-header h3 {
            margin: 0;
            color: #333;
            font-size: 16px;
            font-weight: 600;
        }

        .form-group label {
            color: #333;
            font-weight: 600;
            margin-top: 15px;
        }

        .form-control {
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 10px;
            font-size: 14px;
        }

        .form-control:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25);
        }

        .btn-encrypt {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 10px 30px;
            border-radius: 4px;
            font-weight: 600;
            cursor: pointer;
            margin-top: 10px;
            transition: all 0.3s ease;
        }

        .btn-encrypt:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
            color: white;
        }

        .btn-store {
            background: #28a745;
            color: white;
            border: none;
            padding: 10px 30px;
            border-radius: 4px;
            font-weight: 600;
            cursor: pointer;
            margin-top: 10px;
            transition: all 0.3s ease;
        }

        .btn-store:hover {
            background: #218838;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(40, 167, 69, 0.4);
        }

        .encrypted-output {
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 4px;
            padding: 15px;
            margin-top: 15px;
            font-family: 'Courier New', monospace;
            word-break: break-all;
            color: #333;
        }

        .copy-btn {
            background: #007bff;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            margin-top: 10px;
            transition: all 0.3s ease;
        }

        .copy-btn:hover {
            background: #0056b3;
        }

        .alert {
            margin-top: 20px;
            border-radius: 4px;
        }

        .alert-success {
            background: #d4edda;
            border: 1px solid #c3e6cb;
            color: #155724;
            padding: 12px 15px;
            border-radius: 4px;
        }

        .alert-error {
            background: #f8d7da;
            border: 1px solid #f5c6cb;
            color: #721c24;
            padding: 12px 15px;
            border-radius: 4px;
        }

        .info-box {
            background: #e7f3ff;
            border-left: 4px solid #2196F3;
            padding: 12px 15px;
            border-radius: 4px;
            margin-bottom: 20px;
            font-size: 13px;
            color: #1976D2;
        }

        .step-divider {
            border-top: 2px dashed #dee2e6;
            margin: 30px 0;
            position: relative;
        }

        .step-divider::after {
            content: "↓";
            position: absolute;
            top: -12px;
            left: 50%;
            transform: translateX(-50%);
            background: white;
            padding: 0 8px;
            color: #667eea;
            font-size: 20px;
        }

        .instructions {
            background: #fff3cd;
            border: 1px solid #ffc107;
            color: #856404;
            padding: 12px 15px;
            border-radius: 4px;
            margin-bottom: 15px;
            font-size: 13px;
        }
    </style>
</head>
<body>

    <div class="container-wrapper">
        <!-- Header -->
        <div class="header-section">
            <h1>🔐 Password Encryption Tool</h1>
            <p>Encrypt passwords and store them securely in the database using AES-256 encryption</p>
        </div>

        <!-- Content -->
        <div class="content-section">

            <div class="info-box">
                ℹ️ This tool encrypts passwords using AES-256 encryption before storing them in the database.
                The encrypted password will be decrypted during login for verification.
            </div>

            <!-- STEP 1: Encrypt Password -->
            <div class="step-container">
                <div class="step-header">
                    <h3>Step 1: Encrypt Your Password</h3>
                </div>

                <div class="instructions">
                    Enter the user details and plain password below. The password will be encrypted using AES-256.
                </div>

                <form action="encrypt-password.jsp" method="post">
                    <input type="hidden" name="action" value="encrypt">

                    <div class="form-group">
                        <label for="branch1">Branch Code:</label>
                        <select id="branch1" name="branchCode" class="form-control" required>
                            <option value="">-- Select Branch --</option>
                            <%
                                try (Connection conn = DBConnection.getConnection();
                                     Statement stmt = conn.createStatement();
                                     ResultSet branchRS = stmt.executeQuery("SELECT BRANCH_CODE, NAME FROM HEADOFFICE.BRANCH ORDER BY BRANCH_CODE")) {
                                    while(branchRS.next()) {
                                        String bCode = branchRS.getString("BRANCH_CODE");
                                        String bName = branchRS.getString("NAME");
                            %>
                                        <option value="<%=bCode%>"><%=bCode%> - <%=bName%></option>
                            <%
                                    }
                                } catch(Exception ex) {
                                    out.println("<option>Error loading branches</option>");
                                }
                            %>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="userId">User ID:</label>
                        <input type="text" id="userId" name="userId" class="form-control" 
                               value="<%= userId != null ? userId : "" %>" required 
                               placeholder="Enter User ID">
                    </div>

                    <div class="form-group">
                        <label for="plainPassword">Plain Password:</label>
                        <input type="password" id="plainPassword" name="plainPassword" class="form-control" 
                               value="<%= plainPassword != null ? plainPassword : "" %>" required 
                               placeholder="Enter password to encrypt">
                    </div>

                    <button type="submit" class="btn-encrypt">🔒 Encrypt Password</button>
                </form>
            </div>

            <!-- Message Display -->
            <% if (message != null) { %>
                <div class="alert alert-<%= "success".equals(messageType) ? "success" : "error" %>">
                    <%= message %>
                </div>
            <% } %>

            <!-- STEP 2: Display Encrypted Password -->
            <% if (encryptedPassword != null) { %>
                <div class="step-divider"></div>

                <div class="step-container">
                    <div class="step-header">
                        <h3>Step 2: Encrypted Password (Copy below)</h3>
                    </div>

                    <div class="instructions">
                        The password has been encrypted. You can now store this encrypted password in the database.
                        Click "Store in Database" to save it automatically, or copy it for manual storage.
                    </div>

                    <div class="encrypted-output" id="encryptedOutput">
                        <%= encryptedPassword %>
                    </div>

                    <button type="button" class="copy-btn" onclick="copyToClipboard()">
                        📋 Copy Encrypted Password
                    </button>
                </div>

                <div class="step-divider"></div>

                <!-- STEP 3: Store in Database -->
                <div class="step-container">
                    <div class="step-header">
                        <h3>Step 3: Store in Database</h3>
                    </div>

                    <div class="instructions">
                        Click the button below to automatically store the encrypted password in the database.
                    </div>

                    <form action="encrypt-password.jsp" method="post">
                        <input type="hidden" name="action" value="store">
                        <input type="hidden" name="userId" value="<%= userId %>">
                        <input type="hidden" name="branchCode" value="<%= branchCode %>">
                        <input type="hidden" name="encryptedPassword" value="<%= encryptedPassword %>">

                        <button type="submit" class="btn-store">💾 Store in Database</button>
                    </form>
                </div>
            <% } %>

        </div>
    </div>

    <script>
        function copyToClipboard() {
            const output = document.getElementById("encryptedOutput");
            const text = output.innerText;
            
            navigator.clipboard.writeText(text).then(() => {
                alert("✓ Encrypted password copied to clipboard!");
            }).catch(() => {
                alert("Failed to copy. Please copy manually.");
            });
        }
    </script>

</body>
</html>
