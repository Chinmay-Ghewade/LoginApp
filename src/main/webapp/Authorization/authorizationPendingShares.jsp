<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*, db.DBConnection" %>

<%
    String branchCode = (String) session.getAttribute("branchCode");
    if (branchCode == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Authorization Pending Shares</title>

<link rel="stylesheet" href="../css/totalCustomers.css">

<style>
body {
    font-family: Arial, sans-serif;
    background: #E6E6FA;
    margin: 0;
    padding: 20px;
}
html, body { overflow-x: hidden; }
.container { max-width: 1400px; margin: auto; }
h2 {
    text-align: center;
    color: #2b0d73;
    font-weight: 700;
    margin-bottom: 18px;
    font-size: 24px;
}
.search-box { width: 650px; margin: 0 auto 18px auto; }
.search-box input {
    width: 100%;
    padding: 8px 12px;
    border-radius: 4px;
    border: 1px solid #B8B8E6;
    font-size: 13px;
    background: #FFFFFF;
    box-sizing: border-box;
    color: #444;
}
.table-card {
    background: #fff;
    border-radius: 6px;
    box-shadow: 0 2px 6px rgba(0,0,0,0.10);
    overflow: auto;
    border: 1px solid #B8B8E6;
    max-height: 500px;
}
table { width: 100%; border-collapse: collapse; font-size: 13px; }
thead tr { background: #303F9F; }
th {
    color: #FFFFFF;
    padding: 6px 8px;
    text-align: center;
    font-weight: 600;
    font-size: 12.5px;
    border-right: 1px solid rgba(255,255,255,0.2);
}
th:last-child { border-right: none; }
tbody tr:nth-child(odd)  { background: #F7F7F7; }
tbody tr:nth-child(even) { background: #FFFFFF; }
td {
    padding: 5px 8px;
    text-align: left;
    border-right: 1px solid #e3e3e3;
}
td:last-child { border-right: none; }
.action-btn {
    background: #2b0d73;
    color: #FFFFFF;
    border: none;
    padding: 3px 10px;
    border-radius: 3px;
    font-size: 12px;
    cursor: pointer;
    font-weight: 400;
}
.action-btn:hover { background: #1E2870; }
.no-data {
    text-align: center;
    padding: 30px;
    color: #666;
    font-size: 14px;
}
.error-banner {
    background: #fff0f0;
    border: 1px solid #f5b8b8;
    border-radius: 4px;
    padding: 10px 14px;
    color: #c0392b;
    font-size: 13px;
    margin-bottom: 14px;
    word-break: break-word;
}
</style>
</head>

<body>
<div class="container">

    <h2>Authorization Pending Shares for Branch: <%=branchCode%></h2>

    <div class="search-box">
        <input type="text"
               id="searchInput"
               onkeyup="searchTable()"
               placeholder="🔍 Search by Name, Account Code, Branch">
    </div>

<%
Connection conn  = null;
PreparedStatement pstmt = null;
ResultSet rs     = null;
String errorMsg  = null;
int srNo         = 1;

java.util.List<String[]> rows = new java.util.ArrayList<>();

try {
    conn = DBConnection.getConnection();

    // Show all pending records for this branch (including null BR_CODE)
    String sql =
        "SELECT cm.BR_CODE, " +
        "       cm.ACCOUNT_NUMBER, " +
        "       FN_GET_ACCOUNT_NAME(cm.ACCOUNT_NUMBER) AS ACCOUNT_NAME, " +
        "       cm.MEETING_DATE " +
        "FROM SHARES.CERTIFICATE_MASTER cm " +
        "WHERE cm.STATUS = 'E' " +
        "AND NVL(cm.BR_CODE, 'NULL') = NVL(?, 'NULL') " +
        "ORDER BY cm.MEETING_DATE DESC";

    pstmt = conn.prepareStatement(sql);
    pstmt.setString(1, branchCode);
    rs = pstmt.executeQuery();

    while (rs.next()) {
        String accountCode = rs.getString("ACCOUNT_NUMBER");
        String branchCol   = rs.getString("BR_CODE");
        String accountName = rs.getString("ACCOUNT_NAME");

        java.sql.Date meetingDate = rs.getDate("MEETING_DATE");
        String meetingDateStr = "";
        if (meetingDate != null) {
            meetingDateStr = new java.text.SimpleDateFormat("dd-MMM-yyyy").format(meetingDate);
        }

        rows.add(new String[]{
            branchCol   != null ? branchCol   : "",
            accountCode != null ? accountCode : "",
            accountName != null ? accountName : "",
            meetingDateStr
        });
    }

} catch (Exception e) {
    errorMsg = e.getClass().getName() + ": " + e.getMessage();
} finally {
    if (rs    != null) try { rs.close();    } catch (Exception ex) {}
    if (pstmt != null) try { pstmt.close(); } catch (Exception ex) {}
    if (conn  != null) try { conn.close();  } catch (Exception ex) {}
}
%>

<% if (errorMsg != null) { %>
    <div class="error-banner"><strong>Database Error:</strong> <%=errorMsg%></div>
<% } %>

    <div class="table-card">
        <table id="sharesTable">
            <thead>
            <tr>
                <th>Sr. No.</th>
                <th>Branch</th>
                <th>Account Code</th>
                <th>Name</th>
                <th>Meeting Date</th>
                <th>Action</th>
            </tr>
            </thead>
            <tbody>

<% if (rows.isEmpty() && errorMsg == null) { %>
            <tr>
                <td colspan="6" class="no-data">No pending shares found for branch <%=branchCode%></td>
            </tr>
<% } %>

<% for (String[] row : rows) {
       String branchCol   = row[0];
       String accountCode = row[1];
       String accountName = row[2];
       String meetingDate = row[3];
%>
            <tr>
                <td><%=srNo++%></td>
                <td><%=branchCol%></td>
                <td><%=accountCode%></td>
                <td><%=accountName%></td>
                <td><%=meetingDate%></td>
                <td>
                    <button class="action-btn"
                            onclick="openDetails('<%=accountCode%>', '<%=branchCol%>')">
                        View Details
                    </button>
                </td>
            </tr>
<% } %>

            </tbody>
        </table>
    </div>

</div>

<script>
function openDetails(accountCode, branchCode) {
    var url = "Authorization/authViewShares.jsp"
            + "?accountCode=" + encodeURIComponent(accountCode)
            + "&branchCode="  + encodeURIComponent(branchCode);

    if (window.parent && window.parent.document) {
        var iframe = window.parent.document.getElementById("contentFrame");
        if (iframe) {
            iframe.src = url;
            if (window.parent.updateParentBreadcrumb) {
                window.parent.updateParentBreadcrumb("Authorization > Pending Shares > View");
            }
            return;
        }
    }
    window.location.href = url;
}

function searchTable() {
    let input  = document.getElementById("searchInput");
    let filter = input.value.toLowerCase();
    let table  = document.getElementById("sharesTable");
    let tr     = table.getElementsByTagName("tr");

    for (let i = 1; i < tr.length; i++) {
        let tds   = tr[i].getElementsByTagName("td");
        let found = false;
        for (let j = 0; j < tds.length; j++) {
            if (tds[j]) {
                let text = tds[j].textContent || tds[j].innerText;
                if (text.toLowerCase().indexOf(filter) > -1) { found = true; break; }
            }
        }
        tr[i].style.display = found ? "" : "none";
    }
}
</script>

</body>
</html>
