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
  <title>Locker Issue</title>
  <link rel="stylesheet" href="../css/locker.css">
  <link rel="stylesheet" href="../css/tabs-navigation.css">
  <link rel="stylesheet" href="../css/lookup-modal.css">
  <script src="<%= request.getContextPath() %>/js/breadcrumb-auto.js"></script>
  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
  <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>

  <style>
    select.dd-loading { color: #999; background-color: #f9f9f9; font-style: italic; }
    .dd-spinner {
      display: inline-block; width: 8px; height: 8px; border-radius: 50%;
      background: #373279; margin-left: 4px;
      animation: ddPulse 0.8s ease-in-out infinite alternate; vertical-align: middle;
    }
    @keyframes ddPulse {
      from { opacity: 0.2; transform: scale(0.8); }
      to   { opacity: 1;   transform: scale(1.1); }
    }
    .dd-spinner.done { display: none; }

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
    .form-buttons {
      display: flex !important;
    }
    #checkAvailabilityBtn {
      background-color: #373279;
      color: white;
      border: none;
      padding: 10px 25px;
      border-radius: 6px;
      font-size: 14px;
      font-weight: bold;
      cursor: pointer;
      transition: background-color 0.3s ease, transform 0.2s ease;
    }
    #checkAvailabilityBtn:hover {
      background-color: #2b0d73;
      transform: scale(1.05);
    }
    #checkAvailabilityBtn:active {
      transform: scale(0.97);
    }
    form {
      padding: 0 20px;
    }

    /* ── Lookup table styling scoped to issue customer lookup content ── */
    #issueCustomerLookupContent .lookup-title {
      font-size: 1.05rem;
      font-weight: 700;
      color: var(--lk-primary);
      padding: 16px 18px 12px 18px;
      border-bottom: 1px solid var(--lk-border-light);
      display: flex;
      align-items: center;
      gap: 10px;
    }
    #issueCustomerLookupContent .search-box {
      padding: 14px 18px 8px 18px;
      background: var(--lk-primary-light);
      border-bottom: 1px solid var(--lk-border-light);
    }
    #issueCustomerLookupContent #customerSearch {
      width: 100%;
      height: 40px;
      padding: 0 14px 0 42px;
      border: 1.5px solid var(--lk-border);
      border-radius: var(--lk-radius-md);
      font-size: 0.875rem;
      font-family: var(--lk-font);
      color: var(--lk-text);
      box-sizing: border-box;
      outline: none;
      background: #fff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='15' height='15' fill='%238066E8' viewBox='0 0 16 16'%3E%3Cpath d='M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85zm-5.242 1.656a5.5 5.5 0 1 1 0-11 5.5 5.5 0 0 1 0 11'/%3E%3C/svg%3E") no-repeat 13px center;
      transition: border-color 0.18s ease, box-shadow 0.18s ease;
    }
    #issueCustomerLookupContent #customerSearch::placeholder { color: #a090cc; }
    #issueCustomerLookupContent #customerSearch:focus {
      border-color: var(--lk-primary);
      box-shadow: 0 0 0 3px rgba(55,50,121,0.10);
    }
    #issueCustomerLookupContent .customer-count {
      font-size: 0.75rem;
      color: var(--lk-text-muted);
      text-align: right;
      padding: 6px 18px;
      border-bottom: 1px solid var(--lk-border-light);
    }
    #issueCustomerLookupContent .customer-count strong { color: var(--lk-primary); }
    #issueCustomerLookupContent .table-container {
      flex: 1;
      overflow-y: auto;
      overflow-x: auto;
      min-height: 0;
    }
    #issueCustomerLookupContent .table-container::-webkit-scrollbar { width: 7px; }
    #issueCustomerLookupContent .table-container::-webkit-scrollbar-track { background: var(--lk-primary-light); }
    #issueCustomerLookupContent .table-container::-webkit-scrollbar-thumb { background: var(--lk-border); border-radius: 10px; }
    #issueCustomerLookupContent #customerTable {
      width: 100%;
      border-collapse: collapse;
      font-family: var(--lk-font);
    }
    #issueCustomerLookupContent #customerTable thead tr {
      background: linear-gradient(90deg, var(--lk-primary) 0%, var(--lk-accent) 100%);
      position: sticky;
      top: 0;
      z-index: 2;
    }
    #issueCustomerLookupContent #customerTable thead th {
      padding: 11px 16px;
      text-align: left;
      font-size: 0.77rem;
      font-weight: 700;
      color: rgba(255,255,255,0.95);
      letter-spacing: 0.06em;
      text-transform: uppercase;
      border-right: 1px solid rgba(255,255,255,0.12);
      white-space: nowrap;
    }
    #issueCustomerLookupContent #customerTable thead th:last-child { border-right: none; }
    #issueCustomerLookupContent #customerTable tbody tr {
      border-bottom: 1px solid var(--lk-border-light);
      cursor: pointer;
      transition: background 0.18s ease, transform 0.1s ease;
      border-left: 3px solid transparent;
    }
    #issueCustomerLookupContent #customerTable tbody tr:nth-child(even) { background: var(--lk-row-stripe); }
    #issueCustomerLookupContent #customerTable tbody tr:hover {
      background: var(--lk-row-hover);
      border-left-color: var(--lk-primary-mid);
      transform: translateX(2px);
    }
    #issueCustomerLookupContent #customerTable tbody td {
      padding: 11px 16px;
      font-size: 0.875rem;
      color: var(--lk-text);
      vertical-align: middle;
      border-right: 1px solid var(--lk-border-light);
    }
    #issueCustomerLookupContent #customerTable tbody td:last-child { border-right: none; }
    #issueCustomerLookupContent #customerTable tbody td:first-child {
      font-weight: 700;
      color: var(--lk-primary);
      font-size: 0.84rem;
      white-space: nowrap;
    }
  </style>
