<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page language="java" %>
<%
    // Get user details from session before invalidating
    String userId = (String) session.getAttribute("userId");
    String branchCode = (String) session.getAttribute("branchCode");
    
    // Update logout status in database
    if (userId != null && branchCode != null) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = DBConnection.getConnection();
            
            // 1. Update CURRENTLOGIN_STATUS to 'U' in USERREGISTER table
            String updateStatusSql = "UPDATE ACL.USERREGISTER SET CURRENTLOGIN_STATUS = 'U' WHERE USER_ID = ? AND BRANCH_CODE = ?";
            pstmt = conn.prepareStatement(updateStatusSql);
            pstmt.setString(1, userId);
            pstmt.setString(2, branchCode);
            pstmt.executeUpdate();
            pstmt.close();
            
            // 2. Update LOGOUT_TIME in USERREGISTERLOGINHISTORY table for the latest login record
            String updateLogoutTimeSql = "UPDATE ACL.USERREGISTERLOGINHISTORY SET LOGOUT_TIME = SYSDATE " +
                                         "WHERE USER_ID = ? AND BRANCH_CODE = ? AND LOGOUT_TIME IS NULL " +
                                         "AND LOGIN_TIME = (SELECT MAX(LOGIN_TIME) FROM ACL.USERREGISTERLOGINHISTORY " +
                                         "WHERE USER_ID = ? AND BRANCH_CODE = ?)";
            pstmt = conn.prepareStatement(updateLogoutTimeSql);
            pstmt.setString(1, userId);
            pstmt.setString(2, branchCode);
            pstmt.setString(3, userId);
            pstmt.setString(4, branchCode);
            pstmt.executeUpdate();
            
        } catch (Exception e) {
            // Log the error but continue with logout
            System.err.println("Error updating logout status: " + e.getMessage());
            e.printStackTrace();
        } finally {
            try { if (pstmt != null) pstmt.close(); } catch (Exception ignored) {}
            try { if (conn != null) conn.close(); } catch (Exception ignored) {}
        }
    }
    
    // Destroy session
    session.invalidate();
    
    // Redirect to login page
    response.sendRedirect("login.jsp");
%>
