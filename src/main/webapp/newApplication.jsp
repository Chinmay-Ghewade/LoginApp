<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, db.DBConnection" %>

<%
    // ✅ Handle AJAX requests for fetching data
    String action = request.getParameter("action");
    
    if ("fetchAccountType".equals(action)) {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String accountType = request.getParameter("accountType");
        StringBuilder json = new StringBuilder();
        
        if (accountType == null || accountType.trim().isEmpty()) {
            json.append("{\"success\":false,\"message\":\"Account Type is required\"}");
        } else {
            accountType = accountType.trim().toUpperCase();
            
            if (!accountType.matches("^[A-Z]{2}$")) {
                json.append("{\"success\":false,\"message\":\"Invalid Account Type format\"}");
            } else {
                Connection conn = null;
                PreparedStatement ps = null;
                ResultSet rs = null;
                
                try {
                    conn = DBConnection.getConnection();
                    String query = "SELECT NAME FROM HEADOFFICE.ACCOUNTTYPE WHERE ACCOUNT_TYPE = ?";
                    ps = conn.prepareStatement(query);
                    ps.setString(1, accountType);
                    rs = ps.executeQuery();
                    
                    if (rs.next()) {
                        String name = rs.getString("NAME").replace("\"", "\\\"");
                        json.append("{\"success\":true,\"name\":\"").append(name).append("\"}");
                    } else {
                        json.append("{\"success\":false,\"message\":\"Account Type not found\"}");
                    }
                } catch (SQLException e) {
                    json.append("{\"success\":false,\"message\":\"Database error\"}");
                    e.printStackTrace();
                } finally {
                    try { if (rs != null) rs.close(); } catch (Exception e) { }
                    try { if (ps != null) ps.close(); } catch (Exception e) { }
                    try { if (conn != null) conn.close(); } catch (Exception e) { }
                }
            }
        }
        
        out.print(json.toString());
        return;
    }
    
    if ("fetchProductCode".equals(action)) {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String productCode = request.getParameter("productCode");
        String accountType = request.getParameter("accountType");
        StringBuilder json = new StringBuilder();
        
        if (productCode == null || productCode.trim().isEmpty()) {
            json.append("{\"success\":false,\"message\":\"Product Code is required\"}");
        } else if (accountType == null || accountType.trim().isEmpty()) {
            json.append("{\"success\":false,\"message\":\"Account Type is required\"}");
        } else {
            productCode = productCode.trim();
            accountType = accountType.trim().toUpperCase();
            
            if (!productCode.matches("^\\d{1,3}$")) {
                json.append("{\"success\":false,\"message\":\"Invalid Product Code format\"}");
            } else if (!accountType.matches("^[A-Z]{2}$")) {
                json.append("{\"success\":false,\"message\":\"Invalid Account Type format\"}");
            } else {
                Connection conn = null;
                PreparedStatement ps = null;
                ResultSet rs = null;
                
                try {
                    conn = DBConnection.getConnection();
                    String query = "SELECT DESCRIPTION FROM HEADOFFICE.PRODUCT WHERE PRODUCT_CODE = ? AND ACCOUNT_TYPE = ?";
                    ps = conn.prepareStatement(query);
                    ps.setString(1, productCode);
                    ps.setString(2, accountType);
                    rs = ps.executeQuery();
                    
                    if (rs.next()) {
                        String description = rs.getString("DESCRIPTION").replace("\"", "\\\"");
                        json.append("{\"success\":true,\"description\":\"").append(description).append("\"}");
                    } else {
                        json.append("{\"success\":false,\"message\":\"Product Code not found\"}");
                    }
                } catch (SQLException e) {
                    json.append("{\"success\":false,\"message\":\"Database error\"}");
                    e.printStackTrace();
                } finally {
                    try { if (rs != null) rs.close(); } catch (Exception e) { }
                    try { if (ps != null) ps.close(); } catch (Exception e) { }
                    try { if (conn != null) conn.close(); } catch (Exception e) { }
                }
            }
        }
        
        out.print(json.toString());
        return;
    }
    
    // ✅ Get branch code from session for normal page load
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String branchCode = (String) sess.getAttribute("branchCode");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>List of Product</title>
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
    <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/toastify-js"></script>
    <script src="<%= request.getContextPath() %>/js/breadcrumb-auto.js"></script>
    
    <style>
        body {
            margin: -10px 0px 0px 0px;
            font-family: Arial, sans-serif;
            background-color: #e8e4fc;
        }

        .container {
            width: 90%;
            margin: 30px auto;
        }

        h1 {
            text-align: center;
            font-size: 30px;
            color: #3D316F;
            letter-spacing: 2px;
            margin-bottom: 30px;
        }

        .header-box {
            display: flex;
            justify-content: space-between;
            background: white;
            padding: 15px 20px;
            border-radius: 10px;
            font-size: 16px;
            color: #3D316F;
            box-shadow: 0px 2px 10px rgba(0,0,0,0.05);
        }

        .header-box span {
            font-weight: bold;
        }

        .card {
            margin-top: 30px;
            border-radius: 12px;
        }

        .card-title {
            font-size: 20px;
            color: #3D316F;
            font-weight: bold;
            margin-bottom: 20px;
        }

        fieldset {
            background-color: white;
            border: 2px solid #BBADED;
            border-radius: 12px;
        }

        legend {
            font-size: 18px;
            padding: 0 10px;
            color: #3D316F;
        }

        .row {
            display: flex;
            gap: 25px;
            margin-bottom: 20px;
        }

        .label {
            font-weight: bold;
            font-size: 14px;
            color: #3D316F;
        }
        
        .label1 {
            font-weight: bold;
            font-size: 14px;
            color: #3D316F;
            text-align-last: end;
        }
        

        .input-box {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        input {
            padding: 10px;
            width: 70px;
            border: 2px solid #C8B7F6;
            border-radius: 8px;
            background-color: #F4EDFF;
            outline: none;
            font-size: 14px;
        }

        input:focus {
            border-color: #8066E8;
        }
        
        input.error {
            border-color: #f44336;
            background-color: #ffebee;
        }
        
        input.editable {
            background-color: #fff;
        }

        /* ✅ Bold green style for prodDescription */
        #prodDescription {
            color: #1a8c4e;
            font-weight: bold;
            border-color: #b6e4cc;
            background-color: #f4fff9;
        }

        .icon-btn {
            background-color: #2D2B80;
            color: white;
            border: none;
            width: 35px;
            height: 35px;
            border-radius: 8px;
            font-size: 18px;
            cursor: pointer;
        }

        /* ---------------- Responsive CSS Added ---------------- */
        @media (max-width: 1000px) {
            .row {
                flex-direction: column;
                gap: 15px;
            }

            input {
                width: 100%;
            }

            .input-box {
                width: 100%;
                justify-content: space-between;
            }
        }
        
        @media (max-width: 768px) {
            .row {
                flex-direction: column;
                gap: 15px;
            }

            input {
                width: 100%;
            }

            .input-box {
                width: 100%;
                justify-content: space-between;
            }
        }

        @media (max-width: 480px) {
            fieldset {
                padding: 15px;
            }

            legend {
                font-size: 16px;
            }

            input {
                font-size: 13px;
                padding: 8px;
            }

            .icon-btn {
                width: 30px;
                height: 30px;
                font-size: 16px;
            }
        }

        .modal {
            display: none;
            position: fixed;
            top: 0; left: 0;
            width: 100%; height: 100%;
            background: rgba(0,0,0,0.4);
            z-index: 9999;
        }
        
        .modal-content {
            background: #fff;
            width: 60%;
            margin: 5% auto;
            padding: 20px;
            border-radius: 12px;
        }
        
        .close {
            float: right;
            font-size: 22px;
            cursor: pointer;
        }
    </style>
