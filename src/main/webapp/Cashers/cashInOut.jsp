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
    <title>Cash In / Out</title>
    <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        body {
            font-family:'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #d4e9f7;
            min-height:100vh; padding:30px 20px; font-size:13px;
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
            align-items: flex-end;
            margin-bottom: 15px;
        }

        .field-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
            flex: 1;
            min-width: 140px;
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

        .btn-add {
            padding: 10px 25px;
            background: #2b0d73;
            color: #fff;
            border: none;
            border-radius: 2px;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.2s;
        }

        .btn-add:hover {
            background: #1f0a52;
        }

        .table-container {
            margin: 15px 0;
            border-radius: 0px;
            overflow: hidden;
            border: 1px solid #999;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        table thead tr {
            background: #2b0d73;
            color: #fff;
        }

        table thead th {
            padding: 12px 15px;
            text-align: center;
            font-size: 13px;
            font-weight: 700;
        }

        table tbody tr:nth-child(even) {
            background: #e8f1f9;
        }

        table tbody tr:nth-child(odd) {
            background: #fff;
        }

        table tbody tr:hover {
            background: #d4e9f7;
        }

        table td {
            padding: 12px 15px;
            text-align: center;
            font-size: 13px;
            color: #333;
            font-weight: 500;
            border-bottom: 1px solid #ddd;
        }

        table input[type="number"] {
            width: 90px;
            padding: 8px 10px;
            border: 1px solid #999;
            border-radius: 2px;
            text-align: center;
            font-size: 13px;
            background: #fff;
            color: #333;
        }

        table input:focus {
            outline: none;
            border-color: #2b0d73;
            background: #fff;
        }

        .btn-remove {
            padding: 6px 14px;
            background: #d32f2f;
            color: #fff;
            border: none;
            border-radius: 2px;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.2s;
        }

        .btn-remove:hover {
            background: #b71c1c;
        }

        .empty-msg {
            text-align: center;
            color: #999;
            font-size: 13px;
            padding: 15px;
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

        .btn-validate, .btn-save { background: #2b0d73; }
        .btn-validate:hover, .btn-save:hover { background: #1f0a52; }

        .btn-cancel { background: #999; }
        .btn-cancel:hover { background: #777; }
    </style>
</head>
<body>

<h2>CASH IN / OUT - Branch <%= branchCode %></h2>

<div class="page-wrapper">

    <div class="section-label">Add Scroll</div>
    <div class="form-row">
        <div class="field-group">
            <label>Scroll Number</label>
            <input type="text" id="scrollNo" placeholder="e.g. 00123">
        </div>
        <div class="field-group">
            <label>Suffix</label>
            <input type="text" id="scrollSuffix" placeholder="–" style="width:80px;">
        </div>
        <div class="field-group">
            <label>Amount (₹)</label>
            <input type="number" id="scrollAmt" min="0" placeholder="0.00">
        </div>
        <button class="btn-add" onclick="addScroll()">Add</button>
    </div>

    <div class="section-label">Scroll List</div>
    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th>#</th>
                    <th>Scroll Number</th>
                    <th>Amount (₹)</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody id="scrollBody">
                <tr><td colspan="4" class="empty-msg">No scrolls added yet.</td></tr>
            </tbody>
        </table>
    </div>

    <div class="section-label">Cash Details</div>
    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th>Denomination (₹)</th>
                    <th>Received Nos.</th>
                    <th>Received Amt (₹)</th>
                    <th>Paid Nos.</th>
                    <th>Paid Amt (₹)</th>
                </tr>
            </thead>
            <tbody id="denomBody"></tbody>
        </table>
    </div>

    <div class="section-label">Summary</div>
    <div class="summary-block">
        <div class="summary-item">
            <label>Total Received (₹)</label>
            <input type="text" id="totalRec" readonly placeholder="0">
        </div>
        <div class="summary-item">
            <label>Total Paid (₹)</label>
            <input type="text" id="totalPaid" readonly placeholder="0">
        </div>
        <div class="summary-item">
            <label>Net Amount (₹)</label>
            <input type="text" id="netAmt" readonly placeholder="0">
        </div>
    </div>

    <div class="button-container">
        <button class="btn btn-validate" onclick="validateCombine()">Validate</button>
        <button class="btn btn-save" onclick="saveCombine()">Save</button>
        <button class="btn btn-cancel" onclick="cancelCombine()">Cancel</button>
    </div>

</div>

<script>
    const DENOMS = [2000,1000,500,100,50,20,10,5,2,1];
    let scrollList = [];
    let scrollCounter = 0;

    const tbody = document.getElementById('denomBody');
    DENOMS.forEach(function(d) {
        const tr = document.createElement('tr');
        tr.innerHTML =
            '<td>₹ ' + d + '</td>' +
            '<td><input type="number" min="0" value="0" class="rec-inp" data-denom="' + d + '" oninput="recalc()"></td>' +
            '<td class="rec-amt" id="rec-' + d + '">0</td>' +
            '<td><input type="number" min="0" value="0" class="paid-inp" data-denom="' + d + '" oninput="recalc()"></td>' +
            '<td class="paid-amt" id="paid-' + d + '">0</td>';
        tbody.appendChild(tr);
    });

    function recalc() {
        let rec = 0, paid = 0;
        DENOMS.forEach(function(d) {
            const rq = parseInt(document.querySelector('.rec-inp[data-denom="'+d+'"]').value) || 0;
            const pq = parseInt(document.querySelector('.paid-inp[data-denom="'+d+'"]').value) || 0;
            const ra = d * rq, pa = d * pq;
            document.getElementById('rec-' + d).textContent  = ra.toLocaleString('en-IN');
            document.getElementById('paid-' + d).textContent = pa.toLocaleString('en-IN');
            rec += ra; paid += pa;
        });
        document.getElementById('totalRec').value  = rec.toLocaleString('en-IN');
        document.getElementById('totalPaid').value = paid.toLocaleString('en-IN');
        document.getElementById('netAmt').value    = (rec - paid).toLocaleString('en-IN');
    }

    function addScroll() {
        const no  = document.getElementById('scrollNo').value.trim();
        const sfx = document.getElementById('scrollSuffix').value.trim();
        const amt = parseFloat(document.getElementById('scrollAmt').value) || 0;
        if (!no) { alert('Please enter Scroll Number.'); return; }
        scrollCounter++;
        scrollList.push({ id: scrollCounter, no: no + (sfx ? '-' + sfx : ''), amt });
        renderScrollList();
        document.getElementById('scrollNo').value  = '';
        document.getElementById('scrollSuffix').value = '';
        document.getElementById('scrollAmt').value = '';
    }

    function removeScroll(id) {
        scrollList = scrollList.filter(s => s.id !== id);
        renderScrollList();
    }

    function renderScrollList() {
        const sb = document.getElementById('scrollBody');
        if (scrollList.length === 0) {
            sb.innerHTML = '<tr><td colspan="4" class="empty-msg">No scrolls added yet.</td></tr>';
            return;
        }
        sb.innerHTML = scrollList.map((s, i) =>
            '<tr>' +
            '<td>' + (i+1) + '</td>' +
            '<td>' + s.no + '</td>' +
            '<td>₹ ' + s.amt.toLocaleString('en-IN') + '</td>' +
            '<td><button class="btn-remove" onclick="removeScroll(' + s.id + ')">Remove</button></td>' +
            '</tr>'
        ).join('');
    }

    function validateCombine() {
        if (scrollList.length === 0) { alert('Please add at least one scroll.'); return; }
        alert('Cash In / Out validated successfully.');
    }

    function saveCombine() {
        if (scrollList.length === 0) { alert('Please add at least one scroll.'); return; }
        alert('Cash In / Out saved successfully!');
    }

    function cancelCombine() {
        scrollList = []; scrollCounter = 0; renderScrollList();
        document.querySelectorAll('.rec-inp, .paid-inp').forEach(i => i.value = 0);
        recalc();
    }

    window.onload = function() {
        if (window.parent && window.parent.updateParentBreadcrumb) {
            window.parent.updateParentBreadcrumb('Cashers > Cash In / Out', 'Cashers/cashInOut.jsp');
        }
    };
</script>
</body>
</html>