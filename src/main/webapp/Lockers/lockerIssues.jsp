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
  <link rel="stylesheet" href="../css/addCustomer.css">
  <link rel="stylesheet" href="../css/tabs-navigation.css">
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
  </style>
</head>
<body>

<form action="LockerIssueServlet" method="post" onsubmit="return validateForm()">

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
				       oninput="this.value = this.value.replace(/[^0-9]/g,'')">
		  <button type="button" class="icon-btn" onclick="openCustomerLookup()"
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
        <label>Address 1</label>
        <input type="text" name="dispAddress1" id="dispAddress1" readonly>
      </div>

      <div>
        <label>Mobile No.</label>
        <input type="text" name="dispMobile" id="dispMobile" readonly>
      </div>

      <div>
        <label>Address 2</label>
        <input type="text" name="dispAddress2" id="dispAddress2" readonly>
      </div>

      <div>
        <label>Telephone Res.</label>
        <input type="text" name="dispTelRes" id="dispTelRes" readonly>
      </div>

      <div>
        <label>Address 3</label>
        <input type="text" name="dispAddress3" id="dispAddress3" readonly>
      </div>

      <div>
        <label>Telephone Office</label>
        <input type="text" name="dispTelOffice" id="dispTelOffice" readonly>
      </div>

      <div>
        <label>City</label>
        <input type="text" name="dispCity" id="dispCity" readonly>
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
    <button type="reset">Reset</button>
  </div>

</form>

<script>
window.APP_CONTEXT_PATH = '<%= contextPath %>';

const DD_MAP = {
    lockerSize:    { id: 'lockerSize',    sp: 'sp-lockerSize',    codeLabel: false },
    lockerType:    { id: 'lockerType',    sp: 'sp-lockerType',    codeLabel: false },
    accountType:   { id: 'accountType',   sp: 'sp-accountType',   codeLabel: false },
    rentFrequency: { id: 'rentFrequency', sp: 'sp-rentFrequency', codeLabel: false },
    paymentMode:   { id: 'paymentMode',   sp: 'sp-paymentMode',   codeLabel: false }
};

function fillSelect(selectEl, items, codeLabel) {
    selectEl.innerHTML = '';
    const blank = document.createElement('option');
    blank.value = ''; blank.textContent = '-- Select --';
    selectEl.appendChild(blank);
    items.forEach(function(item) {
        const opt = document.createElement('option');
        opt.value = item.v;
        opt.textContent = codeLabel ? item.v + ' — ' + item.l : item.l;
        selectEl.appendChild(opt);
    });
    selectEl.classList.remove('dd-loading');
    selectEl.style.color = ''; selectEl.style.fontStyle = '';
}

(function loadAllDropdowns() {
    fetch(window.APP_CONTEXT_PATH + '/loaders/LockerIssueDataLoader')
        .then(function(res) { if (!res.ok) throw new Error('HTTP ' + res.status); return res.json(); })
        .then(function(data) {
            Object.keys(DD_MAP).forEach(function(key) {
                var cfg = DD_MAP[key];
                var selectEl = document.getElementById(cfg.id);
                if (!selectEl) return;
                var items = data[key];
                if (Array.isArray(items)) { fillSelect(selectEl, items, cfg.codeLabel); }
                else { selectEl.innerHTML = '<option value="">-- Error loading --</option>'; selectEl.classList.remove('dd-loading'); }
                if (document.getElementById(cfg.sp)) document.getElementById(cfg.sp).classList.add('done');
            });
        })
        .catch(function(err) {
            console.error('Dropdown error:', err);
            Object.keys(DD_MAP).forEach(function(key) {
                var cfg = DD_MAP[key];
                var selectEl = document.getElementById(cfg.id);
                if (selectEl) { selectEl.innerHTML = '<option value="">-- Error: reload page --</option>'; selectEl.classList.remove('dd-loading'); selectEl.style.borderColor = '#f44336'; }
            });
        });
})();

function validateForm() {
    var aadhar = document.getElementById('aadharNumber').value;
    if (aadhar.length !== 12) { alert('Aadhar Number must be exactly 12 digits'); return false; }
    if (!document.getElementById('declarationAccepted').checked) { alert('Please accept the declaration'); return false; }
    return true;
}

window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath ? window.buildBreadcrumbPath('Lockers/lockerIssues.jsp') : 'Locker Issues'
        );
    }
};

function checkLockerAvailability() {
    var lockerType   = document.getElementById('lockerTypeSearch').value.trim();
    var lockerNumber = document.getElementById('lockerNumberSearch').value.trim();
    if (!lockerType && !lockerNumber) {
        alert('Please enter Locker Type or Locker Number to check availability.');
        return;
    }
    fetch(window.APP_CONTEXT_PATH + '/loaders/LockerAvailabilityLoader'
        + '?lockerType=' + encodeURIComponent(lockerType)
        + '&lockerNumber=' + encodeURIComponent(lockerNumber))
    .then(function(res) { return res.json(); })
    .then(function(data) {
        if (data.available) {
            // Auto-fill display fields
            document.getElementById('keyNo').value           = data.keyNo        || '';
            document.getElementById('customerNameDisplay').value = data.customerName || '';
            document.getElementById('dispAddress1').value    = data.address1     || '';
            document.getElementById('dispAddress2').value    = data.address2     || '';
            document.getElementById('dispAddress3').value    = data.address3     || '';
            document.getElementById('dispMobile').value      = data.mobile       || '';
            document.getElementById('dispTelRes').value      = data.telRes       || '';
            document.getElementById('dispTelOffice').value   = data.telOffice    || '';
            document.getElementById('dispCity').value        = data.city         || '';
            document.getElementById('dispPin').value         = data.pin          || '';
            document.getElementById('rentPaidTillDate').value= data.rentPaidTill || '';
            alert('Locker is Available!');
        } else {
            alert('Locker is NOT available or not found.');
        }
    })
    .catch(function(err) { console.error('Availability check error:', err); });
}
</script>
</body>
</html>