</head>
<body>

<form action="LockerIssueServlet" method="post">

  <!-- ══════════════════════════════════════════════════ -->
  <!-- FIELDSET 0: LOCKER TYPE DETAILS (Availability)    -->
  <!-- ══════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Locker Type Details</legend>
    <div class="form-grid">

      <div>
        <label>Locker Type</label>
        <div class="input-icon-box">
          <input type="text" name="lockerTypeSearch" id="lockerTypeSearch"
                 oninput="this.value = this.value.toUpperCase();" readonly>
          <button type="button" class="inside-icon-btn" title="Search Locker Type">🔍</button>
        </div>
      </div>

      <div>
        <label>Locker Number</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <input type="text" name="lockerNumberSearch" id="lockerNumberSearch"
                 class="form-input"
                 oninput="this.value = this.value.replace(/[^A-Za-z0-9]/g,'').toUpperCase();">
          <button type="button" class="icon-btn" onclick="openLockerLookup()"
                  style="background-color:#2D2B80; color:white; border:none; width:35px; height:35px;
                         border-radius:8px; font-size:18px; cursor:pointer;">…</button>
        </div>
      </div>

      <div style="display:flex; align-items:flex-end;">
        <button type="button" id="checkAvailabilityBtn" onclick="checkLockerAvailability()">
          Check Availability
        </button>
      </div>

    </div>
  </fieldset>


  <!-- ══════════════════════════════════════════════════ -->
  <!-- FIELDSET 0B: LOCKER ACCOUNT DETAILS               -->
  <!-- ══════════════════════════════════════════════════ -->
  <fieldset>
    <legend>Locker Account Details</legend>
    <div class="form-grid">

      <div>
        <label>Key No</label>
        <input type="text" name="keyNo" id="keyNo" readonly>
      </div>

      <div>
        <label>Customer Id</label>
        <div style="display:flex; gap:4px; align-items:center;">
          <input type="text" name="customerIdLookup" id="customerIdLookup"
                 class="form-input"
                 onclick="openCustomerLookup(this)"
                 readonly>
          <button type="button" class="icon-btn" onclick="openCustomerLookup(this)"
                  style="background-color:#2D2B80; color:white; border:none; width:35px; height:35px;
                         border-radius:8px; font-size:18px; cursor:pointer;">…</button>
        </div>
      </div>

      <div>
        <label>Customer Name</label>
        <input type="text" name="customerNameDisplay" id="customerNameDisplay" readonly>
      </div>

      <div>
        <label>Name of Hire</label>
        <input type="text" name="nameOfHire" id="nameOfHire">
      </div>

      <div>
        <label>Category</label>
        <input type="text" name="category" id="category" value="PUBLIC" readonly>
      </div>
      
      <div>
        <label>Mobile No.</label>
        <input type="text" name="dispMobile" id="dispMobile" readonly>
      </div>

      <div>
        <label>Address 1</label>
        <input type="text" name="dispAddress1" id="dispAddress1" readonly>
      </div>

      <div>
        <label>Address 2</label>
        <input type="text" name="dispAddress2" id="dispAddress2" readonly>
      </div>

      <div>
        <label>Address 3</label>
        <input type="text" name="dispAddress3" id="dispAddress3" readonly>
      </div>
      
      <div>
        <label>Telephone Res.</label>
        <input type="text" name="dispTelRes" id="dispTelRes" readonly>
      </div>

      <div>
        <label>Telephone Office</label>
        <input type="text" name="dispTelOffice" id="dispTelOffice" readonly>
      </div>

      <!-- ✅ CITY — changed from readonly input to AJAX dropdown -->
      <div>
        <label>City <span class="dd-spinner" id="citySpinner"></span></label>
        <select name="dispCity" id="dispCity" class="dd-loading">
          <option value="">Loading...</option>
        </select>
      </div>

      <div>
        <label>Pin</label>
        <input type="text" name="dispPin" id="dispPin" readonly>
      </div>

      <div>
        <label>Rent Paid Till Date</label>
        <input type="date" name="rentPaidTillDate" id="rentPaidTillDate" readonly>
      </div>

      <div>
        <label>Mode of Operation</label>
        <select name="modeOfOperation" id="modeOfOperation">
          <option value="JOINT">JOINT</option>
          <option value="SINGLE">SINGLE</option>
          <option value="EITHER_OR_SURVIVOR">EITHER OR SURVIVOR</option>
          <option value="ANYONE_OR_SURVIVOR">ANYONE OR SURVIVOR</option>
        </select>
      </div>

      <div>
        <label>Lessor Agre.</label>
        <input type="text" name="lessorAgre" id="lessorAgre">
      </div>

      <div>
        <label>Nominee</label>
        <div style="flex-direction:row;" class="radio-group">
          <label><input type="radio" name="nomineeFlag" value="yes"> Yes</label>
          <label><input type="radio" name="nomineeFlag" value="no" checked> No</label>
        </div>
      </div>

      <div>
        <label>Join Operation</label>
        <div style="flex-direction:row;" class="radio-group">
          <label><input type="radio" name="joinOperation" value="yes"> Yes</label>
          <label><input type="radio" name="joinOperation" value="no" checked> No</label>
        </div>
      </div>

    </div>
  </fieldset>


  <!-- ══════════════════════════════════════════════════ -->
  <!-- BUTTON SECTION                                    -->
  <!-- ══════════════════════════════════════════════════ -->
  <div class="form-buttons">
    <button type="submit">Issue Locker</button>
    <button type="button" onclick="resetLockerForm()">Reset</button>
  </div>

