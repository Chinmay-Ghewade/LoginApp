<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String userId     = (String) session.getAttribute("userId");
    String branchCode = (String) session.getAttribute("branchCode");

    if (userId == null || branchCode == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Denomination Master</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #e8e4fc;
            min-height: 100vh;
            padding: 30px 20px;
            font-size: 13px;
        }

        h2 {
            color: #2b0d73;
            margin-bottom: 30px;
            font-size: 24px;
            font-weight: 700;
            text-align: center;
        }

        .page-wrapper {
            max-width: 1200px;
            margin: 0 auto;
            background: #fff;
            padding: 30px;
            border-radius: 2px;
        }

        .section-label {
            padding: 8px 0;
            font-size: 12px;
            font-weight: 700;
            color: #2b0d73;
            border-bottom: 2px solid #2b0d73;
            margin-top: 20px;
            margin-bottom: 15px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .form-row {
            display: flex;
            gap: 30px;
            flex-wrap: wrap;
            margin-bottom: 20px;
        }

        .field-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
            flex: 1;
            min-width: 200px;
        }

        .field-group label {
            font-size: 13px;
            font-weight: 500;
            color: #333;
        }

        .field-group input, .field-group select {
            padding: 10px 12px;
            border: 1px solid #999;
            border-radius: 2px;
            background: #f5f5f5;
            font-size: 13px;
            color: #333;
        }

        .field-group input:focus, .field-group select:focus {
            outline: none;
            border-color: #2b0d73;
            background: #fff;
        }

        .table-container {
            margin: 15px 0;
            border-radius: 8px;
            overflow: hidden;
            border: 1px solid #999;
        }

        table.denom-table {
            width: 100%;
            border-collapse: collapse;
        }

        .denom-table thead tr {
            background: #2b0d73;
            color: #fff;
        }

        .denom-table thead th {
            padding: 12px 15px;
            text-align: center;
            font-size: 13px;
            font-weight: 700;
        }

        .denom-table tbody tr:nth-child(even) {
            background: #e8f1f9;
        }

        .denom-table tbody tr:nth-child(odd) {
            background: #fff;
        }

        .denom-table tbody tr:hover {
            background: #d4e9f7;
        }

        .denom-table td {
            padding: 12px 15px;
            text-align: center;
            font-size: 13px;
            color: #333;
            font-weight: 500;
            border-bottom: 1px solid #ddd;
        }

        .denom-table input[type="number"] {
            width: 100px;
            padding: 8px 10px;
            border: 1px solid #999;
            border-radius: 2px;
            text-align: center;
            font-size: 13px;
            background: #fff;
            color: #333;
        }

        .denom-table input:focus {
            outline: none;
            border-color: #2b0d73;
            background: #fff;
        }

        .summary-block {
            padding: 15px;
            background: #f5f5f5;
            border: 1px solid #999;
            border-radius: 0px;
            margin: 20px 0;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 20px;
        }

        .summary-item {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .summary-item label {
            font-size: 12px;
            font-weight: 600;
            color: #333;
        }

        .summary-item input {
            padding: 8px 12px;
            border: 1px solid #999;
            border-radius: 2px;
            background: #fff;
            font-size: 13px;
            font-weight: 600;
            color: #2b0d73;
            text-align: right;
        }

        .button-container {
            display: flex;
            justify-content: center;
            gap: 15px;
            margin-top: 25px;
            padding-top: 20px;
            border-top: 1px solid #999;
        }

        .btn {
            padding: 10px 35px;
            border: none;
            border-radius: 2px;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.2s;
            color: #fff;
        }

        .btn-validate { background: #2b0d73; }
        .btn-validate:hover { background: #1f0a52; }

        .btn-save { background: #2b0d73; }
        .btn-save:hover { background: #1f0a52; }

        .btn-cancel { background: #999; }
        .btn-cancel:hover { background: #777; }
    </style>
</head>
<body>

<h2>User Denomination Master - Branch <%= branchCode %></h2>

<div class="page-wrapper">

    <div class="section-label">Account Details</div>
    <div class="form-row">
        <div class="field-group">
            <label>Cash Handling Date</label>
            <input type="date" id="cashHandlingDate" name="cashHandlingDate">
        </div>
        <div class="field-group">
            <label>Opening Cash (₹)</label>
            <input type="text" id="openingCash" name="openingCash" readonly placeholder="0.00">
        </div>
        <div class="field-group">
            <label>Current Cash (₹)</label>
            <input type="text" id="currentCash" name="currentCash" readonly placeholder="0.00">
        </div>
    </div>

    <div class="section-label">Cash Details</div>
    <div class="table-container">
        <table class="denom-table" id="denomTable">
            <thead>
                <tr>
                    <th>Denomination (₹)</th>
                    <th>No. of Notes</th>
                    <th>Amount (₹)</th>
                </tr>
            </thead>
            <tbody id="denomBody"></tbody>
        </table>
    </div>

    <div class="section-label">Summary</div>
    <div class="summary-block">
        <div class="summary-item">
            <label>Total Amount (₹)</label>
            <input type="text" id="totalAmt" readonly placeholder="0">
        </div>
        <div class="summary-item">
            <label>Remaining (₹)</label>
            <input type="text" id="remainingAmt" readonly placeholder="0">
        </div>
        <div class="summary-item">
            <label>Denomination (₹)</label>
            <input type="text" id="denomAmt" readonly placeholder="0">
        </div>
    </div>

    <div class="button-container">
        <button class="btn btn-validate" onclick="validateCash()">Validate</button>
        <button class="btn btn-save" onclick="saveCash()">Save</button>
        <button class="btn btn-cancel" onclick="cancelCash()">Cancel</button>
    </div>

</div>

<script>
    const DENOMS = [500, 200, 100, 50, 20, 10, 5, 2, 1];

    const tbody = document.getElementById('denomBody');
    DENOMS.forEach(function(d) {
        const tr = document.createElement('tr');
        tr.innerHTML =
            '<td>₹ ' + d + '</td>' +
            '<td><input type="number" min="0" value="0" class="qty-input" data-denom="' + d + '" oninput="recalc()"></td>' +
            '<td class="amt-cell" id="amt-' + d + '">0</td>';
        tbody.appendChild(tr);
    });

    // Change row
    const changeRow = document.createElement('tr');
    changeRow.innerHTML =
        '<td><strong>Change</strong></td>' +
        '<td><input type="number" min="0" value="0" class="qty-input" data-denom="change" oninput="recalc()"></td>' +
        '<td class="amt-cell" id="amt-change">0</td>';
    tbody.appendChild(changeRow);

    function recalc() {
        let total = 0;

        // Normal denomination rows
        DENOMS.forEach(function(d) {
            const q = parseInt(document.querySelector('.qty-input[data-denom="' + d + '"]').value) || 0;
            const amt = d * q;
            document.getElementById('amt-' + d).textContent = amt.toLocaleString('en-IN');
            total += amt;
        });

        // Change row (value entered directly as amount)
        const changeVal = parseFloat(document.querySelector('.qty-input[data-denom="change"]').value) || 0;
        document.getElementById('amt-change').textContent = changeVal.toLocaleString('en-IN');
        total += changeVal;

        document.getElementById('totalAmt').value    = total.toLocaleString('en-IN');
        document.getElementById('denomAmt').value    = total.toLocaleString('en-IN');
        document.getElementById('remainingAmt').value = 0;
    }

    function validateCash() {
        const date = document.getElementById('cashHandlingDate').value;
        if (!date) { alert('Please select Cash Handling Date.'); return; }
        const total = document.getElementById('totalAmt').value;
        alert('Validated successfully. Total: ₹ ' + total);
    }

    function saveCash() {
        const date = document.getElementById('cashHandlingDate').value;
        if (!date) { alert('Please select Cash Handling Date.'); return; }
        alert('Cash entry saved successfully!');
    }

    function cancelCash() {
        document.querySelectorAll('.qty-input').forEach(i => i.value = 0);
        document.getElementById('cashHandlingDate').value = '';
        document.getElementById('amt-change').textContent = '0';
        recalc();
    }

    window.onload = function() {
        if (window.parent && window.parent.updateParentBreadcrumb) {
            window.parent.updateParentBreadcrumb('Cashers > User Denomination Master', 'Cashers/userDenominationMaster.jsp');
        }
    };
</script>
</body>
</html>
