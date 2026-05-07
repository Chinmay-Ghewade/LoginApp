<%@ page import="java.sql.*, db.DBConnection" %> 
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<link rel="stylesheet" href="../css/lookup-modal.css">

<%
    // Get branch code from session
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String branchCode = (String) sess.getAttribute("branchCode");
    String type = request.getParameter("type");
    String accType = request.getParameter("accType");

    // Validate type parameter
    if (type == null || (!type.equals("account") && !type.equals("product"))) {
%>
        <div class="error-message">Invalid lookup type</div>
<%
        return;
    }

    String query = "";
    
    if ("account".equals(type)) {
        query = "SELECT ACCOUNT_TYPE, NAME FROM HEADOFFICE.ACCOUNTTYPE ORDER BY ACCOUNT_TYPE";
    } 
    else if ("product".equals(type)) {
        if (accType == null || accType.trim().isEmpty()) {
%>
            <div class="error-message">Account Type is required for product lookup</div>
<%
            return;
        }
        query = "SELECT PRODUCT_CODE, DESCRIPTION FROM HEADOFFICE.PRODUCT WHERE ACCOUNT_TYPE = ? ORDER BY PRODUCT_CODE";
    }

    try (Connection con = DBConnection.getConnection();
         PreparedStatement ps = con.prepareStatement(query)) {
        
        // Set parameter for product query
        if ("product".equals(type)) {
            ps.setString(1, accType);
        }
        
        try (ResultSet rs = ps.executeQuery()) {
%>

<div class="lookup-title">
    Select <%= ("account".equals(type) ? "Account Type" : "Product Code") %>
</div>

<table class="lookup-standalone-table">
    <tr>
        <th>Code</th>
        <th>Description</th>
    </tr>

<%
            boolean hasRecords = false;
            while (rs.next()) {
                hasRecords = true;
                String code = rs.getString(1);
                String desc = rs.getString(2);
%>

    <tr onclick="sendBack('<%=code%>', '<%=desc%>', '<%=type%>')">
        <td><%=code%></td>
        <td><%=desc%></td>
    </tr>

<% 
            }
            
            if (!hasRecords) {
%>
    <tr>
        <td colspan="2" style="text-align:center; color:#999;">
            No records found
        </td>
    </tr>
<%
            }
%>
</table>

<%
        }
    } catch (SQLException e) {
        e.printStackTrace();
%>
        <div class="error-message">
            Database error occurred: <%= e.getMessage() %>
        </div>
<%
    }
%>

<script>
function sendBack(code, desc, type) {
    if (window.parent && window.parent.setLookupData) {
        window.parent.setLookupData(code, desc, type);
    } else if (window.setLookupData) {
        window.setLookupData(code, desc, type);
    } else {
        // Fallback mechanism
        if (type === 'account') {
            parent.document.getElementById('accountType').value = code;
            parent.document.getElementById('accountTypeName').value = desc;
        } else if (type === 'product') {
            parent.document.getElementById('productCode').value = code;
            parent.document.getElementById('productDesc').value = desc;
        }
        
        if (parent.closeLookup) {
            parent.closeLookup();
        }
    }
}
</script>