</head>
<body>

<div class="container">

    <form id="productForm" method="post" target="resultFrame">
        <div class="card">

            <fieldset>
    <div class="row">

        <!-- Account Type -->
        <div>
            <div class="label1">Account Type</div>
            <div class="input-box">
                <button type="button" class="icon-btn" onclick="openLookup('account')">…</button>
                <input type="text" 
                       name="accountType" 
                       id="accountType" 
                       placeholder="Enter code" 
                       maxlength="2"
                       class="editable">
            </div>
        </div>

        <div>
            <div class="label">Description</div>
            <input type="text" 
                   name="accDescription" 
                   id="accDescription" 
                   placeholder="Description" 
                   style="width: 150px;" 
                   readonly>
        </div>

        <!-- Product Code -->
        <div>
            <div class="label1">Product Code</div>
            <div class="input-box">
                <button type="button" class="icon-btn" onclick="openLookup('product', document.getElementById('accountType').value)">…</button>
                <input type="text" 
                       name="productCode" 
                       id="productCode" 
                       placeholder="Enter code" 
                       maxlength="3"
                       class="editable">
            </div>
        </div>

        <div>
            <div class="label">Description</div>
            <input type="text" 
                   name="prodDescription" 
                   id="prodDescription" 
                   placeholder="Description" 
                   style="width: 560px; color: #1a8c4e; font-weight: 700;" 
                   readonly>
        </div>

    </div>
