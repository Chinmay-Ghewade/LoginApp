<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    String branchCode = (String) session.getAttribute("branchCode");
    
    if (branchCode == null) {
        response.sendRedirect("../login.jsp");
        return;
    }

    // Load card structure from database (optional - you can hardcode if not in DB)
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    
    java.util.List<java.util.Map<String, String>> cards = new java.util.ArrayList<>();
    
    try {
        // If you have locker cards in GLOBALCONFIG.DASHBOARD, fetch them
        // Otherwise, we'll hardcode them below
        conn = DBConnection.getConnection();
        // You can add your query here if cards are in database
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ex) {}
        try { if (ps != null) ps.close(); } catch (Exception ex) {}
        try { if (conn != null) conn.close(); } catch (Exception ex) {}
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Locker Management</title>
<link rel="stylesheet" href="../css/cardView.css">
</head>

<body>
<div class="dashboard-container">
    <div class="cards-wrapper">
        
        <!-- Card 1: Locker Issues -->
        <div class="card" onclick="openPage('lockerIssues')">
            <h3>Locker Issues</h3>
            <p class="size-1">→</p>
        </div>
        
        <!-- Card 2: Locker Attendance -->
        <div class="card" onclick="openPage('lockerAttendance')">
            <h3>Locker Attendance</h3>
            <p class="size-1">→</p>
        </div>
        
        <!-- Card 3: Locker Surrender -->
        <div class="card" onclick="openPage('lockerSurrender')">
            <h3>Locker Surrender</h3>
            <p class="size-1">→</p>
        </div>
        
        <!-- Card 4: Locker Transaction -->
        <div class="card" onclick="openPage('lockerTransaction')">
            <h3>Locker Transaction</h3>
            <p class="size-1">→</p>
        </div>

    </div>
</div>

<script>
window.onload = function () {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb('Lockers');
    }
    
    // Load card values
    loadCardValues();
};

async function loadCardValues() {
    // Card 1: Locker Issues
    loadSingleCard('locker-issues', 'Locker Issues');
    
    // Card 2: Locker Attendance
    loadSingleCard('locker-attendance', 'Locker Attendance');
    
    // Card 3: Locker Surrender
    loadSingleCard('locker-surrender', 'Locker Surrender');
    
    // Card 4: Locker Transaction
    loadSingleCard('locker-transaction', 'Locker Transaction');
}

async function loadSingleCard(cardId, cardName) {
    try {
        // Replace with your actual endpoint that returns count/value
        const response = await fetch('../getCardValueUnified.jsp?type=locker&id=' + cardId);
        const data = await response.json();
        
        const valueElement = document.getElementById('value-' + cardId);
        if (valueElement) {
            if (data.error) {
                valueElement.textContent = 'Error';
            } else {
                valueElement.textContent = data.value;
            }
            valueElement.classList.remove('loading');
            
            // Remove all size classes first
            valueElement.className = valueElement.className.replace(/size-\d+/g, '').trim();
            
            // Calculate appropriate size class based on text length
            const length = data.value.length;
            let sizeClass = 'size-1';
            
            if (length <= 12) {
                sizeClass = 'size-1';
            } else if (length <= 16) {
                sizeClass = 'size-2';
            } else if (length <= 20) {
                sizeClass = 'size-3';
            } else if (length <= 25) {
                sizeClass = 'size-4';
            } else if (length <= 32) {
                sizeClass = 'size-5';
            } else if (length <= 40) {
                sizeClass = 'size-6';
            } else {
                sizeClass = 'size-7';
            }
            
            valueElement.classList.add(sizeClass);
        }
    } catch (error) {
        console.error('Error loading card:', error);
        const valueElement = document.getElementById('value-' + cardId);
        if (valueElement) {
            valueElement.textContent = 'Error';
            valueElement.classList.remove('loading');
        }
    }
}

function openPage(page) {
    if (window.parent && window.parent.document) {
        const iframe = window.parent.document.getElementById("contentFrame");
        if (iframe) {
            let url = '';
            
            switch(page) {
                case 'lockerIssues':
                    url = '../View/lockerIssues.jsp';
                    break;
                case 'lockerAttendance':
                    url = '../View/lockerAttendance.jsp';
                    break;
                case 'lockerSurrender':
                    url = '../View/lockerSurrender.jsp';
                    break;
                case 'lockerTransaction':
                    url = '../View/lockerTransaction.jsp';
                    break;
            }
            
            if (url) {
                iframe.src = url;
                if (window.parent.updateParentBreadcrumb) {
                    window.parent.updateParentBreadcrumb('Lockers > ' + page);
                }
            }
        }
    }
}
</script>
</body>
</html>