<%@ page import="java.sql.*, db.DBConnection" %> 
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect("../login.jsp");
        return;
    }

    String branchCode = (String) sess.getAttribute("branchCode");
    
    // ✅ ENHANCED: Accept multiple customer IDs to exclude (comma-separated)
    String excludeCustomerIds = request.getParameter("excludeCustomerIds");
    
    String query;
    if (excludeCustomerIds != null && !excludeCustomerIds.trim().isEmpty()) {
        // Split comma-separated IDs and build IN clause
        String[] idsArray = excludeCustomerIds.split(",");
        StringBuilder placeholders = new StringBuilder();
        for (int i = 0; i < idsArray.length; i++) {
            placeholders.append("?");
            if (i < idsArray.length - 1) placeholders.append(",");
        }
        
        query = "SELECT CUSTOMER_ID, CUSTOMER_NAME, CATEGORY_CODE, RISK_CATEGORY " +
                "FROM CUSTOMERS " +
                "WHERE BRANCH_CODE = ? AND STATUS = 'A' AND CUSTOMER_ID NOT IN (" + placeholders + ") " +
                "ORDER BY CUSTOMER_ID";
    } else {
        query = "SELECT CUSTOMER_ID, CUSTOMER_NAME, CATEGORY_CODE, RISK_CATEGORY " +
                "FROM CUSTOMERS " +
                "WHERE BRANCH_CODE = ? AND STATUS = 'A' " +
                "ORDER BY CUSTOMER_ID";
    }

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    
    try {
        con = DBConnection.getConnection();
        ps = con.prepareStatement(query);
        ps.setString(1, branchCode);
        
        // Bind excluded customer IDs if provided
        if (excludeCustomerIds != null && !excludeCustomerIds.trim().isEmpty()) {
            String[] idsArray = excludeCustomerIds.split(",");
            for (int i = 0; i < idsArray.length; i++) {
                ps.setString(i + 2, idsArray[i].trim());
            }
        }
        
        rs = ps.executeQuery();
%>

<div class="lookup-title">🔍 Select Customer</div>

<div class="search-box">
    <input type="text" 
           id="customerSearch" 
           placeholder="Search by Customer ID or Name..." 
           onkeyup="searchCustomer()">
</div>

<div class="customer-count">
    Total Customers: <strong id="customerCount">0</strong>
</div>

<div class="table-container">
    <table id="customerTable">
        <thead>
            <tr>
                <th>Customer ID</th>
                <th>Customer Name</th>
                <th>Category Code</th>
                <th>Risk Category</th>
            </tr>
        </thead>
        <tbody>
<%
        boolean hasResults = false;
        int totalCount = 0;
        
        while (rs.next()) {
            hasResults = true;
            totalCount++;
            
            String customerId = rs.getString("CUSTOMER_ID");
            String customerName = rs.getString("CUSTOMER_NAME");
            String categoryCode = rs.getString("CATEGORY_CODE");
            String riskCategory = rs.getString("RISK_CATEGORY");
            
            customerName = (customerName != null) ? customerName : "";
            categoryCode = (categoryCode != null) ? categoryCode : "";
            riskCategory = (riskCategory != null) ? riskCategory : "";
%>
            <tr onclick="setCustomerData('<%= customerId %>', '<%= customerName.replace("'", "\\'") %>', '<%= categoryCode %>', '<%= riskCategory %>')">
                <td><%= customerId %></td>
                <td><%= customerName %></td>
                <td><%= categoryCode %></td>
                <td><%= riskCategory %></td>
            </tr>
<%
        }
        
        if (!hasResults) {
%>
        <tr>
            <td colspan="4" style="text-align:center;padding:40px;color:#666;">
                <strong>⚠️ No Authorized Customers Found</strong>
                <br><br>
                Please add and authorize customers first.
            </td>
        </tr>
<%
        }
%>
        </tbody>
    </table>
</div>

<script>
document.getElementById('customerCount').textContent = '<%= totalCount %>';

function searchCustomer() {
    const input = document.getElementById('customerSearch');
    const filter = input.value.toUpperCase();
    const table = document.getElementById('customerTable');
    const tbody = table.getElementsByTagName('tbody')[0];
    const rows = tbody.getElementsByTagName('tr');
    
    let visibleCount = 0;
    
    for (let i = 0; i < rows.length; i++) {
        const cells = rows[i].getElementsByTagName('td');
        
        if (cells.length === 1) continue;
        
        let found = false;
        
        for (let j = 0; j < Math.min(cells.length, 2); j++) {
            const cellText = cells[j].textContent || cells[j].innerText;
            if (cellText.toUpperCase().indexOf(filter) > -1) {
                found = true;
                break;
            }
        }
        
        if (found) {
            rows[i].style.display = '';
            visibleCount++;
        } else {
            rows[i].style.display = 'none';
        }
    }
    
    document.getElementById('customerCount').textContent = visibleCount;
}
</script>

<%
    } catch (Exception e) {
        out.println("<div style='text-align:center;padding:40px;color:red;'>");
        out.println("<strong>❌ Error Loading Customers</strong><br><br>");
        out.println("Error: " + e.getMessage());
        out.println("</div>");
        e.printStackTrace();
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ex) {}
        try { if (ps != null) ps.close(); } catch (Exception ex) {}
        try { if (con != null) con.close(); } catch (Exception ex) {}
    }
%>