</form>

<!-- ════════════════════════════════════════════════════════════════ -->
<!-- CUSTOMER LOOKUP MODAL — exact same structure as lockerNominee  -->
<!-- ════════════════════════════════════════════════════════════════ -->
<div id="issueCustomerLookupModal" class="customer-modal">
    <div style="background:#fff; border-radius:14px; width:85%; max-width:920px;
                max-height:84vh; overflow:hidden; display:flex; flex-direction:column;
                box-shadow:0 8px 32px rgba(55,50,121,0.18); font-family:Arial,sans-serif;">

        <!-- Header -->
        <div style="display:flex; align-items:center; justify-content:space-between;
                    padding:14px 18px; background:linear-gradient(135deg,#373279,#2b0d73);
                    border-radius:14px 14px 0 0; flex-shrink:0;">
            <div style="display:flex; align-items:center; gap:10px;">
                <div style="width:34px;height:34px;background:rgba(255,255,255,0.15);
                            border-radius:6px;display:flex;align-items:center;
                            justify-content:center;font-size:17px;">🔍</div>
                <span style="font-size:1.05rem;font-weight:700;color:#fff;letter-spacing:0.02em;">Customer Lookup</span>
            </div>
            <span onclick="closeCustomerLookup()"
                  style="font-size:26px;font-weight:700;color:rgba(255,255,255,0.75);
                         cursor:pointer;line-height:1;padding:0 4px;"
                  onmouseover="this.style.color='#fff'"
                  onmouseout="this.style.color='rgba(255,255,255,0.75)'">&times;</span>
        </div>

        <!-- Loading indicator shown until content loads -->
        <div id="issueCustomerLookupLoading"
             style="display:flex;align-items:center;justify-content:center;
                    gap:10px;padding:40px 20px;color:#8066E8;font-size:14px;">
            <div style="width:18px;height:18px;border:2.5px solid #e0dcf8;
                        border-top-color:#8066E8;border-radius:50%;
                        animation:lk-spin 0.7s linear infinite;"></div>
            Loading customers...
        </div>

        <!-- Content loaded from lookupForCustomerId.jsp -->
        <div id="issueCustomerLookupContent"
             style="display:flex;flex-direction:column;flex:1;overflow:hidden;"></div>

    </div>
</div>

<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';

window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath ? window.buildBreadcrumbPath('Lockers/lockerIssues.jsp') : 'Locker Issues'
        );
    }
    loadCityDropdown();
};

