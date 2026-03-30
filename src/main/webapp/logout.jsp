<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page language="java" %>
<%
    HttpSession existingSession = request.getSession(false);

    if (existingSession != null) {
        // SessionListener will automatically handle DB update when invalidate() is called
        existingSession.invalidate();
    }

    response.sendRedirect("login.jsp");
%>