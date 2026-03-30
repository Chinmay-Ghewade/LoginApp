package db;

import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpSessionEvent;
import javax.servlet.http.HttpSessionListener;
import javax.servlet.annotation.WebListener;
import java.sql.Connection;
import java.sql.PreparedStatement;

@WebListener
public class SessionListener implements HttpSessionListener {

    @Override
    public void sessionCreated(HttpSessionEvent se) {
        // Nothing needed here
    }

    @Override
    public void sessionDestroyed(HttpSessionEvent se) {
        HttpSession session = se.getSession();

        try {
            String userId     = (String) session.getAttribute("userId");
            String branchCode = (String) session.getAttribute("branchCode");

            if (userId == null || branchCode == null) return;

            Connection conn = null;
            PreparedStatement ps = null;

            try {
                conn = DBConnection.getConnection();

                // 1. Reset login status AND clear SESSION_ID
                ps = conn.prepareStatement(
                    "UPDATE ACL.USERREGISTER " +
                    "SET CURRENTLOGIN_STATUS = 'U', SESSION_ID = NULL " +
                    "WHERE USER_ID = ? AND BRANCH_CODE = ?"
                );
                ps.setString(1, userId);
                ps.setString(2, branchCode);
                ps.executeUpdate();
                ps.close();

                // 2. Update logout time in history
                ps = conn.prepareStatement(
                    "UPDATE ACL.USERREGISTERLOGINHISTORY SET LOGOUT_TIME = SYSDATE " +
                    "WHERE USER_ID = ? AND BRANCH_CODE = ? AND LOGOUT_TIME IS NULL " +
                    "AND LOGIN_TIME = (SELECT MAX(LOGIN_TIME) FROM ACL.USERREGISTERLOGINHISTORY " +
                    "WHERE USER_ID = ? AND BRANCH_CODE = ?)"
                );
                ps.setString(1, userId);
                ps.setString(2, branchCode);
                ps.setString(3, userId);
                ps.setString(4, branchCode);
                ps.executeUpdate();

            } finally {
                try { if (ps   != null) ps.close();  } catch (Exception ignored) {}
                try { if (conn != null) conn.close(); } catch (Exception ignored) {}
            }

        } catch (Exception e) {
            System.err.println("SessionListener error: " + e.getMessage());
        }
    }
}