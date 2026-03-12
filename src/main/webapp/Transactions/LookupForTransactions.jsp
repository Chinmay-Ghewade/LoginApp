<%@ page import="java.sql.*, db.DBConnection" %> 
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Get branch code from session
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String branchCode = (String) sess.getAttribute("branchCode");
    String type = request.getParameter("type");
    String accountCategory = request.getParameter("accountCategory");
    String query = "";

    if ("transaction".equals(type)) {
        query = "SELECT CODE_TYPE, DESCRIPTION FROM HEADOFFICE.TRANSACTIONS_TYPE ORDER BY CODE_TYPE";
    } 
    else if ("accountType".equals(type)) {
        query = "SELECT ACCOUNT_TYPE, NAME FROM HEADOFFICE.ACCOUNTTYPE ORDER BY ACCOUNT_TYPE";
    }
    else if ("product".equals(type)) {
        String accType = request.getParameter("accType");
        query = "SELECT PRODUCT_CODE, DESCRIPTION FROM HEADOFFICE.PRODUCT WHERE ACCOUNT_TYPE = ? ORDER BY PRODUCT_CODE";
    }
    else if ("account".equals(type) || "dynamicCredit".equals(type)) {
        // Map account categories to product code starting digits
        String productCodePattern = "";
        switch(accountCategory) {
            case "saving":
                productCodePattern = "2%";
                break;
            case "loan":
                productCodePattern = "[57]%";
                break;
            case "deposit":
                productCodePattern = "4%";
                break;
            case "pigmy":
                productCodePattern = "6%";
                break;
            case "current":
                productCodePattern = "1%";
                break;
            case "cc":
                productCodePattern = "3%";
                break;
            default:
                productCodePattern = "%";
        }
        
        // Build query based on category 
        if ("loan".equals(accountCategory)) {
            // Special case for loan (5 or 7)
            query = "SELECT ACCOUNT_CODE, NAME, " +
                    "FN_GET_PRODUCT_DESC(SUBSTR(ACCOUNT_CODE, 5, 3)) AS PRODUCT_DESC " +
                    "FROM ACCOUNT.ACCOUNT " +
                    "WHERE SUBSTR(ACCOUNT_CODE, 1, 4) = ? " +
                    "AND (SUBSTR(ACCOUNT_CODE, 5, 1) = '5' OR SUBSTR(ACCOUNT_CODE, 5, 1) = '7') " +
                    "AND ACCOUNT_STATUS = 'L' " +
                    "ORDER BY ACCOUNT_CODE";
        } else {
            query = "SELECT ACCOUNT_CODE, NAME, " +
                    "FN_GET_PRODUCT_DESC(SUBSTR(ACCOUNT_CODE, 5, 3)) AS PRODUCT_DESC " +
                    "FROM ACCOUNT.ACCOUNT " +
                    "WHERE SUBSTR(ACCOUNT_CODE, 1, 4) = ? " +
                    "AND SUBSTR(ACCOUNT_CODE, 5, 1) = ? "+ 
                    "AND ACCOUNT_STATUS = 'L' " +
                    "ORDER BY ACCOUNT_CODE";
        }
    }

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    
    try {
        con = DBConnection.getConnection();
        ps = con.prepareStatement(query);
        
        // Set parameter for product lookup
        if ("product".equals(type)) {
            String accType = request.getParameter("accType");
            ps.setString(1, accType);
        }
        // Set parameters for account lookup
        else if ("account".equals(type)) {
            ps.setString(1, branchCode);
            
            // Set second parameter only for non-loan categories
            if (!"loan".equals(accountCategory)) {
                String productCodePattern = "";
                switch(accountCategory) {
                    case "saving": productCodePattern = "2"; break;
                    case "deposit": productCodePattern = "4"; break;
                    case "pigmy": productCodePattern = "6"; break;
                    case "current": productCodePattern = "1"; break;
                    case "cc": productCodePattern = "3"; break;
                    default: productCodePattern = "%";
                }
                ps.setString(2, productCodePattern);
            }
        }
        
        rs = ps.executeQuery();
%>

<style>
table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 10px;
}
th, td {
    border: 1px solid #999;
    padding: 10px;
    cursor: pointer;
}
th {
    background-color: #373279;
    color: white;
    font-weight: bold;
}
tr:hover { 
    background-color: #e8e4fc;
}
.lookup-title {
    font-size: 20px;
    margin-bottom: 10px;
    font-weight: bold;
    color: #373279;
}

.no-results {
    text-align: center;
    padding: 20px;
    color: #999;
    font-style: italic;
}
.category-badge {
    display: inline-block;
    padding: 4px 12px;
    margin-left: 10px;
    background-color: #8066E8;
    color: white;
    border-radius: 15px;
    font-size: 12px;
    font-weight: bold;
}

.search-container {
        text-align: center;
    }
    .search-container input {
        width: 40%;
        padding: 8px;
        font-size: 14px;
        border: 1px solid #ccc;
        border-radius: 4px;
    }
    
    .product-badge {
	    font-size: 16px;
	    padding: 4px 12px;
	    border-radius: 4px;
	    white-space: nowrap;
	    display: inline-block;
	}
	
</style>

<div class="lookup-title">
    Select <%= ("transaction".equals(type) ? "Transaction Type" : 
                 "accountType".equals(type) ? "Account Type" : 
                 "product".equals(type) ? "Product Code" : "Account") %>
    <% if ("account".equals(type) && accountCategory != null) { %>
        <span class="category-badge"><%= accountCategory.toUpperCase() %></span>
    <% } %>
</div>

<% if ("account".equals(type)) { %>
   <div class="search-container">
   <input id="searchBox" 
           class="search-box" 
           placeholder="🔍 Search by Account Code or Name..." 
           onkeyup="filterTable()">
           </div>
<% } %>

<table id="lookupTable">
    <tr>
        <th>Code</th>
        <th><%= "account".equals(type) ? "Name" : "Description" %></th>
        <% if ("account".equals(type)) { %>
            <th>Product</th>
        <% } %>
    </tr>

<%
        int rowCount = 0;
        while (rs.next()) {
            String code = rs.getString(1);
            String desc = rs.getString(2);
            String productDesc = "";
            
            // Get product description for account type
            if ("account".equals(type)) {
                productDesc = rs.getString(3);
                if (productDesc == null) productDesc = "";
            }
            
            rowCount++;
%>

    <tr class="data-row" onclick="sendBack('<%=code%>', '<%=desc%>', '<%=type%>')">
        <td><%=code%></td>
        <td><%=desc%></td>
        <% if ("account".equals(type)) { %>
            <td><span class="product-badge"><%=productDesc%></span></td>
        <% } %>
    </tr>

<% 
        }
        
        if (rowCount == 0) {
%>
    <tr>
        <td colspan="2" class="no-results">
            No accounts found for <%= accountCategory != null ? accountCategory.toUpperCase() : "selected" %> category
        </td>
    </tr>
<%
        }
    } catch (SQLException e) {
        out.println("<tr><td colspan='2' style='color: red; text-align: center;'>Error loading data: " + e.getMessage() + "</td></tr>");
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch(SQLException e) {}
        if (ps != null) try { ps.close(); } catch(SQLException e) {}
        if (con != null) try { con.close(); } catch(SQLException e) {}
    }
%>
</table>