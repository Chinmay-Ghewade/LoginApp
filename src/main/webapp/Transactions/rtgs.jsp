<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    String branchCode = (String) session.getAttribute("branchCode");
    if (branchCode == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    String contextPath = request.getContextPath();
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>RTGS Outward Entry</title>
  <link rel="stylesheet" href="../css/rtgs.css">
  <link rel="stylesheet" href="../css/tabs-navigation.css">
  <link rel="stylesheet" href="../css/lookup-modal.css">
  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
  <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>

  <style>
    .page-header {
      text-align: center;
      font-size: 24px;
      font-weight: bold;
      color: #373279;
      margin: 20px 0 30px 0;
      letter-spacing: 1px;
    }

    select.dd-loading {
      color: #999;
      background-color: #f9f9f9;
      font-style: italic;
    }
    .dd-spinner {
      display: inline-block;
      width: 8px; height: 8px;
      border-radius: 50%;
      background: #373279;
      margin-left: 4px;
      animation: ddPulse 0.8s ease-in-out infinite alternate;
      vertical-align: middle;
    }
    @keyframes ddPulse {
      from { opacity: 0.2; transform: scale(0.8); }
      to   { opacity: 1;   transform: scale(1.1); }
    }
    .dd-spinner.done { display: none; }

    .form-buttons { display: flex !important; }
    
    form { padding: 0 20px; }

    .input-icon-box {
      position: relative;
      width: 90%;
    }
    .input-icon-box input {
      width: 100%;
      padding-right: 40px;
      height: 30px;
      cursor: pointer;
      box-sizing: border-box;
    }
    .input-icon-box .inside-icon-btn {
      position: absolute;
      right: 5px;
      top: 50%;
      transform: translateY(-50%);
      background: none;
      border: none;
      font-size: 16px;
      cursor: pointer;
      color: #373279;
    }

    .inline-radio-row {
      display: flex;
      align-items: center;
      gap: 20px;
      flex-wrap: wrap;
    }
    .inline-radio-row .radio-group { flex-direction: row; }

    .rtgs-success-modal {
      display: none;
      position: fixed;
      inset: 0;
      z-index: 9999;
      background: rgba(0,0,0,0.45);
      align-items: center;
      justify-content: center;
    }
    .rtgs-success-modal.open { display: flex; }
    .rtgs-success-card {
      background: #fff;
      border-radius: 18px;
      padding: 36px 40px 30px 40px;
      text-align: center;
      box-shadow: 0 12px 48px rgba(55,50,121,0.22);
      max-width: 420px;
      width: 90%;
      animation: popIn 0.28s cubic-bezier(.34,1.56,.64,1);
    }
    @keyframes popIn {
      from { transform: scale(0.7); opacity: 0; }
      to   { transform: scale(1);   opacity: 1; }
    }
    .rtgs-success-icon {
      width: 68px;
      height: 68px;
      border-radius: 50%;
      background: linear-gradient(135deg,#373279,#5a3ec8);
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 18px auto;
      font-size: 32px;
    }
    .rtgs-success-card h2 {
      color: #373279;
      font-size: 1.25rem;
      margin: 0 0 8px 0;
      font-family: Arial,sans-serif;
    }
    .rtgs-success-card p {
      color: #666;
      font-size: 0.9rem;
      margin: 5px 0;
      font-family: Arial,sans-serif;
    }
    .rtgs-success-detail-box {
      background: #f4f2fc;
      border-radius: 10px;
      padding: 14px 20px;
      margin: 16px 0;
      text-align: left;
    }
    .rtgs-success-detail-row {
      display: flex;
      justify-content: space-between;
      font-family: Arial,sans-serif;
      font-size: 0.88rem;
      padding: 4px 0;
      border-bottom: 1px solid #e0daf5;
    }
    .rtgs-success-detail-row:last-child { border-bottom: none; }
    .rtgs-success-detail-row span:first-child { color: #888; }
    .rtgs-success-detail-row span:last-child  { color: #373279; font-weight: 700; }
    .rtgs-success-ok-btn {
      background: linear-gradient(135deg,#373279,#5a3ec8);
      color: #fff;
      border: none;
      border-radius: 8px;
      padding: 11px 48px;
      font-size: 1rem;
      font-weight: 700;
      cursor: pointer;
      font-family: Arial,sans-serif;
      margin-top: 6px;
      transition: opacity 0.2s;
    }
    .rtgs-success-ok-btn:hover { opacity: 0.88; }
  </style>
</head>
<body>

<!-- PAGE HEADER -->
<div class="page-header">RTGS OUTWARD ENTRY</div>

<!-- ════════════════════════════════════════════════════════════════ -->
<!-- RTGS SUCCESS MODAL                                             -->
<!-- ════════════════════════════════════════════════════════════════ -->
<div id="rtgsSuccessModal" class="rtgs-success-modal">
  <div class="rtgs-success-card">
    <div class="rtgs-success-icon">✅</div>
    <h2>RTGS Request Submitted Successfully!</h2>
    <p>Your RTGS transaction has been registered.</p>
    <div class="rtgs-success-detail-box">
      <div class="rtgs-success-detail-row">
        <span>Transaction ID</span>
        <span id="successTransactionId">—</span>
      </div>
      <div class="rtgs-success-detail-row">
        <span>Beneficiary Name</span>
        <span id="successBeneficiaryName">—</span>
      </div>
      <div class="rtgs-success-detail-row">
        <span>Amount</span>
        <span id="successAmount">—</span>
      </div>
      <div class="rtgs-success-detail-row">
        <span>Status</span>
        <span id="successStatus">Submitted</span>
      </div>
    </div>
    <button class="rtgs-success-ok-btn" onclick="closeRtgsSuccessModal()">OK</button>
  </div>
</div>

<!-- ════════════════════════════════════════════════════════════════ -->
<!-- LOOKUP MODAL                                                   -->
<!-- ════════════════════════════════════════════════════════════════ -->
<div id="lookupModal" class="lookup-modal-wrap" style="display:none;">
    <div class="lookup-modal-box">
        <button class="lookup-modal-box-close" onclick="closeLookup()">&#10006;</button>
        <div id="lookupContent"></div>
    </div>
</div>

<form id="rtgsForm" onsubmit="submitRtgsForm(event)">

	<!-- ══════════════════════════════════════════════════════════════ -->
  <!-- RTGS Details   -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>RTGS Details</legend>
    <div class="form-grid">

      <div>
        <label>Transaction Mode</label>
        <div class="inline-radio-row radio-group">
          <label><input type="radio" name="transactionMode" value="Transfer" checked onchange="toggleModeSections(this.value)"> Transfer</label>
		  <label><input type="radio" name="transactionMode" value="Cash" onchange="toggleModeSections(this.value)"> Cash</label>
        </div>
      </div>

      <div>
        <label>Transaction Type</label>
        <div class="inline-radio-row radio-group">
          <label><input type="radio" name="transactionType" value="RTGS" checked> RTGS</label>
          <label><input type="radio" name="transactionType" value="NEFT"> NEFT</label>
          <label><input type="radio" name="transactionType" value="ThirdParty"> Third Party</label>
        </div>
      </div>

      <div>
        <label>Scroll Number</label>
        <input type="text" name="scrollNumber" id="scrollNumber" readonly>
      </div>

    </div>
  </fieldset>

  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 2: TRANSFER DETAILS                                  -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Transfer Details</legend>
    <div class="form-grid">

      <div>
        <label>Account Code</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <input type="text" name="accountCode" id="accountCode" class="form-input" autocomplete="off">
          <button type="button" class="icon-btn" onclick="openAccountLookup()"
                  style="background-color:#2D2B80; color:white; border:none; width:35px; height:35px;
                         border-radius:8px; font-size:18px; cursor:pointer;">…</button>
        </div>
      </div>

      <div>
        <label>Account Name</label>
        <input type="text" name="accountName" id="accountName" readonly>
      </div>

      <div>
        <label>Address 1</label>
        <input type="text" name="address1" id="address1">
      </div>

      <div>
        <label>Address 2</label>
        <input type="text" name="address2" id="address2">
      </div>

      <div>
        <label>Address 3</label>
        <input type="text" name="address3" id="address3">
      </div>

      <div>
        <label>Ledger Balance</label>
        <input type="text" name="ledgerBalance" id="ledgerBalance" readonly>
      </div>

      <div>
        <label>Available Balance</label>
        <input type="text" name="availableBalance" id="availableBalance" readonly>
      </div>

      <div>
        <label>New Ledger Balance</label>
        <input type="text" name="newLedgerBalance" id="newLedgerBalance" readonly>
      </div>

      <div>
        <label>Cheque Type</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <select name="chequeType" id="chequeType" class="form-input">
            <option value="">Select Cheque Type</option>
          </select>
          <button type="button" class="icon-btn" onclick="loadChequeData()"
                  style="background-color:#2D2B80; color:white; border:none; width:35px; height:35px;
                         border-radius:8px; font-size:18px; cursor:pointer;">↻</button>
        </div>
      </div>
      
      <div>
        <label>Cheque Series</label>
        <select name="chequeSeries" id="chequeSeries" class="form-input">
          <option value="">Select Cheque Series</option>
        </select>
      </div>

      <div>
        <label>Cheque Number</label>
        <select name="chequeNumber" id="chequeNumber" class="form-input">
          <option value="">Select Cheque No</option>
        </select>
      </div>

      <div>
        <label>Cheque Date</label>
        <input type="date" name="chequeDate" id="chequeDate">
      </div>

    </div>
  </fieldset>

  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 3: CASH DETAILS                                      -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Cash Details</legend>
    <div class="form-grid">

      <div>
        <label>Name Of Applicant</label>
        <input type="text" name="nameOfApplicant" id="nameOfApplicant">
      </div>

      <div>
        <label>Address1</label>
        <input type="text" name="cashAddress1" id="cashAddress1">
      </div>

      <div>
        <label>Address2</label>
        <input type="text" name="cashAddress2" id="cashAddress2">
      </div>

      <div>
        <label>Address3</label>
        <input type="text" name="cashAddress3" id="cashAddress3">
      </div>

    </div>
  </fieldset>

  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 4: REMITTER DETAILS                                  -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Remitter Details</legend>
    <div class="form-grid">

      <div>
        <label>Remitting Banks IFSC CODE</label>
        <input type="text" name="remittingIfscCode" id="remittingIfscCode">
      </div>

      <div>
        <label>Application contact no(M)</label>
        <input type="text" name="appContactNo" id="appContactNo">
      </div>

      <div>
        <label>Residence</label>
        <input type="text" name="residenceNo" id="residenceNo">
      </div>

      <div>
        <label>Office</label>
        <input type="text" name="officeNo" id="officeNo">
      </div>

      <div>
        <label>Application Email ID</label>
        <input type="email" name="appEmailId" id="appEmailId">
      </div>

    </div>
  </fieldset>

  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 5: BENEFICIARY DETAILS                               -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Beneficiary Details</legend>
    <div class="form-grid">

      <div>
        <label>Beneficiary Name</label>
        <input type="text" name="beneficiaryName" id="beneficiaryName" required>
      </div>

      <div>
        <label>Beneficiary Account Code</label>
        <input type="text" name="beneficiaryAccountCode" id="beneficiaryAccountCode" required>
      </div>

      <div>
        <label>IFSC Code</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <input type="text" name="ifscCode" id="ifscCode" class="form-input" required>
          <button type="button" class="icon-btn" onclick="openIfscLookup()"
                  style="background-color:#2D2B80; color:white; border:none; width:35px; height:35px;
                         border-radius:8px; font-size:18px; cursor:pointer;">…</button>
        </div>
      </div>

      <div>
        <label>IFSC Bank Name</label>
        <input type="text" name="ifscBankName" id="ifscBankName" readonly>
      </div>

      <div>
        <label>IFSC Branch Name</label>
        <input type="text" name="ifscBranchName" id="ifscBranchName" readonly>
      </div>

      <div>
        <label>Beneficiary Contact No (M)</label>
        <input type="text" name="beneficiaryMobile" id="beneficiaryMobile">
      </div>

      <div>
        <label>Residence</label>
        <input type="text" name="beneficiaryResidence" id="beneficiaryResidence">
      </div>

      <div>
        <label>Office</label>
        <input type="text" name="beneficiaryOffice" id="beneficiaryOffice">
      </div>

      <div>
        <label>Beneficiary Address 1</label>
        <input type="text" name="beneficiaryAddress1" id="beneficiaryAddress1">
      </div>

      <div>
        <label>Beneficiary Address 2</label>
        <input type="text" name="beneficiaryAddress2" id="beneficiaryAddress2">
      </div>

      <div>
        <label>City</label>
        <input type="text" name="beneficiaryCity" id="beneficiaryCity">
      </div>

      <div>
        <label>State</label>
        <input type="text" name="beneficiaryState" id="beneficiaryState">
      </div>
      
     <div>
        <label>Sender To Receiver Info</label>
        <input type="text" name="SenderToReceiver" id="SenderToReceiver">
      </div>

    </div>
  </fieldset>

  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- FIELDSET 6: PAYMENT DETAILS                                   -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Payment Details</legend>
    <div class="form-grid">

      <div>
        <label>Remitting Amount</label>
        <input type="text" name="remittingAmount" id="remittingAmount" value="0"
               oninput="this.value = this.value.replace(/[^0-9.]/g, ''); calculateTotal();" required>
      </div>

      <div>
        <label>Applicable Charges</label>
        <input type="text" name="applicableCharges" id="applicableCharges" value="0"
               oninput="this.value = this.value.replace(/[^0-9.]/g, ''); calculateTotal();">
      </div>

      <div>
        <label>Service Tax</label>
        <input type="text" name="serviceTax" id="serviceTax" value="0"
               oninput="this.value = this.value.replace(/[^0-9.]/g, ''); calculateTotal();">
      </div>

      <div>
        <label>Total Amount</label>
        <input type="text" name="totalAmount" id="totalAmount" value="0" readonly>
      </div>

    </div>
  </fieldset>

  <!-- ══════════════════════════════════════════════════════════════ -->
  <!-- BUTTON SECTION                                                -->
  <!-- ══════════════════════════════════════════════════════════════ -->
  <div class="form-buttons">
    <button type="button" class="action-btn btn-validate" onclick="validateRtgsForm()">Validate</button>
    <button type="submit" class="action-btn btn-save">Save</button>
    <button type="button" class="action-btn btn-vouchers" onclick="displayVouchers()">Display Vouchers</button>
    <button type="button" class="action-btn btn-signature" onclick="captureSignature()">Display Signature</button>
    <button type="button" onclick="resetRtgsForm()" class="action-btn btn-cancel">Cancel</button>
  </div>

</form>

<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';

// ──────────────────────────────────────────────────────────────────────
// INITIALIZATION
// ──────────────────────────────────────────────────────────────────────
window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
    	window.parent.updateParentBreadcrumb(
    		    window.buildBreadcrumbPath
    		        ? window.buildBreadcrumbPath('Transactions/rtgs.jsp')
    		        : 'Transactions > RTGS / NEFT > RTGS Outward'
    		);
    }
    
    // Close success modal on backdrop click
    document.getElementById('rtgsSuccessModal').addEventListener('click', function(e) {
        if (e.target === this) closeRtgsSuccessModal();
    });

    // Close lookup modal on backdrop click
    document.getElementById('lookupModal').addEventListener('click', function(e) {
        if (e.target === this) closeLookup();
    });
};

// ──────────────────────────────────────────────────────────────────────
// ACCOUNT LOOKUP
// ──────────────────────────────────────────────────────────────────────
function openAccountLookup() {
    let url = "LookupForTransactions.jsp?type=account&accountCategory=saving";
    
    fetch(url)
        .then(function(response) { return response.text(); })
        .then(function(html) {
            document.getElementById("lookupContent").innerHTML = html;
            document.getElementById("lookupModal").style.display = "flex";
            window.currentLookupType = 'account';
            setTimeout(function() {
                const searchBox = document.getElementById('searchBox');
                if (searchBox) searchBox.focus();
            }, 100);
        })
        .catch(function(error) {
            showToast('Failed to load account lookup.', true);
            console.error('Lookup error:', error);
        });
}

function closeLookup() {
    document.getElementById("lookupModal").style.display = "none";
    window.currentLookupType = null;
}

function sendBack(code, desc, type) {
    setValueFromLookup(code, desc, type);
}

function setValueFromLookup(code, desc, type) {
    if (type === 'account') {
        document.getElementById("accountCode").value = code;
        document.getElementById("accountName").value = desc;
        
        // Fetch account details
        fetchAccountDetails(code);
        
        // Load cheque data for this account
        setTimeout(function() {
            loadChequeData();
        }, 500);
    }
    
    closeLookup();
}

// ──────────────────────────────────────────────────────────────────────
// FETCH ACCOUNT DETAILS
// ──────────────────────────────────────────────────────────────────────
function fetchAccountDetails(accountCode) {
    if (!accountCode || accountCode.trim() === '') {
        showToast('No account code provided.', true);
        return;
    }
    
    fetch('GetAccountDetails.jsp?accountCode=' + encodeURIComponent(accountCode))
        .then(response => response.json())
        .then(data => {
            if (data.error) {
                showToast('Error: ' + data.error, true);
            } else {
                // Populate only balance fields (NOT GL Account Code, GL Account Name, Customer ID)
                document.getElementById('ledgerBalance').value = data.ledgerBalance || '0.00';
                document.getElementById('availableBalance').value = data.availableBalance || '0.00';
                
                // Set new ledger balance (same as current for RTGS)
                document.getElementById('newLedgerBalance').value = data.ledgerBalance || '0.00';
                
                // ✅ Parse and populate address fields from concatenated customer address
                if (data.customerAddress && data.customerAddress.trim() !== '') {
                    populateAddressFields(data.customerAddress);
                }
                
                
            }
        })
        .catch(error => {
            console.error('Error fetching account details:', error);
            showToast('Failed to fetch account details', true);
        });
}

// ──────────────────────────────────────────────────────────────────────
// PARSE AND POPULATE ADDRESS FIELDS
// ──────────────────────────────────────────────────────────────────────
function populateAddressFields(concatenatedAddress) {
    if (!concatenatedAddress || concatenatedAddress.trim() === '') {
        return;
    }
    
    // Get the concatenated address and trim it
    var fullAddress = concatenatedAddress.trim();
    
    // Split address by multiple spaces or try to distribute intelligently
    // The function returns: ADDRESS1 || ' ' || ADDRESS2 || ' ' || ADDRESS3
    // So we try to split by looking for patterns
    
    var addressParts = [];
    
    // Try to split by finding natural breaks (multiple spaces or specific delimiters)
    // For now, we'll use a simple approach: split by space and try to distribute
    var words = fullAddress.split(/\s+/);
    
    if (words.length === 0) {
        // No words found, use full address in address1
        document.getElementById('address1').value = fullAddress;
        document.getElementById('address2').value = '';
        document.getElementById('address3').value = '';
    } else if (words.length <= 3) {
        // If 3 words or less, assign one per field
        document.getElementById('address1').value = words[0] || '';
        document.getElementById('address2').value = words[1] || '';
        document.getElementById('address3').value = words[2] || '';
    } else if (words.length <= 6) {
        // If more than 3, distribute: 2-2-2 or 2-2-rest
        var wordsPerField = Math.ceil(words.length / 3);
        var address1 = words.slice(0, wordsPerField).join(' ');
        var address2 = words.slice(wordsPerField, wordsPerField * 2).join(' ');
        var address3 = words.slice(wordsPerField * 2).join(' ');
        
        document.getElementById('address1').value = address1 || '';
        document.getElementById('address2').value = address2 || '';
        document.getElementById('address3').value = address3 || '';
    } else {
        // If many words, distribute evenly
        var itemsPerGroup = Math.ceil(words.length / 3);
        var address1 = words.slice(0, itemsPerGroup).join(' ');
        var address2 = words.slice(itemsPerGroup, itemsPerGroup * 2).join(' ');
        var address3 = words.slice(itemsPerGroup * 2).join(' ');
        
        document.getElementById('address1').value = address1 || '';
        document.getElementById('address2').value = address2 || '';
        document.getElementById('address3').value = address3 || '';
    }
}

// ──────────────────────────────────────────────────────────────────────
// LOAD CHEQUE DATA
// ──────────────────────────────────────────────────────────────────────
function loadChequeData() {
    const accountCode = document.getElementById('accountCode').value.trim();
    
    if (!accountCode) {
        showToast('Please select an account first', true);
        return;
    }
    
    // Show loading state
    document.getElementById('chequeType').innerHTML = '<option value="">Loading...</option>';
    document.getElementById('chequeSeries').innerHTML = '<option value="">Loading...</option>';
    document.getElementById('chequeNumber').innerHTML = '<option value="">Loading...</option>';
    
    fetch('GetChequeData.jsp?accountCode=' + encodeURIComponent(accountCode))
        .then(response => response.json())
        .then(data => {
            if (!data.success) {
                showToast('Cheque data error: ' + (data.error || 'Unknown error'), true);
                clearChequeDropdowns();
                return;
            }
            
            if (!data.cheques || data.cheques.length === 0) {
                clearChequeDropdowns('No cheques available');
                return;
            }
            
            // Populate Cheque Type (unique CHEQUETYPE_CODE)
            let chequeTypeSelect = document.getElementById('chequeType');
            chequeTypeSelect.innerHTML = '<option value="">Select Cheque Type</option>';
            
            if (data.typeList && data.typeList.length > 0) {
                data.typeList.forEach(function(type) {
                    let opt = document.createElement('option');
                    opt.value = type.trim();
                    opt.textContent = type.trim();
                    chequeTypeSelect.appendChild(opt);
                });
            }
            
            // Populate Cheque Series (unique CHEQUE_SERIES)
            let chequeSeriesSelect = document.getElementById('chequeSeries');
            chequeSeriesSelect.innerHTML = '<option value="">Select Cheque Series</option>';
            
            if (data.seriesList && data.seriesList.length > 0) {
                data.seriesList.forEach(function(series) {
                    let opt = document.createElement('option');
                    opt.value = series.trim();
                    opt.textContent = series.trim();
                    chequeSeriesSelect.appendChild(opt);
                });
            }
            
            // Populate Cheque Number (all CHEQUE_NUMBER)
            let chequeNoSelect = document.getElementById('chequeNumber');
            chequeNoSelect.innerHTML = '<option value="">Select Cheque No</option>';
            
            data.cheques.forEach(function(cheque) {
                let opt = document.createElement('option');
                opt.value = cheque.chequeNumber.trim();
                opt.textContent = cheque.chequeNumber.trim();
                chequeNoSelect.appendChild(opt);
            });
            
            showToast('✓ Cheque data loaded successfully', false);
        })
        .catch(error => {
            console.error('Error loading cheque data:', error);
            showToast('Failed to load cheque data', true);
            clearChequeDropdowns();
        });
}

function clearChequeDropdowns(message = 'No cheques available') {
    document.getElementById('chequeType').innerHTML = '<option value="">' + message + '</option>';
    document.getElementById('chequeSeries').innerHTML = '<option value="">' + message + '</option>';
    document.getElementById('chequeNumber').innerHTML = '<option value="">' + message + '</option>';
}

// ──────────────────────────────────────────────────────────────────────
// CALCULATE TOTAL AMOUNT
// ──────────────────────────────────────────────────────────────────────
function calculateTotal() {
    var remitting = parseFloat(document.getElementById('remittingAmount').value) || 0;
    var charges = parseFloat(document.getElementById('applicableCharges').value) || 0;
    var tax = parseFloat(document.getElementById('serviceTax').value) || 0;
    var total = remitting + charges + tax;
    
    document.getElementById('totalAmount').value = total.toFixed(2);
}

// ──────────────────────────────────────────────────────────────────────
// FORM SUBMISSION
// ──────────────────────────────────────────────────────────────────────
function submitRtgsForm(e) {
    e.preventDefault();
    
    var btn = document.querySelector('button[type="submit"]');
    if (btn.disabled) return;
    
    btn.disabled = true;
    btn.textContent = 'Submitting...';
    
    var beneficiaryName = document.getElementById('beneficiaryName').value.trim();
    var accountCode = document.getElementById('accountCode').value.trim();
    var remittingAmount = document.getElementById('remittingAmount').value.trim();
    
    if (!beneficiaryName) {
        btn.disabled = false;
        btn.textContent = 'Save';
        showToast('Please enter Beneficiary Name.', true);
        return;
    }
    
    if (!accountCode) {
        btn.disabled = false;
        btn.textContent = 'Save';
        showToast('Please select Account Code.', true);
        return;
    }
    
    if (!remittingAmount || parseFloat(remittingAmount) <= 0) {
        btn.disabled = false;
        btn.textContent = 'Save';
        showToast('Please enter a valid Remitting Amount.', true);
        return;
    }
    
    var formData = new FormData(document.getElementById('rtgsForm'));
    
    fetch(window.APP_CONTEXT_PATH + '/RtgsServlet', {
        method: 'POST',
        body: formData
    })
    .then(function(res) { return res.json(); })
    .then(function(data) {
        btn.disabled = false;
        btn.textContent = 'Save';
        
        if (data.success) {
            document.getElementById('successTransactionId').textContent = data.transactionId || '—';
            document.getElementById('successBeneficiaryName').textContent = data.beneficiaryName || '—';
            document.getElementById('successAmount').textContent = '₹ ' + (data.totalAmount || '0.00');
            document.getElementById('rtgsSuccessModal').classList.add('open');
            resetRtgsForm();
        } else {
            showToast(data.message || 'Failed to submit RTGS request.', true);
        }
    })
    .catch(function(err) {
        btn.disabled = false;
        btn.textContent = 'Save';
        showToast('Network error: ' + err.message, true);
    });
}

// ──────────────────────────────────────────────────────────────────────
// HELPER FUNCTIONS
// ──────────────────────────────────────────────────────────────────────
function closeRtgsSuccessModal() {
    document.getElementById('rtgsSuccessModal').classList.remove('open');
}

function showToast(msg, isError) {
    Toastify({
        text: msg,
        duration: 3500,
        gravity: 'top',
        position: 'right',
        stopOnFocus: true,
        style: {
            background: isError
                ? 'linear-gradient(to right,#e53935,#b71c1c)'
                : 'linear-gradient(to right,#373279,#5a3ec8)',
            borderRadius: '8px',
            fontFamily: 'Arial,sans-serif',
            fontSize: '14px'
        }
    }).showToast();
}

function validateRtgsForm() {
    var accountCode = document.getElementById('accountCode').value.trim();
    var beneficiaryName = document.getElementById('beneficiaryName').value.trim();
    var remittingAmount = document.getElementById('remittingAmount').value.trim();
    
    if (!accountCode) {
        showToast('Please select Account Code.', true);
        return;
    }
    
    if (!beneficiaryName) {
        showToast('Please enter Beneficiary Name.', true);
        return;
    }
    
    if (!remittingAmount || parseFloat(remittingAmount) <= 0) {
        showToast('Please enter a valid Remitting Amount.', true);
        return;
    }
    
    showToast('✔ Validation successful', false);
}

function displayVouchers() {
    showToast('Vouchers feature - To be implemented', false);
}

function captureSignature() {
    showToast('Signature capture feature - To be implemented', false);
}

function resetRtgsForm() {
    document.getElementById('rtgsForm').reset();
    
    ['accountName', 'ledgerBalance', 'availableBalance', 'newLedgerBalance',
     'ifscBankName', 'ifscBranchName', 'totalAmount'].forEach(function(id) {
        var el = document.getElementById(id);
        if (el) el.value = '';
    });
    
    clearChequeDropdowns();
    
    document.getElementById('remittingAmount').value = '0';
    document.getElementById('applicableCharges').value = '0';
    document.getElementById('serviceTax').value = '0';
    document.getElementById('totalAmount').value = '0';
}

function openIfscLookup() {
    showToast('IFSC lookup - To be implemented', false);
}

function toggleModeSections(mode) {
    // Transfer Details inputs → readonly when Cash is selected
    document.querySelectorAll('fieldset:nth-of-type(2) input').forEach(function(el) {
        el.readOnly = (mode === 'Cash');
    });

    // Cash Details inputs → readonly when Transfer is selected
    document.querySelectorAll('fieldset:nth-of-type(3) input').forEach(function(el) {
        el.readOnly = (mode === 'Transfer');
    });
}

// Run once on load to apply default (Transfer is checked by default)
document.addEventListener('DOMContentLoaded', function() {
    toggleModeSections('Transfer');
});
</script>

</body>
</html>
