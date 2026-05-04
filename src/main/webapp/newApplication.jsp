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

        .input-box {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        input {
            padding: 10px;
            width: 180px;
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
                        <div class="label">Account Type</div>
                        <div class="input-box">
                            <input type="text" 
                                   name="accountType" 
                                   id="accountType" 
                                   placeholder="Enter code" 
                                   maxlength="2"
                                   class="editable"
                                   style="text-transform: uppercase;">
                            <button type="button" class="icon-btn" onclick="openLookup('account')">…</button>
                        </div>
                    </div>

                    <div>
                        <div class="label">Description</div>
                        <input type="text" 
                               name="accDescription" 
                               id="accDescription" 
                               placeholder="Description" 
                               style="width: 230px;" 
                               readonly>
                    </div>

                    <!-- Product Code -->
                    <div>
                        <div class="label">Product Code</div>
                        <div class="input-box">
                            <input type="text" 
                                   name="productCode" 
                                   id="productCode" 
                                   placeholder="Enter code" 
                                   maxlength="3"
                                   class="editable">
                            <button type="button" class="icon-btn" onclick="openLookup('product', document.getElementById('accountType').value)">…</button>
                        </div>
                    </div>

                    <div>
                        <div class="label">Description</div>
                        <input type="text" 
                               name="prodDescription" 
                               id="prodDescription" 
                               placeholder="Description" 
                               style="width: 230px;" 
                               readonly>
                    </div>

                </div>
            </fieldset>

        </div>
    </form>

    <!-- 🔽 IFRAME for loading dynamic pages -->
    <iframe id="resultFrame" name="resultFrame"
            style="width:100%; height:800px; border:1px solid #ccc; margin-top:20px;">
    </iframe>

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

/**
 * Validate Account Type: 2 alphabetic characters only
 */
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

/**
 * Validate Product Code: up to 3 digits only
 */
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

/**
 * Fetch Account Type description from database
 */
function fetchAccountTypeDescription(accountType) {
    if (!accountType || accountType.length !== 2) {
        document.getElementById('accDescription').value = '';
        // Clear product fields when account type changes
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
                
                // Clear product fields when account type changes
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

/**
 * Fetch Product Code description from database
 */
function fetchProductCodeDescription(productCode, accountType) {
    if (!productCode || productCode.length === 0) {
        document.getElementById('prodDescription').value = '';
        return;
    }
    
    if (!accountType || accountType.length !== 2) {
        // Don't show toast - just silently return since this is automatic validation
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
                
                // Auto submit form when valid product is selected
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
    
    // Account Type input validation and fetch
    accountTypeInput.addEventListener('input', function(e) {
        let value = e.target.value.toUpperCase();
        e.target.value = value;
        
        // Remove non-alphabetic characters
        if (!/^[A-Z]*$/.test(value)) {
            e.target.value = value.replace(/[^A-Z]/g, '');
            // Don't show toast for every keystroke - just prevent the input
            return;
        }
        
        validateAccountType(e.target.value);
        
        // Clear product code and iframe when account type changes
        document.getElementById('productCode').value = '';
        document.getElementById('prodDescription').value = '';
        document.getElementById('resultFrame').src = '';
        
        // Fetch immediately when 2 characters entered
        if (e.target.value.length === 2) {
            fetchAccountTypeDescription(e.target.value);
        } else if (e.target.value.length < 2) {
            document.getElementById('accDescription').value = '';
        }
    });
    
    // ✅ Handle Enter/Tab key press
    accountTypeInput.addEventListener('keydown', function(e) {
        if (e.key === 'Enter' || e.key === 'Tab') {
            const value = e.target.value.trim();
            const descField = document.getElementById('accDescription');
            
            // Only move focus if account type is valid and description is fetched
            if (value.length === 2 && descField.value && descField.value !== 'No account type found' && descField.value !== 'Error fetching data') {
                e.preventDefault(); // Prevent default tab/enter behavior
                document.getElementById('productCode').focus();
            }
        }
    });
    
    // Product Code input validation and fetch
    productCodeInput.addEventListener('input', function(e) {
        let value = e.target.value;
        
        // Remove non-numeric characters
        if (!/^\d*$/.test(value)) {
            e.target.value = value.replace(/\D/g, '');
            // Don't show toast for every keystroke - just prevent the input
            return;
        }
        
        validateProductCode(e.target.value);
        
        // Clear iframe when product code changes or is removed
        document.getElementById('resultFrame').src = '';
        
        // Fetch only when 3 digits are entered
        const accountType = document.getElementById('accountType').value.trim();

        if (e.target.value.length === 3) {
            if (accountType.length === 2) {
                fetchProductCodeDescription(e.target.value, accountType);
            }
        } else if (e.target.value.length === 0) {
            document.getElementById('prodDescription').value = '';
        } else {
            // Clear any previous error messages while typing
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
        
        // Clear product fields and IFrame when new account type selected
        document.getElementById("productCode").value = "";
        document.getElementById("prodDescription").value = "";
        document.getElementById("resultFrame").src = "";
    }

    if (type === "product") {
        document.getElementById("productCode").value = code;
        document.getElementById("prodDescription").value = desc;
        
        // Auto submit form when product is selected
        autoSubmitForm();
    }

    closeLookup();
}

// ========== FORM SUBMISSION ==========

function autoSubmitForm() {
    let accType = document.getElementById("accountType").value.trim();
    let prodCode = document.getElementById("productCode").value.trim();

    // Validate fields are filled (silent validation - no toasts)
    if (!accType || accType.length !== 2) {
        return;
    }
    
    if (!prodCode) {
        return;
    }

    // Mapping based on Account Type
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

    console.log("Account Type =", accType);

    // Check if mapping exists for this account type
    if (pageMap[accType]) {
        document.getElementById("productForm").action = pageMap[accType];
        document.getElementById("productForm").submit();
    } else {
        showToast('No page found for Account Type: ' + accType, 'error');
    }
}
</script>
</body>
</html>
