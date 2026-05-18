package servlet;

import db.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

@WebServlet("/CheckAadharServlet")
public class CheckAadharServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json; charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        String aadhar = request.getParameter("aadhar");
        
        if (aadhar == null || aadhar.trim().isEmpty()) {
            out.print("{\"exists\": false}");
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            
            // Updated query to fetch STATUS column as well
            String sql = "SELECT CUSTOMER_ID, STATUS FROM CUSTOMERS WHERE AADHAR = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, aadhar.trim());
            
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                String customerId = rs.getString("CUSTOMER_ID");
                String status = rs.getString("STATUS");
                
                // Return both customerId and status
                out.print("{\"exists\": true, \"customerId\": \"" + customerId + "\", \"status\": \"" + status + "\"}");
            } else {
                out.print("{\"exists\": false}");
            }
            
        } catch (Exception e) {
            System.out.println("Aadhar check error: " + e.getMessage());
            out.print("{\"exists\": false, \"error\": \"" + e.getMessage() + "\"}");
        } finally {
            try { if (rs != null) rs.close(); } catch (Exception ignored) {}
            try { if (pstmt != null) pstmt.close(); } catch (Exception ignored) {}
            try { if (conn != null) conn.close(); } catch (Exception ignored) {}
        }
    }
}