// ── Load City dropdown from AddCustomerDataLoader ───────────────────
function loadCityDropdown() {
    fetch(window.APP_CONTEXT_PATH + '/loaders/AddCustomerDataLoader')
        .then(function(res) {
            if (!res.ok) throw new Error('HTTP ' + res.status);
            return res.json();
        })
        .then(function(data) {
            var citySelect  = document.getElementById('dispCity');
            var citySpinner = document.getElementById('citySpinner');
            var cities      = data.city;

            if (Array.isArray(cities) && cities.length > 0) {
                citySelect.innerHTML = '<option value="">-- Select City --</option>';
                cities.forEach(function(item) {
                    var opt = document.createElement('option');
                    opt.value       = item.v;
                    opt.textContent = item.l;
                    citySelect.appendChild(opt);
                });
            } else {
                citySelect.innerHTML = '<option value="">-- Error loading --</option>';
                citySelect.style.borderColor = '#f44336';
            }

            citySelect.classList.remove('dd-loading');
            if (citySpinner) citySpinner.classList.add('done');
        })
        .catch(function(err) {
            console.error('City dropdown error:', err);
            var citySelect  = document.getElementById('dispCity');
            var citySpinner = document.getElementById('citySpinner');
            citySelect.innerHTML   = '<option value="">-- Error: reload page --</option>';
            citySelect.classList.remove('dd-loading');
            citySelect.style.borderColor = '#f44336';
            if (citySpinner) { citySpinner.style.background = '#f44336'; citySpinner.classList.add('done'); }
        });
}

// ═══════════════════════════════════════════════════════════════════════
// CUSTOMER LOOKUP — same pattern as lockerNominee.jsp
// ═══════════════════════════════════════════════════════════════════════

function openCustomerLookup(triggerEl) {
    document.getElementById('issueCustomerLookupModal').style.display = 'flex';
    document.getElementById('issueCustomerLookupLoading').style.display = 'flex';
    document.getElementById('issueCustomerLookupContent').innerHTML = '';

    fetch(window.APP_CONTEXT_PATH + '/OpenAccount/lookupForCustomerId.jsp')
        .then(function(res) { return res.text(); })
        .then(function(html) {
            document.getElementById('issueCustomerLookupLoading').style.display = 'none';
            var content = document.getElementById('issueCustomerLookupContent');
            content.innerHTML = html;
            content.querySelectorAll('script').forEach(function(s) {
                var ns = document.createElement('script');
                ns.textContent = s.textContent;
                document.body.appendChild(ns);
                document.body.removeChild(ns);
            });
        });
}

function closeCustomerLookup() {
    document.getElementById('issueCustomerLookupModal').style.display = 'none';
}

