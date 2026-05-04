<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    String branchCode = (String) session.getAttribute("branchCode");
    if (branchCode == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    
 // Fetch working date for this branch
    String workingDateStr = "";
    try (Connection connWorkDate = DBConnection.getConnection()) {
        String bankCode = "0100"; // Default bank code
        CallableStatement cstmtWorkDate = connWorkDate.prepareCall("{? = call SYSTEM.FN_GET_WORKINGDATE(?, ?)}");
        cstmtWorkDate.registerOutParameter(1, Types.DATE);
        cstmtWorkDate.setString(2, bankCode);
        cstmtWorkDate.setString(3, branchCode);
        cstmtWorkDate.execute();
        
        Date workingDate = cstmtWorkDate.getDate(1);
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
        workingDateStr = sdf.format(workingDate);
        
        cstmtWorkDate.close();
    } catch (Exception e) {
        e.printStackTrace();
        // Fallback to current date if error
        workingDateStr = new SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
    }
    
    String productCode = request.getParameter("productCode");
    if (productCode == null) {
        productCode = "";
    }
    System.out.println("📌 fAApplication.jsp - Product Code received: " + productCode);
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Fixed Asset Depreciation Application</title>
  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
  <link rel="stylesheet" type="text/css" href="css/savingAcc.css">
  <link rel="stylesheet" href="css/application-tabs.css">
  <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
</head>
<body>

<form action="SaveFAApplicationServlet" method="post" onsubmit="return validateForm()">
  <input type="hidden" id="hiddenProductCode" name="productCode" value="<%= productCode %>">

  <fieldset>
    <legend>Application</legend>
    <div class="form-grid">
      
      <div>
        <label>Product Code</label>
        <input type="text" value="<%= productCode %>" readonly style="background-color: #f0f0f0;">
      </div>
      
      <div>
        <label>Customer ID</label>
        <div class="input-icon-box">
          <input type="text" id="customerId" name="customerId" onclick="openCustomerLookup()" readonly required>
          <button type="button" class="inside-icon-btn" onclick="openCustomerLookup()" title="Search Customer">🔍</button>
        </div>
      </div>

      <div>
        <label>Customer Name</label>
        <input type="text" id="customerName" name="customerName" readonly>
      </div>
     
      <div>
    	<label>Date Of Application</label>
    	<input type="date" name="dateOfApplication" value="<%= workingDateStr %>" readonly 
           style="background-color: #f0f0f0; cursor: not-allowed;" required>
	</div>

      <div>
        <label>Item Name</label>
        <input type="text" name="itemName" required oninput="this.value = this.value.replace(/[^A-Za-z0-9 ]/g, '')">
      </div>

      <div>
        <label>Purchase Date</label>
        <input type="date" name="purchaseDate" required>
      </div>

      <div>
        <label>Purchase Amount</label>
        <input type="number" step="0.01" name="purchaseAmount" value="0" required>
      </div>

      <div>
        <label>No. Of Item</label>
        <input type="number" name="noOfItem" value="0" required>
      </div>

      <div>
        <label>Depreciation Rate</label>
        <input type="number" step="0.01" name="depreciationRate" value="0" required>
      </div>

      <div>
        <label>Description</label>
        <input type="text" name="description" required oninput="this.value = this.value.replace(/[^A-Za-z0-9 ]/g, '')" required>
      </div>

      <div>
        <label>Bill Number</label>
        <input type="text" name="billNumber" required oninput="this.value = this.value.replace(/[^A-Za-z0-9 ]/g, '')" required>
      </div>

      <div>
        <label>Method Of Depreciation Calculation</label>
        <div class="radio-group" style="flex-direction: row;">
          <label><input type="radio" name="methodOfDepreciation" value="Day"> Day</label>
          <label><input type="radio" name="methodOfDepreciation" value="Month" checked> Month</label>
        </div>
      </div>

      <div>
        <label>Depreciation Calculate On</label>
        <div class="radio-group" style="flex-direction: row;">
          <label><input type="radio" name="depreciationCalculateOn" value="Opening Balance"> Opening Balance</label>
          <label><input type="radio" name="depreciationCalculateOn" value="Current Balance" checked> Current Balance</label>
        </div>
      </div>

    </div>
  </fieldset>

  <div class="form-buttons">
    <button type="submit">Save</button>
    <button type="reset">Reset</button>
  </div>
</form>

<!-- Customer Lookup Modal -->
<div id="customerLookupModal" class="customer-modal">
  <div class="customer-modal-content">
    <span class="customer-close" onclick="closeCustomerLookup()">&times;</span>
    <div id="customerLookupContent">
      <!-- Content will be loaded here -->
    </div>
  </div>
</div>
<script src="js/application-tabs.js"></script>
<script>
// Validation function
function validateForm() {
    const customerId = document.getElementById('customerId').value.trim();
    
    if (!customerId) {
        showToast('❌ Please select a customer before submitting');
        return false;
    }
    
    const purchaseAmount = parseFloat(document.querySelector('input[name="purchaseAmount"]').value);
    if (purchaseAmount <= 0) {
        showToast('❌ Purchase Amount must be greater than 0');
        return false;
    }
    
    const noOfItem = parseInt(document.querySelector('input[name="noOfItem"]').value);
    if (noOfItem <= 0) {
        showToast('❌ Number of Items must be greater than 0');
        return false;
    }
    
    const depreciationRate = parseFloat(document.querySelector('input[name="depreciationRate"]').value);
    if (depreciationRate < 0 || depreciationRate > 100) {
        showToast('❌ Depreciation Rate must be between 0 and 100');
        return false;
    }
    
    return true;
}

// Check URL parameters for success/error messages
window.addEventListener('DOMContentLoaded', function() {
    const urlParams = new URLSearchParams(window.location.search);
    const status = urlParams.get('status');
    const applicationNumber = urlParams.get('applicationNumber');
    const message = urlParams.get('message');
    
    if (status === 'success' && applicationNumber) {
        Toastify({
            text: "✅ Fixed Asset Application saved successfully!\nApplication Number: " + applicationNumber,
            duration: 6000,
            close: true,
            gravity: "top",
            position: "center",
            style: {
                background: "#fff",
                color: "#333",
                borderRadius: "8px",
                fontSize: "14px",
                padding: "16px 24px",
                boxShadow: "0 3px 10px rgba(0,0,0,0.2)",
                borderLeft: "5px solid #4caf50",
                marginTop: "20px",
                whiteSpace: "pre-line"
            },
            stopOnFocus: true
        }).showToast();
        
        setTimeout(function() {
            const cleanUrl = window.location.pathname + window.location.search.replace(/[?&](status|applicationNumber|message)=[^&]*/g, '').replace(/^&/, '?').replace(/\?$/, '');
            window.history.replaceState({}, document.title, cleanUrl || window.location.pathname);
        }, 100);
        
    } else if (status === 'error') {
        Toastify({
            text: "❌ Error: " + (message || "Failed to save application"),
            duration: 6000,
            close: true,
            gravity: "top",
            position: "center",
            style: {
                background: "#fff",
                color: "#333",
                borderRadius: "8px",
                fontSize: "14px",
                padding: "16px 24px",
                boxShadow: "0 3px 10px rgba(0,0,0,0.2)",
                borderLeft: "5px solid #f44336",
                marginTop: "20px"
            },
            stopOnFocus: true
        }).showToast();
        
        setTimeout(function() {
            const cleanUrl = window.location.pathname + window.location.search.replace(/[?&](status|applicationNumber|message)=[^&]*/g, '').replace(/^&/, '?').replace(/\?$/, '');
            window.history.replaceState({}, document.title, cleanUrl || window.location.pathname);
        }, 100);
    }
});

//==================== CUSTOMER LOOKUP FUNCTIONS ====================

window.setCustomerData = function(customerId, customerName, categoryCode, riskCategory) {
    document.getElementById('customerId').value = customerId;
    document.getElementById('customerName').value = customerName;

    closeCustomerLookup();

    if (typeof Toastify !== 'undefined') {
        Toastify({
            text: "✅ Customer data loaded successfully!",
            duration: 5000,
            close: true,
            gravity: "top",
            position: "center",
            style: {
                background: "#fff",
                color: "#333",
                borderRadius: "8px",
                fontSize: "14px",
                padding: "16px 24px",
                boxShadow: "0 3px 10px rgba(0,0,0,0.2)",
                borderLeft: "5px solid #4caf50",
                marginTop: "20px"
            }
        }).showToast();
    }
};

function openCustomerLookup() {
    const modal = document.getElementById('customerLookupModal');
    const content = document.getElementById('customerLookupContent');

    modal.style.display = 'flex';
    content.innerHTML = '<div style="text-align:center;padding:40px;">Loading customers...</div>';

    fetch('lookupForCustomerId.jsp')
        .then(response => response.text())
        .then(html => {
            content.innerHTML = html;
            const scripts = content.querySelectorAll('script');
            scripts.forEach(script => {
                const newScript = document.createElement('script');
                newScript.textContent = script.textContent;
                document.body.appendChild(newScript);
                document.body.removeChild(newScript);
            });
        })
        .catch(error => {
            console.error('Error loading customer lookup:', error);
            content.innerHTML = '<div style="text-align:center;padding:40px;color:red;">Failed to load customer list. Please try again.</div>';
        });
}

function closeCustomerLookup() {
    document.getElementById('customerLookupModal').style.display = 'none';
}

window.onclick = function(event) {
    const modal = document.getElementById('customerLookupModal');
    if (event.target === modal) {
        closeCustomerLookup();
    }
}

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeCustomerLookup();
    }
});

function showToast(message) {
    if (typeof Toastify !== 'undefined') {
        Toastify({
            text: message,
            duration: 5000,
            close: true,
            gravity: "top",
            position: "center",
            style: {
                background: "#fff",
                color: "#333",
                borderRadius: "8px",
                fontSize: "14px",
                padding: "16px 24px",
                boxShadow: "0 3px 10px rgba(0,0,0,0.2)",
                borderLeft: "5px solid #4caf50",
                marginTop: "20px"
            }
        }).showToast();
    }
}

// Update breadcrumb on page load
window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb('Fixed Asset Application');
    }
};

</script>
</body>
</html>