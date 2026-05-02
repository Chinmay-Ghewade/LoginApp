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
    <title>Denomination View</title>
    <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        body {
            font-family:'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #e8e4fc;
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
            max-width: 1400px;
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

        .filter-row {
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
            min-width: 160px;
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

        .btn-search {
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

        .btn-search:hover {
            background: #1f0a52;
        }

        .table-container {
            margin: 15px 0;
            border-radius: 8px;
            overflow: auto;
            border: 1px solid #999;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 12px;
        }

        table thead tr {
            background: #2b0d73;
            color: #fff;
        }

        table thead th {
            padding: 12px 10px;
            text-align: center;
            font-weight: 700;
            white-space: nowrap;
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
            padding: 10px;
            text-align: center;
            color: #333;
            font-weight: 500;
            border-bottom: 1px solid #ddd;
        }

        table tfoot tr {
            background: #f5f5f5;
            font-weight: 700;
        }

        table tfoot td {
            padding: 12px 10px;
            border-top: 1px solid #999;
        }

        .no-data {
            text-align: center;
            padding: 20px;
            color: #999;
            font-size: 13px;
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

        .btn-print {
            background: #2b0d73;
        }

        .btn-print:hover {
            background: #1f0a52;
        }

        .btn-cancel {
            background: #999;
        }

        .btn-cancel:hover {
            background: #777;
        }

        @media print {
            body { background: #fff !important; padding: 0; }
            .filter-row, .button-container { display: none !important; }
            .page-wrapper { box-shadow: none; border-radius: 0; }
        }
    </style>
</head>
<body>

<h2>Denomination View - Branch <%= branchCode %></h2>

<div class="page-wrapper">

    <div class="section-label">Search Criteria</div>
    <div class="filter-row">
        <div class="field-group">
            <label>From Date</label>
            <input type="date" id="fromDate">
        </div>
        <div class="field-group">
            <label>To Date</label>
            <input type="date" id="toDate">
        </div>
        <div class="field-group">
            <label>User ID</label>
            <input type="text" id="searchUser" placeholder="All Users">
        </div>
        <div class="field-group">
            <label>Transaction Type</label>
            <select id="txnType">
                <option value="">All</option>
                <option value="IN">Cash In</option>
                <option value="OUT">Cash Out</option>
            </select>
        </div>
        <button class="btn-search" onclick="searchDenom()">Search</button>
    </div>

    <div class="section-label">Denomination Details</div>
    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th>Date</th>
                    <th>User</th>
                    <th>Type</th>
                    <th>₹500</th>
                    <th>₹200</th>
                    <th>₹100</th>
                    <th>₹50</th>
                    <th>₹20</th>
                    <th>₹10</th>
                    <th>₹5</th>
                    <th>₹2</th>
                    <th>₹1</th>
                    <th>Total (₹)</th>
                </tr>
            </thead>
            <tbody id="viewBody">
                <tr><td colspan="13" class="no-data">Click Search to load data.</td></tr>
            </tbody>
            <tfoot>
                <tr id="footRow" style="display:none">
                    <td colspan="3"><b>TOTAL</b></td>
                    <td id="ft500">0</td>
                    <td id="ft200">0</td>
                    <td id="ft100">0</td>
                    <td id="ft50">0</td>
                    <td id="ft20">0</td>
                    <td id="ft10">0</td>
                    <td id="ft5">0</td>
                    <td id="ft2">0</td>
                    <td id="ft1">0</td>
                    <td id="ftTotal">0</td>
                </tr>
            </tfoot>
        </table>
    </div>

    <div class="button-container">
        <button class="btn btn-print" onclick="window.print()">Print</button>
        <button class="btn btn-cancel" onclick="cancelView()">Cancel</button>
    </div>

</div>

<script>
    const DEMO_DATA = [
        { date:'29-04-2026', user:'<%= userId %>', type:'IN',  d:[5,3,2,10,4,2,5,0,2], total:0 },
        { date:'29-04-2026', user:'<%= userId %>', type:'OUT', d:[2,1,1, 5,2,1,2,0,1], total:0 },
    ];
    const DENOMS = [500,200,100,50,20,10,5,2,1];
    DEMO_DATA.forEach(function(r) {
        r.total = r.d.reduce((s,q,i) => s + q * DENOMS[i], 0);
    });

    function searchDenom() {
        const tbody = document.getElementById('viewBody');
        if (DEMO_DATA.length === 0) {
        	tbody.innerHTML = '<tr><td colspan="13" class="no-data">No records found.</td></tr>';
            document.getElementById('footRow').style.display = 'none';
            return;
        }

        const ft = new Array(9).fill(0);
        let ftTotal = 0;
        tbody.innerHTML = DEMO_DATA.map(function(r) {
            const cells = r.d.map((q,i) => { ft[i] += q * DENOMS[i]; return '<td>' + (q * DENOMS[i]).toLocaleString('en-IN') + '</td>'; }).join('');
            ftTotal += r.total;
            return '<tr><td>' + r.date + '</td><td>' + r.user + '</td><td>' + r.type + '</td>' + cells + '<td>' + r.total.toLocaleString('en-IN') + '</td></tr>';
        }).join('');

        const keys = [500,200,100,50,20,10,5,2,1];
        keys.forEach((k,i) => document.getElementById('ft'+k).textContent = ft[i].toLocaleString('en-IN'));
        document.getElementById('ftTotal').textContent = ftTotal.toLocaleString('en-IN');
        document.getElementById('footRow').style.display = '';
    }

    function cancelView() {
        document.getElementById('fromDate').value = '';
        document.getElementById('toDate').value   = '';
        document.getElementById('searchUser').value = '';
        document.getElementById('viewBody').innerHTML = '<tr><td colspan="13" class="no-data">Click Search to load data.</td></tr>';
        document.getElementById('footRow').style.display = 'none';
    }

    window.onload = function() {
        if (window.parent && window.parent.updateParentBreadcrumb) {
            window.parent.updateParentBreadcrumb('Cashers > Denomination View', 'Cashers/denominationView.jsp');
        }
    };
</script>
</body>
</html>