</fieldset>

        </div>
    </form>

    <!-- 🔽 IFRAME for loading dynamic pages -->
    <iframe id="resultFrame" name="resultFrame"
        onload="hideLoader()"
        style="width:100%; height:800px; border:1px solid #ccc; margin-top:20px;">
</iframe>
<!-- LOADING OVERLAY -->
<div id="pageLoader" style="
    display: none;
    position: fixed;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(232, 228, 252, 0.85);
    z-index: 9998;
    flex-direction: column;
    align-items: center;
    justify-content: center;
">
    <div style="
        background: white;
        border-radius: 16px;
        padding: 40px 60px;
        box-shadow: 0 10px 40px rgba(55,50,121,0.15);
        text-align: center;
    ">
        <!-- Spinner -->
        <div style="
            width: 52px; height: 52px;
            border: 5px solid #e8e4fc;
            border-top: 5px solid #373279;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
            margin: 0 auto 20px;
        "></div>
        <div id="loaderText" style="
            font-size: 16px;
            font-weight: 600;
            color: #373279;
            margin-bottom: 6px;
        ">Loading Application Form...</div>
        <div id="loaderSub" style="
            font-size: 13px;
            color: #888;
        ">Fetching product configuration</div>
    </div>
</div>

<style>
@keyframes spin {
    0%   { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}
</style>
</div>

<!-- LOOKUP MODAL -->
<div id="lookupModal" style="
    display:none; 
    position:fixed; 
    top:0; left:0; width:100%; height:100%;
    background:rgba(0,0,0,0.5); 
    justify-content:center; 
    align-items:center;
">
    <div style="background:white; width:80%; max-height:80%; overflow:auto; padding:20px; border-radius:6px;">
        <button onclick="closeLookup()" style="float:right; cursor:pointer;">✖</button>
        <div id="lookupContent"></div>
    </div>
</div>

<!-- CUSTOMER LOOKUP MODAL — lives in newApplication.jsp -->
<div id="newAppCustomerModal" style="
    display: none;
    position: fixed;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(0,0,0,0.55);
    z-index: 9999;
    align-items: center;
    justify-content: center;
">
  <div style="
      background: #fff;
      width: 85%;
      max-width: 900px;
      max-height: 85vh;
      border-radius: 12px;
      overflow: hidden;
      display: flex;
      flex-direction: column;
  ">
    <!-- Modal header -->
    <div style="
        background: #373279;
        padding: 14px 20px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-shrink: 0;
    ">
      <span style="color:#fff; font-size:16px; font-weight:bold;">
        🔍 Select Customer
      </span>
      <span onclick="closeNewAppModal()"
            style="color:rgba(255,255,255,0.8); font-size:26px; cursor:pointer; line-height:1;">
        &times;
      </span>
    </div>

    <!-- Search box -->
    <div style="padding:12px 16px; border-bottom:1px solid #eee; flex-shrink:0;">
      <input type="text"
             id="newAppModalSearch"
             placeholder="Search by Customer ID or Name..."
             oninput="filterNewAppModal()"
             style="
                 width:100%; padding:10px 14px;
                 font-size:14px; border:2px solid #9c8ed8;
                 border-radius:8px; background:#f5f3ff;
                 box-sizing:border-box; outline:none;
             ">
    </div>

    <!-- Count -->
    <div style="padding:6px 16px; font-size:13px; color:#666; flex-shrink:0;">
      Showing <strong id="newAppModalCount">0</strong> customers
    </div>

    <!-- Table — scrollable -->
    <div style="overflow-y:auto; flex:1;">
      <table id="newAppModalTable" style="width:100%; border-collapse:collapse;">
        <thead>
          <tr style="position:sticky; top:0; z-index:10;">
            <th style="background:#373279;color:#fff;padding:10px 14px;text-align:left;font-size:13px;">Customer ID</th>
            <th style="background:#373279;color:#fff;padding:10px 14px;text-align:left;font-size:13px;">Customer Name</th>
            <th style="background:#373279;color:#fff;padding:10px 14px;text-align:left;font-size:13px;">Category</th>
            <th style="background:#373279;color:#fff;padding:10px 14px;text-align:left;font-size:13px;">Risk Category</th>
          </tr>
        </thead>
        <tbody id="newAppModalBody">
          <!-- rows injected by JS -->
        </tbody>
      </table>
    </div>
  </div>
</div>

<script>
var _newAppModalCallback = null;
var _newAppModalRows = [];

// Listen for messages from resultFrame (savingAcc.jsp, loan.jsp, etc.)
window.addEventListener('message', function(e) {
    if (e.data && e.data.type === 'OPEN_CUSTOMER_LOOKUP') {
        _newAppModalCallback = e.data.callbackId;
        openNewAppModal(e.data.excludeIds || []);
    }
});

function openNewAppModal(excludeIds) {
    var modal = document.getElementById('newAppCustomerModal');
    var body  = document.getElementById('newAppModalBody');
    var count = document.getElementById('newAppModalCount');

    modal.style.display = 'flex';
    body.innerHTML = '<tr><td colspan="4" style="text-align:center;padding:30px;color:#666;">Loading...</td></tr>';
    count.textContent = '0';
    document.getElementById('newAppModalSearch').value = '';

    var url = 'OpenAccount/lookupForCustomerId.jsp';
    if (excludeIds && excludeIds.length > 0) {
        url += '?excludeCustomerIds=' + encodeURIComponent(excludeIds.join(','));
    }

    // We fetch the JSP but only extract the table rows from it
    // Easier: call a JSON endpoint. But since you already have lookupForCustomerId.jsp
    // we parse its HTML to grab the rows.
    fetch(url)
        .then(function(r){ return r.text(); })
        .then(function(html){
            var parser = new DOMParser();
            var doc    = parser.parseFromString(html, 'text/html');
            var rows   = doc.querySelectorAll('#customerTable tbody tr');

            _newAppModalRows = [];
            var fragment = document.createDocumentFragment();

            rows.forEach(function(row) {
                var cells = row.querySelectorAll('td');
                if (cells.length < 2) return;

                var custId   = cells[0] ? cells[0].textContent.trim() : '';
                var custName = cells[1] ? cells[1].textContent.trim() : '';
                var catCode  = cells[2] ? cells[2].textContent.trim() : '';
                var riskCat  = cells[3] ? cells[3].textContent.trim() : '';

                _newAppModalRows.push({ custId, custName, catCode, riskCat });

                var tr = document.createElement('tr');
                tr.style.cssText = 'cursor:pointer; transition:background 0.15s;';
                tr.innerHTML =
                    '<td style="padding:10px 14px;border-bottom:1px solid #f0f0f0;font-size:13px;">' + custId   + '</td>' +
                    '<td style="padding:10px 14px;border-bottom:1px solid #f0f0f0;font-size:13px;">' + custName + '</td>' +
                    '<td style="padding:10px 14px;border-bottom:1px solid #f0f0f0;font-size:13px;">' + catCode  + '</td>' +
                    '<td style="padding:10px 14px;border-bottom:1px solid #f0f0f0;font-size:13px;">' + riskCat  + '</td>';

                tr.onmouseover = function(){ this.style.background = '#e8e4fc'; };
                tr.onmouseout  = function(){ this.style.background = ''; };
                tr.onclick = function(){
                    selectNewAppCustomer(custId, custName, catCode, riskCat);
                };
                fragment.appendChild(tr);
            });

            body.innerHTML = '';
            body.appendChild(fragment);
            count.textContent = _newAppModalRows.length;

            if (_newAppModalRows.length === 0) {
                body.innerHTML = '<tr><td colspan="4" style="text-align:center;padding:30px;color:#666;">No customers found</td></tr>';
            }
        })
        .catch(function(){
            body.innerHTML = '<tr><td colspan="4" style="text-align:center;padding:30px;color:red;">Failed to load customers</td></tr>';
        });
}

function selectNewAppCustomer(custId, custName, catCode, riskCat) {
    // Send selected customer back to the resultFrame
    var iframe = document.getElementById('resultFrame');
    if (iframe && iframe.contentWindow) {
        iframe.contentWindow.postMessage({
            type       : 'CUSTOMER_SELECTED',
            callbackId : _newAppModalCallback,
            custId     : custId,
            custName   : custName,
            catCode    : catCode,
            riskCat    : riskCat
        }, '*');
    }
    closeNewAppModal();
}

function closeNewAppModal() {
    document.getElementById('newAppCustomerModal').style.display = 'none';
    _newAppModalCallback = null;
}

function filterNewAppModal() {
    var q    = document.getElementById('newAppModalSearch').value.toUpperCase();
    var rows = document.getElementById('newAppModalBody').querySelectorAll('tr');
    var visible = 0;
    rows.forEach(function(tr) {
        var cells = tr.querySelectorAll('td');
        if (!cells.length) return;
        var text = (cells[0].textContent + ' ' + cells[1].textContent).toUpperCase();
        var show = text.indexOf(q) > -1;
        tr.style.display = show ? '' : 'none';
        if (show) visible++;
    });
    document.getElementById('newAppModalCount').textContent = visible;
}

// Close on backdrop click
document.getElementById('newAppCustomerModal').addEventListener('click', function(e) {
    if (e.target === this) closeNewAppModal();
});

// Close on Escape
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeNewAppModal();
});
</script>

