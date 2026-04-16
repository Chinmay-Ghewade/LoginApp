package servlet;

import java.io.IOException;
import java.sql.*;
import java.text.SimpleDateFormat;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import db.DBConnection;

@WebServlet("/Authorization/UpdateTransactionStatusServlet")
public class UpdateTransactionStatusServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Session validation
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("branchCode") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String branchCode = (String) session.getAttribute("branchCode");
        String scrollNumber = request.getParameter("scrollNumber");
        String type = request.getParameter("type");
        String status = request.getParameter("status");
        String userId = (String) session.getAttribute("userId");

        if (scrollNumber == null || scrollNumber.trim().isEmpty()) {
            response.sendRedirect("authorizationPendingTransactionCash.jsp?error=Invalid%20Scroll%20Number");
            return;
        }

        Connection conn = null;
        PreparedStatement ps = null;

        try {
            conn = DBConnection.getConnection();

            // Get working date from session, if available
            Date workingDate = null;
            Object workingDateObj = session.getAttribute("workingDate");
            
            if (workingDateObj != null && workingDateObj instanceof Date) {
                workingDate = (Date) workingDateObj;
            } else {
                workingDate = new java.sql.Date(System.currentTimeMillis());
            }
            if (userId == null || userId.trim().isEmpty()) {
                response.sendRedirect("authorizationPendingTransactionCash.jsp?error=Invalid%20User%20ID");
                return;
            }

            // Update TRANSACTION.TRANSACTION table
            String updateQuery = "UPDATE TRANSACTION.DAILYSCROLL SET " +
                                 "TRANSACTIONSTATUS = ?, " +
                                 "AUTHORISE_DATE = ?, " +
                                 "OFFICER_ID = ? " +
                                 "WHERE SCROLL_NUMBER = ? " +
                                 "AND BRANCH_CODE = ? " +
                                 "AND TRANSACTIONINDICATOR_CODE LIKE 'CS%'";

            ps = conn.prepareStatement(updateQuery);
            ps.setString(1, status);        // "A" for Authorize, "R" for Reject
            ps.setDate(2, workingDate);
            ps.setString(3, userId);
            ps.setString(4, scrollNumber);
            ps.setString(5, branchCode);

            int rowsUpdated = ps.executeUpdate();

            if (rowsUpdated > 0) {
                String successMsg = status.equals("A") ? "Authorized" : "Rejected";
                response.sendRedirect("authorizationPendingTransactionCash.jsp?success=Transaction%20" + 
                                    successMsg + "%20successfully");
            } else {
                response.sendRedirect("authorizationPendingTransactionCash.jsp?error=No%20transaction%20found");
            }

        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("authorizationPendingTransactionCash.jsp?error=" + 
                                java.net.URLEncoder.encode("Database Error: " + e.getMessage()));
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("authorizationPendingTransactionCash.jsp?error=" + 
                                java.net.URLEncoder.encode("Error: " + e.getMessage()));
        } finally {
            try {
                if (ps != null) ps.close();
            } catch (Exception ex) {
                ex.printStackTrace();
            }
            try {
                if (conn != null) conn.close();
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }
    }
}