// Called by lookupForCustomerId.jsp when a row is clicked
window.setCustomerData = function(customerId, customerName, categoryCode, riskCategory) {
    document.getElementById('customerIdLookup').value    = customerId;
    document.getElementById('customerNameDisplay').value = customerName;

    closeCustomerLookup();

    fetch(window.APP_CONTEXT_PATH + '/OpenAccount/getCustomerDetails.jsp?customerId=' + encodeURIComponent(customerId))
        .then(function(res) { return res.json(); })
        .then(function(data) {
            if (!data.success || !data.customer) return;
            var c = data.customer;

            document.getElementById('dispMobile').value    = c.mobileNo   || '';
            document.getElementById('dispAddress1').value  = c.address1   || '';
            document.getElementById('dispAddress2').value  = c.address2   || '';
            document.getElementById('dispAddress3').value  = c.address3   || '';
            document.getElementById('dispTelRes').value    = c.telRes     || '';
            document.getElementById('dispTelOffice').value = c.telOffice  || '';
            document.getElementById('dispPin').value       = c.zipCode    || '';

            // Set city dropdown to value returned from customer details
            var citySelect = document.getElementById('dispCity');
            if (c.city) {
                for (var i = 0; i < citySelect.options.length; i++) {
                    if (citySelect.options[i].value === c.city ||
                        citySelect.options[i].text  === c.city) {
                        citySelect.selectedIndex = i;
                        break;
                    }
                }
            }
        })
        .catch(function(err) {
            console.error('Failed to fetch customer details:', err);
        });
};

function checkLockerAvailability() {
    var lockerType   = document.getElementById('lockerTypeSearch').value.trim();
    var lockerNumber = document.getElementById('lockerNumberSearch').value.trim();
    if (!lockerType && !lockerNumber) {
        alert('Please enter Locker Type or Locker Number to check availability.');
        return;
    }
    fetch(window.APP_CONTEXT_PATH + '/loaders/LockerAvailabilityLoader'
        + '?lockerType='   + encodeURIComponent(lockerType)
        + '&lockerNumber=' + encodeURIComponent(lockerNumber))
    .then(function(res) { return res.json(); })
    .then(function(data) {
        if (data.available) {
            document.getElementById('keyNo').value              = data.keyNo        || '';
            document.getElementById('customerNameDisplay').value = data.customerName || '';
            document.getElementById('dispAddress1').value       = data.address1     || '';
            document.getElementById('dispAddress2').value       = data.address2     || '';
            document.getElementById('dispAddress3').value       = data.address3     || '';
            document.getElementById('dispMobile').value         = data.mobile       || '';
            document.getElementById('dispTelRes').value         = data.telRes       || '';
            document.getElementById('dispTelOffice').value      = data.telOffice    || '';
            document.getElementById('dispPin').value            = data.pin          || '';
            document.getElementById('rentPaidTillDate').value   = data.rentPaidTill || '';

            // ✅ Set city dropdown to value returned from availability check
            var citySelect = document.getElementById('dispCity');
            if (data.city) {
                for (var i = 0; i < citySelect.options.length; i++) {
                    if (citySelect.options[i].value === data.city ||
                        citySelect.options[i].text  === data.city) {
                        citySelect.selectedIndex = i;
                        break;
                    }
                }
            }

            alert('Locker is Available!');
        } else {
            alert('Locker is NOT available or not found.');
        }
    })
    .catch(function(err) { console.error('Availability check error:', err); });
}

function resetLockerForm() {
    document.querySelector('form').reset();
    document.getElementById('keyNo').value              = '';
    document.getElementById('customerNameDisplay').value = '';
    document.getElementById('dispAddress1').value       = '';
    document.getElementById('dispAddress2').value       = '';
    document.getElementById('dispAddress3').value       = '';
    document.getElementById('dispMobile').value         = '';
    document.getElementById('dispTelRes').value         = '';
    document.getElementById('dispTelOffice').value      = '';
    document.getElementById('dispPin').value            = '';
    document.getElementById('rentPaidTillDate').value   = '';
    // Reset city dropdown to first option
    document.getElementById('dispCity').selectedIndex   = 0;
}
</script>
</body>
</html>