<script>
window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath('newApplication.jsp')
        );
    }
};

// ========== TOAST UTILITY FUNCTION (Only for errors) ==========
function showToast(message, type = 'error') {
    const styles = {
        error: {
            borderColor: '#f44336',
            icon: '❌'
        }
    };
    
    const style = styles[type] || styles.error;
    
    Toastify({
        text: style.icon + ' ' + message,
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
            borderLeft: `5px solid ${style.borderColor}`,
            marginTop: "20px",
            whiteSpace: "pre-line"
        },
        stopOnFocus: true
    }).showToast();
}

// ========== VALIDATION FUNCTIONS ==========

function validateAccountType(value) {
    const input = document.getElementById('accountType');
    const regex = /^[A-Za-z]{0,2}$/;
    
    if (!regex.test(value)) {
        input.classList.add('error');
        return false;
    }
    
    input.classList.remove('error');
    return true;
}

function validateProductCode(value) {
    const input = document.getElementById('productCode');
    const regex = /^\d{0,3}$/;
    
    if (!regex.test(value)) {
        input.classList.add('error');
        return false;
    }
    
    input.classList.remove('error');
    return true;
}

function fetchAccountTypeDescription(accountType) {
    if (!accountType || accountType.length !== 2) {
        document.getElementById('accDescription').value = '';
        document.getElementById('productCode').value = '';
        document.getElementById('prodDescription').value = '';
        document.getElementById('resultFrame').src = '';
        return;
    }
    
    fetch('newApplication.jsp?action=fetchAccountType&accountType=' + encodeURIComponent(accountType))
        .then(response => response.json())
        .then(data => {
            const descField = document.getElementById('accDescription');
            
            if (data.success) {
                descField.value = data.name;
                descField.classList.remove('error');
                document.getElementById('productCode').value = '';
                document.getElementById('prodDescription').value = '';
                document.getElementById('resultFrame').src = '';
            } else {
                descField.value = 'No account type found';
                descField.classList.add('error');
                showToast('Account Type not found', 'error');
            }
        })
        .catch(error => {
            console.error('Error fetching account type:', error);
            document.getElementById('accDescription').value = 'Error fetching data';
            showToast('Error connecting to database', 'error');
        });
}

