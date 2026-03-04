package servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import db.DBConnection;
import db.AESEncryption;

@WebServlet("/Authorization/UserAuthorizationServlet")
public class UserAuthorizationServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        String userId       = request.getParameter("userId");
        String status       = request.getParameter("status");
        String password     = request.getParameter("password");
        String branchCode   = request.getParameter("branchCode");
        String authorizedBy = (session != null) ? (String) session.getAttribute("userId") : null;

        System.out.println("=== UserAuthorizationServlet START ===");
        System.out.println("userId       = " + userId);
        System.out.println("branchCode   = " + branchCode);
        System.out.println("status       = " + status);
        System.out.println("authorizedBy = " + authorizedBy);

        if (userId == null || userId.trim().isEmpty() ||
            authorizedBy == null || authorizedBy.trim().isEmpty()) {
            System.out.println("VALIDATION FAILED - redirecting");
            response.sendRedirect(request.getContextPath() + "/Authorization/authorizationPendingUsers.jsp");
            return;
        }

        Connection conn = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);
            System.out.println("DB connection obtained, autoCommit=false");

            // ================= AUTHORIZE =================
            if ("A".equals(status)) {

                // Encrypt password using AES-256 (replaces oracle toolkit.encrypt)
                String encryptedPassword;
                try {
                    encryptedPassword = AESEncryption.encrypt(password);
                    System.out.println("Password encrypted with AES-256");
                } catch (Exception e) {
                    System.out.println("PASSWORD ENCRYPTION ERROR: " + e.getMessage());
                    e.printStackTrace();
                    conn.rollback();
                    if (session != null) {
                        session.setAttribute("message", "Password encryption failed: " + e.getMessage());
                        session.setAttribute("messageType", "error");
                    }
                    response.sendRedirect(request.getContextPath() + "/Authorization/authorizationPendingUsers.jsp");
                    return;
                }

                // STEP 1: Update USERREGISTER — STATUS='A', AES encrypted password, record authorizer
                System.out.println("STEP 1: Updating USERREGISTER with AES encrypted password...");
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE ACL.USERREGISTER " +
                        "SET STATUS = 'A', PASSWD = ?, AUTHORIZED_BY = ? " +
                        "WHERE USER_ID = ? AND BRANCH_CODE = ?")) {
                    ps.setString(1, encryptedPassword);  // AES encrypted password
                    ps.setString(2, authorizedBy);
                    ps.setString(3, userId);
                    ps.setString(4, branchCode);
                    int rows = ps.executeUpdate();
                    System.out.println("STEP 1 done: rows updated in USERREGISTER = " + rows);
                    
                    if (rows == 0) {
                        System.out.println("WARNING: No rows updated for userId=" + userId + ", branchCode=" + branchCode);
                    }
                }

                // STEP 2: Update USERPENDINGROLES — STATUS='A', record authorizer + date
                System.out.println("STEP 2: Updating USERPENDINGROLES...");
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE ACL.USERPENDINGROLES " +
                        "SET STATUS = 'A', AUTHORIZED_BY = ?, AUTHORIZED_DATE = SYSDATE " +
                        "WHERE USER_ID = ? AND STATUS = 'P'")) {
                    ps.setString(1, authorizedBy);
                    ps.setString(2, userId);
                    int rows = ps.executeUpdate();
                    System.out.println("STEP 2 done: rows updated in USERPENDINGROLES = " + rows);
                }

                // STEP 3: DELETE old roles from USERMAINROLE for this user
                // This ensures if the same user was edited again, old roles are fully replaced
                System.out.println("STEP 3: Deleting old roles from USERMAINROLE...");
                try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM ACL.USERMAINROLE WHERE USER_ID = ?")) {
                    ps.setString(1, userId);
                    int rows = ps.executeUpdate();
                    System.out.println("STEP 3 done: rows deleted from USERMAINROLE = " + rows);
                }

                // STEP 4: Insert fresh roles into USERMAINROLE from newly authorized USERPENDINGROLES
                System.out.println("STEP 4: Inserting new roles into USERMAINROLE...");
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO ACL.USERMAINROLE (USER_ID, MAINROLE_ID, CREATED_DATE) " +
                        "SELECT USER_ID, MAINROLE_ID, SYSDATE " +
                        "FROM ACL.USERPENDINGROLES " +
                        "WHERE USER_ID = ? AND STATUS = 'A'")) {
                    ps.setString(1, userId);
                    int rows = ps.executeUpdate();
                    System.out.println("STEP 4 done: rows inserted into USERMAINROLE = " + rows);
                }

                conn.commit();
                System.out.println("COMMIT done - Authorize complete with AES encryption");

                session.setAttribute("message",     "User Authorized Successfully! Password encrypted with AES-256");
                session.setAttribute("messageType", "success");
            }

            // ================= REJECT =================
            else if ("R".equals(status)) {

                // STEP 1: Update USERREGISTER — STATUS='R', record authorizer
                // Note: No password update on rejection, just status
                System.out.println("STEP 1: Updating USERREGISTER for REJECT...");
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE ACL.USERREGISTER " +
                        "SET STATUS = 'R', AUTHORIZED_BY = ? " +
                        "WHERE USER_ID = ? AND BRANCH_CODE = ?")) {
                    ps.setString(1, authorizedBy);
                    ps.setString(2, userId);
                    ps.setString(3, branchCode);
                    int rows = ps.executeUpdate();
                    System.out.println("STEP 1 done: rows updated in USERREGISTER = " + rows);
                }

                // STEP 2: Update USERPENDINGROLES — STATUS='R', record authorizer + date
                System.out.println("STEP 2: Updating USERPENDINGROLES for REJECT...");
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE ACL.USERPENDINGROLES " +
                        "SET STATUS = 'R', AUTHORIZED_BY = ?, AUTHORIZED_DATE = SYSDATE " +
                        "WHERE USER_ID = ? AND STATUS = 'P'")) {
                    ps.setString(1, authorizedBy);
                    ps.setString(2, userId);
                    int rows = ps.executeUpdate();
                    System.out.println("STEP 2 done: rows updated in USERPENDINGROLES = " + rows);
                }

                conn.commit();
                System.out.println("COMMIT done - Reject complete");

                session.setAttribute("message",     "User Rejected Successfully!");
                session.setAttribute("messageType", "success");
            }

        } catch (SQLException e) {
            System.out.println("EXCEPTION: " + e.getMessage());
            e.printStackTrace();
            if (conn != null) try { conn.rollback(); System.out.println("ROLLBACK done"); } catch (SQLException ignored) {}
            if (session != null) {
                session.setAttribute("message",     "Operation failed: " + e.getMessage());
                session.setAttribute("messageType", "error");
            }
        } finally {
            if (conn != null) try { conn.setAutoCommit(true); conn.close(); } catch (SQLException ignored) {}
        }

        System.out.println("=== UserAuthorizationServlet END ===");
        response.sendRedirect(request.getContextPath() + "/Authorization/authorizationPendingUsers.jsp");
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doPost(request, response);
    }
}