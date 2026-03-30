<%@ page contentType="application/json; charset=UTF-8" %>
<%@ page import="java.sql.*, db.DBConnection" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    HttpSession existingSession = request.getSession(false);
    boolean isValid = false;
    boolean forcedOut = false;

    if (existingSession != null) {
        String userId     = (String) existingSession.getAttribute("userId");
        String branchCode = (String) existingSession.getAttribute("branchCode");

        if (userId != null && branchCode != null) {

            Connection conn = null;
            PreparedStatement ps = null;
            ResultSet rs = null;

            try {
                conn = DBConnection.getConnection();
                ps = conn.prepareStatement(
                    "SELECT SESSION_ID FROM ACL.USERREGISTER " +
                    "WHERE USER_ID = ? AND BRANCH_CODE = ?"
                );
                ps.setString(1, userId);
                ps.setString(2, branchCode);
                rs = ps.executeQuery();

                if (rs.next()) {
                    String dbSessionId     = rs.getString("SESSION_ID");
                    String currentSessionId = existingSession.getId();
                    if (dbSessionId == null) {
                        // SESSION_ID is null — just saved or cleared momentarily — treat as valid
                        isValid   = true;
                        forcedOut = false;
                    } else if (dbSessionId.equals(currentSessionId)) {
                        // Session ID matches DB — valid
                        isValid   = true;
                        forcedOut = false;
                    } else {
                        // Session ID mismatch — someone else force logged in
                        forcedOut = true;
                        isValid   = false;
                        try {
                            existingSession.invalidate();
                        } catch (Exception ignored) {}
                    }
                }

            } catch (Exception e) {
                // On DB error — keep session valid to avoid false logouts
                isValid = true;
            } finally {
                try { if (rs   != null) rs.close();  } catch (Exception ignored) {}
                try { if (ps   != null) ps.close();  } catch (Exception ignored) {}
                try { if (conn != null) conn.close(); } catch (Exception ignored) {}
            }
        }
    }
%>
{"sessionValid": <%= isValid %>, "forcedOut": <%= forcedOut %>}