function fetchProductCodeDescription(productCode, accountType) {
    if (!productCode || productCode.length === 0) {
        document.getElementById('prodDescription').value = '';
        return;
    }
    
    if (!accountType || accountType.length !== 2) {
        return;
    }
    
    fetch('newApplication.jsp?action=fetchProductCode&productCode=' + encodeURIComponent(productCode) + 
          '&accountType=' + encodeURIComponent(accountType))
        .then(response => response.json())
        .then(data => {
            const descField = document.getElementById('prodDescription');
            
            if (data.success) {
                descField.value = data.description;
                descField.classList.remove('error');
                autoSubmitForm();
            } else {
                descField.value = 'No product code found';
                descField.classList.add('error');
                showToast('Product Code not found', 'error');
            }
        })
        .catch(error => {
            console.error('Error fetching product code:', error);
            document.getElementById('prodDescription').value = 'Error fetching data';
            showToast('Error connecting to database', 'error');
        });
}

// ========== EVENT LISTENERS ==========

document.addEventListener('DOMContentLoaded', function() {
    const accountTypeInput = document.getElementById('accountType');
    const productCodeInput = document.getElementById('productCode');
    
    accountTypeInput.addEventListener('input', function(e) {
        let value = e.target.value.toUpperCase();
        e.target.value = value;
        
        if (!/^[A-Z]*$/.test(value)) {
            e.target.value = value.replace(/[^A-Z]/g, '');
            return;
        }
        
        validateAccountType(e.target.value);
        
        document.getElementById('productCode').value = '';
        document.getElementById('prodDescription').value = '';
        document.getElementById('resultFrame').src = '';
        
        if (e.target.value.length === 2) {
            fetchAccountTypeDescription(e.target.value);
        } else if (e.target.value.length < 2) {
            document.getElementById('accDescription').value = '';
        }
    });
    
    accountTypeInput.addEventListener('keydown', function(e) {
        if (e.key === 'Enter' || e.key === 'Tab') {
            const value = e.target.value.trim();
            const descField = document.getElementById('accDescription');
            
            if (value.length === 2 && descField.value && descField.value !== 'No account type found' && descField.value !== 'Error fetching data') {
                e.preventDefault();
                document.getElementById('productCode').focus();
            }
        }
    });
    
    productCodeInput.addEventListener('input', function(e) {
        let value = e.target.value;
        
        if (!/^\d*$/.test(value)) {
            e.target.value = value.replace(/\D/g, '');
            return;
        }
        
        validateProductCode(e.target.value);
        
        document.getElementById('resultFrame').src = '';
        
        const accountType = document.getElementById('accountType').value.trim();

        if (e.target.value.length === 3) {
            if (accountType.length === 2) {
                fetchProductCodeDescription(e.target.value, accountType);
            }
        } else if (e.target.value.length === 0) {
            document.getElementById('prodDescription').value = '';
        } else {
            const descField = document.getElementById('prodDescription');
            if (descField.value === 'No product code found' || descField.value === 'Error fetching data') {
                descField.value = '';
                descField.classList.remove('error');
            }
        }
    });
});

