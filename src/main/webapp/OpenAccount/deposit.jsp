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
        String bankCode = "0100";
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
        workingDateStr = new SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
    }
    
    String productCode = request.getParameter("productCode");
    if (productCode == null) {
        productCode = "";
    }
    System.out.println("📌 deposit.jsp - Product Code received: " + productCode);
    
    // ✅ Fetch IS_NOMINEE_REQUIRED and IS_JOINTHOLDER_REQUIRED from database
    boolean isNomineeRequired = false;
    boolean isJointHolderRequired = false;
    
    if (!productCode.isEmpty()) {
        Connection connProduct = null;
        PreparedStatement psProduct = null;
        ResultSet rsProduct = null;
        
        try {
            connProduct = DBConnection.getConnection();
            String sqlProduct = "SELECT IS_NOMINEE_REQUIRED, IS_JOINT_HOLDER_REQUIRED " +
                              "FROM HEADOFFICE.PRODUCT WHERE PRODUCT_CODE = ?";
            psProduct = connProduct.prepareStatement(sqlProduct);
            psProduct.setString(1, productCode);
            rsProduct = psProduct.executeQuery();
            
            if (rsProduct.next()) {
                String nomineeFlag = rsProduct.getString("IS_NOMINEE_REQUIRED");
                String jointHolderFlag = rsProduct.getString("IS_JOINT_HOLDER_REQUIRED");
                
                isNomineeRequired = "Y".equalsIgnoreCase(nomineeFlag);
                isJointHolderRequired = "Y".equalsIgnoreCase(jointHolderFlag);
                
                System.out.println("✅ Product Settings - Nominee Required: " + isNomineeRequired + 
                                 ", Joint Holder Required: " + isJointHolderRequired);
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("❌ Error fetching product settings: " + e.getMessage());
        } finally {
            try { if (rsProduct != null) rsProduct.close(); } catch (Exception ex) {}
            try { if (psProduct != null) psProduct.close(); } catch (Exception ex) {}
            try { if (connProduct != null) connProduct.close(); } catch (Exception ex) {}
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Term Deposit Application</title>
  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
  <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
  <link rel="stylesheet" type="text/css" href="css/savingAcc.css">
  <link rel="stylesheet" href="css/application-tabs.css">
</head>
<body>

<form action="ADNJhServlet" method="post" onsubmit="return validateForm()">
  <input type="hidden" id="hiddenProductCode" name="productCode" value="<%= productCode %>">

  <!-- Application Fieldset -->
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
        <label>Category Code</label>
        <input type="text" id="categoryCode" name="categoryCode" readonly>
      </div>

      <div>
        <label>Introducer A/c Code</label>
        <input type="text" name="introducerAccCode" maxlength="14" pattern="[0-9]{14}" inputmode="numeric"
               title="Introducer Account Code must be exactly 14 digits">
      </div>

      <div>
        <label>Introducer A/c Name</label>
        <input type="text" name="introducerAccName" required oninput="this.value = this.value
        .replace(/[^A-Za-z ]/g, '')
        .replace(/\s{2,}/g, ' ')
        .replace(/^\s+/g, '')
        .toLowerCase()
        .replace(/\b\w/g, c => c.toUpperCase());">
      </div>
      <script>
      document.querySelector('input[name="introducerAccName"]').addEventListener('input', function () {
          this.value = this.value.replace(/[^A-Za-z\s]/g, '').slice(0, 100);
      });
      </script>
      
      <div>
        <label>Date Of Application</label>
        <input type="date" name="dateOfApplication" value="<%= workingDateStr %>" readonly 
               style="background-color: #f0f0f0; cursor: not-allowed;" required>
      </div>

      <div>
        <label>Account Operation Capacity</label>
        <select name="accountOperationCapacity" id="dd-accountOperationCapacity" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
      </div>

      <div>
        <label>Min Balance</label>
        <select name="minBalanceID" id="dd-minBalance" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
      </div>
      
      <div>
        <label>Risk Category</label>
        <input type="text" id="riskCategory" name="riskCategory" readonly>
      </div>
      
    </div>
  </fieldset>

  <!-- Deposit Fieldset -->
  <fieldset>
    <legend>Deposit</legend>
    <div class="form-grid">
      
      <div>
        <label>Account Type</label>
        <input type="text" name="accountType" readonly value="TD">
      </div>
      
      <div>
        <label>Open Date</label>
        <input type="date" name="openDate">
      </div>

      <div>
        <label>Unit Of Period</label>
        <div style="flex-direction: row;" class="radio-group">
          <label><input type="radio" name="unitOfPeriod" value="Day"> Day</label>
          <label><input type="radio" name="unitOfPeriod" value="Month" checked> Month</label>
        </div>
      </div>

      <div>
        <label>Period Of Deposit</label>
        <input type="number" name="periodOfDeposit" min="0">
      </div>

      <div>
        <label>Maturity Date</label>
        <input type="date" name="maturityDate" readonly style="background-color: #f0f0f0;">
      </div>

      <div>
        <label>Interest Rate</label>
        <input type="number" step="0.01" name="interestRate" required>
      </div>

      <div>
        <label>Interest Paid In Cash</label>
        <div style="flex-direction: row;" class="radio-group">
          <label><input type="radio" name="interestPaidInCash" value="Yes"> Yes</label>
          <label><input type="radio" name="interestPaidInCash" value="No" checked> No</label>
        </div>
      </div>

      <div>
        <label>Rate Discounted</label>
        <div style="flex-direction: row;" class="radio-group">
          <label><input type="radio" name="rateDiscounted" value="Yes"> Yes</label>
          <label><input type="radio" name="rateDiscounted" value="No" checked> No</label>
        </div>
      </div>

      <div>
        <label>Is AR Day Begin</label>
        <div style="flex-direction: row;" class="radio-group">
          <label><input type="radio" name="isARDayBegin" value="Yes"> Yes</label>
          <label><input type="radio" name="isARDayBegin" value="No" checked> No</label>
        </div>
      </div>

      <div>
        <label>Interest Payment Frequency</label>
        <select name="interestPaymentFrequency">
          <option value="">-- Select Frequency --</option>
          <option value="On Maturity">On Maturity</option>
          <option value="Monthly">Monthly</option>
          <option value="Quarterly">Quarterly</option>
          <option value="Half-Yearly">Half-Yearly</option>
          <option value="Yearly">Yearly</option>
        </select>
      </div>
      
      <div>
        <label>Credit A/c Code</label>
        <input type="text" name="creditAccCode">
      </div>

      <div>
        <label>Credit A/c Name</label>
        <input type="text" name="creditAccName" required oninput="this.value = this.value
        .replace(/[^A-Za-z ]/g, '')
        .replace(/\s{2,}/g, ' ')
        .replace(/^\s+/g, '')
        .toLowerCase()
        .replace(/\b\w/g, c => c.toUpperCase());">
      </div>

      <div>
        <label>Deposit Amount</label>
        <input type="number" step="0.01" name="depositAmount" id="depositAmount" value="0" oninput="validateDeposit()">
      </div>

      <div>
        <label>Maturity Amount</label>
        <input type="number" step="0.01" name="maturityAmount">
      </div>

      <div></div>
      
      <div>
        <label>Cash</label>
        <input type="number" step="0.01" name="cash" id="cash" value="0" oninput="validateDeposit()">
      </div>

      <div>
        <label>Clearing</label>
        <input type="number" step="0.01" name="clearing" id="clearing" value="0" oninput="validateDeposit()">
      </div>

      <div>
        <label>Transfer</label>
        <input type="number" step="0.01" name="transfer" id="transfer" value="0" oninput="validateDeposit()">
      </div>

    </div>
  </fieldset>

  <!-- ✅ Nominee Section - Display only if IS_NOMINEE_REQUIRED = 'Y' -->
  <% if (isNomineeRequired) { %>
  <fieldset id="nomineeFieldset">
    <legend>
      Nominee
      <button type="button" onclick="addNominee()" 
        style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
        ➕
      </button>
    </legend>

    <div class="nominee-card nominee-block">
      <button type="button" class="nominee-remove" onclick="removeNominee(this)">✖</button>

      <div class="nominee-title" 
           style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
        Nominee <span class="nominee-serial">1</span>
      </div>
      
      <div class="inline-fields">
        <div>
          <label>Has Customer ID ?</label>
          <div style="flex-direction: row;" class="radio-group">
            <label><input type="radio" name="nomineeHasCustomerID_1" class="nomineeHasCustomerRadio" value="yes" onchange="toggleNomineeCustomerID(this)"> Yes</label>
            <label><input type="radio" name="nomineeHasCustomerID_1" class="nomineeHasCustomerRadio" value="no" onchange="toggleNomineeCustomerID(this)" checked> No</label>
          </div>
        </div>

        <div class="nomineeCustomerIDContainer" style="display:none; margin-top:10px;">
          <label>Customer ID</label>
          <div class="input-icon-box">
            <input type="text" class="nomineeCustomerIDInput" name="nomineeCustomerID[]" onclick="openNomineeCustomerLookup(this)" readonly>
            <button type="button" class="inside-icon-btn" onclick="openNomineeCustomerLookup(this)" title="Search Customer">🔍</button>
          </div>
        </div>
      </div>

      <br>

      <div class="personal-grid">
        <div>
          <label>Salutation Code</label>
          <select name="nomineeSalutation[]" id="dd-nomineeSalutation" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
        </div>

        <div>
          <label>Nominee Name</label>
          <input type="text" name="nomineeName[]" required oninput="this.value = this.value
        .replace(/[^A-Za-z ]/g, '')
        .replace(/\s{2,}/g, ' ')
        .replace(/^\s+/g, '')
        .toLowerCase()
        .replace(/\b\w/g, c => c.toUpperCase());">
        </div>

        <div>
          <label>Address 1</label>
          <input type="text" name="nomineeAddress1[]">
        </div>

        <div>
          <label>Address 2</label>
          <input type="text" name="nomineeAddress2[]">
        </div>

        <div>
          <label>Address 3</label>
          <input type="text" name="nomineeAddress3[]">
        </div>

        <div>
          <label>Country</label>
          <select name="nomineeCountry[]" id="dd-nomineeCountry" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
        </div>

        <div>
          <label>State</label>
          <select name="nomineeState[]" id="dd-nomineeState" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
        </div>

        <div>
          <label>City</label>
          <select name="nomineeCity[]" id="dd-nomineeCity" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
        </div>

        <div>
          <label>Zip</label>
          <input type="text" name="nomineeZip[]" class="zip-input" maxlength="6">
          <small class="zipError"></small>
        </div>

        <div>
          <label>Relation with Guardian</label>
          <select name="nomineeRelation[]" id="dd-nomineeRelation" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
        </div>
      </div>
    </div>
  </fieldset>
  <% } %>

  <!-- ✅ Joint Holder Section - Display only if IS_JOINTHOLDER_REQUIRED = 'Y' -->
  <% if (isJointHolderRequired) { %>
  <fieldset id="jointFieldset">
    <legend>
      Joint Holder
      <button type="button" onclick="addJointHolder()"
        style="border:none;background:#373279;color:white;padding:2px 10px;
        border-radius:5px;cursor:pointer;font-size:12px;margin-left:10px;">
        ➕
      </button>
    </legend>

    <div class="nominee-card joint-block">
      <button type="button" class="nominee-remove" onclick="removeJointHolder(this)">✖</button>

      <div class="nominee-title"
           style="font-weight:bold; font-size:15px; margin-bottom:10px; color:#373279;">
        Joint Holder <span class="joint-serial">1</span>
      </div>
      
      <div class="inline-fields">
        <div>
          <label>Has Customer ID ?</label>
          <div style="flex-direction: row;" class="radio-group">
            <label><input type="radio" name="jointHasCustomerID_1" class="jointHasCustomerRadio" value="yes" onchange="toggleJointCustomerID(this)"> Yes</label>
            <label><input type="radio" name="jointHasCustomerID_1" class="jointHasCustomerRadio" value="no" onchange="toggleJointCustomerID(this)" checked> No</label>
          </div>
        </div>

        <div class="jointCustomerIDContainer" style="display:none; margin-top:10px;">
          <label>Customer ID</label>
          <div class="input-icon-box">
            <input type="text" class="jointCustomerIDInput" name="jointCustomerID[]" onclick="openJointCustomerLookup(this)" readonly>
            <button type="button" class="inside-icon-btn" onclick="openJointCustomerLookup(this)" title="Search Customer">🔍</button>
          </div>
        </div>
      </div>

      <br>

      <div class="address-grid">
        <div>
          <label>Salutation Code</label>
          <select name="jointSalutation[]" id="dd-jointSalutation" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
        </div>

        <div>
          <label>Joint Holder Name</label>
          <input type="text" name="jointName[]" required oninput="this.value = this.value
        .replace(/[^A-Za-z ]/g, '')
        .replace(/\s{2,}/g, ' ')
        .replace(/^\s+/g, '')
        .toLowerCase()
        .replace(/\b\w/g, c => c.toUpperCase());">
        </div>

        <div>
          <label>Address 1</label>
          <input type="text" name="jointAddress1[]">
        </div>

        <div>
          <label>Address 2</label>
          <input type="text" name="jointAddress2[]">
        </div>

        <div>
          <label>Address 3</label>
          <input type="text" name="jointAddress3[]">
        </div>

        <div>
          <label>Country</label>
          <select name="jointCountry[]" id="dd-jointCountry" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
        </div>

        <div>
          <label>State</label>
          <select name="jointState[]" id="dd-jointState" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
        </div>

        <div>
          <label>City</label>
          <select name="jointCity[]" id="dd-jointCity" required class="dd-loading">
  		<option value="">Loading...</option>
		</select>
        </div>

        <div>
          <label>Zip</label>
          <input type="text" name="jointZip[]" class="zip-input" maxlength="6">
          <small class="zipError"></small>
        </div>
      </div>
    </div>
  </fieldset>
  <% } %>

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

<script src="js/savingAcc.js"></script>
<script src="js/application-tabs.js"></script>
<script src="js/formDropdownLoader.js"></script>
<script>
// Validation function
function validateForm() {
    const customerId = document.getElementById('customerId').value.trim();
    
    if (!customerId) {
        showToast('❌ Please select a customer before submitting');
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
            text: "✅ Term Deposit Application saved successfully!\nApplication Number: " + applicationNumber,
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
            text: "❌ Error: " + (message || "Failed to save term deposit application"),
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

//==================== TERM DEPOSIT MATURITY DATE CALCULATION ====================

function calculateTermDepositMaturityDate() {
    const openDateInput = document.querySelector('input[name="openDate"]');
    const periodInput = document.querySelector('input[name="periodOfDeposit"]');
    const maturityDateInput = document.querySelector('input[name="maturityDate"]');
    const unitRadios = document.querySelectorAll('input[name="unitOfPeriod"]');
    
    if (!openDateInput || !periodInput || !maturityDateInput) {
        return;
    }
    
    let selectedUnit = 'Month';
    for (let radio of unitRadios) {
        if (radio.checked) {
            selectedUnit = radio.value;
            break;
        }
    }
    
    const openDate = openDateInput.value;
    const period = parseInt(periodInput.value) || 0;
    
    if (!openDate || period <= 0) {
        maturityDateInput.value = '';
        return;
    }
    
    const dateObj = new Date(openDate + 'T00:00:00');
    
    if (isNaN(dateObj.getTime())) {
        maturityDateInput.value = '';
        return;
    }
    
    if (selectedUnit === 'Day') {
        dateObj.setDate(dateObj.getDate() + period);
    } else if (selectedUnit === 'Month') {
        dateObj.setMonth(dateObj.getMonth() + period);
    }
    
    const year = dateObj.getFullYear();
    const month = String(dateObj.getMonth() + 1).padStart(2, '0');
    const day = String(dateObj.getDate()).padStart(2, '0');
    
    const formattedDate = year + '-' + month + '-' + day;
    
    if (/^\d{4}-\d{2}-\d{2}$/.test(formattedDate)) {
        maturityDateInput.value = formattedDate;
    } else {
        maturityDateInput.value = '';
    }
}

document.addEventListener('DOMContentLoaded', function() {
    const openDateInput = document.querySelector('input[name="openDate"]');
    const periodInput = document.querySelector('input[name="periodOfDeposit"]');
    const maturityDateInput = document.querySelector('input[name="maturityDate"]');
    const unitRadios = document.querySelectorAll('input[name="unitOfPeriod"]');
    
    if (maturityDateInput) {
        maturityDateInput.value = '';
        maturityDateInput.readOnly = true;
        maturityDateInput.style.backgroundColor = '#f0f0f0';
    }
    
    if (openDateInput) {
        openDateInput.addEventListener('change', calculateTermDepositMaturityDate);
    }
    
    if (periodInput) {
        periodInput.addEventListener('input', calculateTermDepositMaturityDate);
        periodInput.addEventListener('change', calculateTermDepositMaturityDate);
    }
    
    if (unitRadios) {
        unitRadios.forEach(function(radio) {
            radio.addEventListener('change', calculateTermDepositMaturityDate);
        });
    }
    
    if (openDateInput && openDateInput.value && periodInput && periodInput.value) {
        calculateTermDepositMaturityDate();
    }
});

// Monitor Application Customer ID changes
document.addEventListener('DOMContentLoaded', function() {
    const customerIdField = document.getElementById('customerId');
    if (customerIdField) {
        let previousValue = customerIdField.value;
        
        customerIdField.addEventListener('change', function() {
            const newValue = this.value.trim();
            if (previousValue && !newValue) {
                console.log('Application customer cleared');
            }
            previousValue = newValue;
        });
    }
});

// Check DEPOSIT amount using CASH, CLEARING, TRANSFER
function validateDeposit() {
  let deposit = parseFloat(document.getElementById("depositAmount").value) || 0;
  let cash = parseFloat(document.getElementById("cash").value) || 0;
  let clearing = parseFloat(document.getElementById("clearing").value) || 0;
  let transfer = parseFloat(document.getElementById("transfer").value) || 0;

  let total = cash + clearing + transfer;

  if (deposit !== total) {
    document.getElementById("depositAmount").style.border = "2px solid red";
  } else {
    document.getElementById("depositAmount").style.border = "";
  }
}

// Utility function
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
</script>
<script>
  document.addEventListener('DOMContentLoaded', function () {
      var ctx = '<%= request.getContextPath() %>';
      loadAccountFormDropdowns(ctx);
  });
</script>
</body>
</html>