// ========== LOOKUP FUNCTIONS ==========

function openLookup(type, accType = "") {
    let url = "LookupForNewAppCode.jsp?type=" + type;

    if (accType !== "") {
        url += "&accType=" + accType;
    }

    fetch(url)
        .then(response => response.text())
        .then(html => {
            document.getElementById("lookupContent").innerHTML = html;
            document.getElementById("lookupModal").style.display = "flex";
        })
        .catch(error => {
            showToast('Failed to load lookup data. Please try again.', 'error');
            console.error('Lookup error:', error);
        });
}

function closeLookup() {
    document.getElementById("lookupModal").style.display = "none";
}

function sendBack(code, desc, type) {
    setValueFromLookup(code, desc, type);
}

function setValueFromLookup(code, desc, type) {
    if (type === "account") {
        document.getElementById("accountType").value = code;
        document.getElementById("accDescription").value = desc;
        document.getElementById("productCode").value = "";
        document.getElementById("prodDescription").value = "";
        document.getElementById("resultFrame").src = "";
    }

    if (type === "product") {
        document.getElementById("productCode").value = code;
        document.getElementById("prodDescription").value = desc;
        autoSubmitForm();
    }

    closeLookup();
}

// ========== FORM SUBMISSION ==========

function autoSubmitForm() {
    let accType = document.getElementById("accountType").value.trim();
    let prodCode = document.getElementById("productCode").value.trim();

    if (!accType || accType.length !== 2) return;
    if (!prodCode) return;

    const pageMap = {
        "SB": "OpenAccount/savingAcc.jsp",
        "CA": "OpenAccount/savingAcc.jsp",
        "TD": "OpenAccount/deposit.jsp",
        "CC": "OpenAccount/loan.jsp",
        "TL": "OpenAccount/loan.jsp",
        "PG": "OpenAccount/pigmy.jsp",
        "SH": "OpenAccount/shares.jsp",
        "FA": "OpenAccount/fAApplication.jsp"
    };

    if (pageMap[accType]) {
        showLoader(accType, prodCode);
        document.getElementById("productForm").action = pageMap[accType];
        document.getElementById("productForm").submit();
    } else {
        showToast('No page found for Account Type: ' + accType, 'error');
    }
}

function showLoader(accType, prodCode) {
    const loader = document.getElementById('pageLoader');
    const loaderText = document.getElementById('loaderText');
    const loaderSub = document.getElementById('loaderSub');

    const typeNames = {
        "SB": "Saving Account",
        "CA": "Current Account",
        "TD": "Term Deposit",
        "CC": "Cash Credit Loan",
        "TL": "Term Loan",
        "PG": "Pigmy",
        "SH": "Shares",
        "FA": "Fixed Asset"
    };

    const typeName = typeNames[accType] || accType;
    loaderText.textContent = 'Loading ' + typeName + ' Form...';
    loaderSub.textContent  = 'Product Code: ' + prodCode + ' — fetching configuration';

    loader.style.display = 'flex';
}

function hideLoader() {
    document.getElementById('pageLoader').style.display = 'none';
}
</script>

</body>
</html>
