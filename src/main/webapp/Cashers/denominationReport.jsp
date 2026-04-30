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
    <title>Denomination Report</title>
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

        .btn-generate {
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

        .btn-generate:hover {
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
            font-size: 12px;
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

        table tfoot tr {
            background: #f5f5f5;
            font-weight: 700;
        }

        table tfoot td {
            padding: 12px 15px;
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

        .btn-export {
            background: #2b0d73;
        }

        .btn-export:hover {
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

<h2>Denomination Report - Branch <%= branchCode %></h2>

<div class="page-wrapper">

    <div class="section-label">Report Parameters</div>
    <div class="filter-row">
        <div class="field-group">
            <label>Report Date</label>
            <input type="date" id="reportDate">
        </div>
        <div class="field-group">
            <label>Report Type</label>
            <select id="reportType">
                <option value="DAILY">Daily Summary</option>
                <option value="USER">User-wise</option>
                <option value="DENOM">Denomination-wise</option>
            </select>
        </div>
        <div class="field-group">
            <label>User ID (optional)</label>
            <input type="text" id="repUserId" placeholder="All Users">
        </div>
        <button class="btn-generate" onclick="generateReport()">Generate</button>
    </div>

    <div class="section-label">Report Output</div>
    <div id="noDataMsg" class="no-data">Select parameters and click Generate to view the report.</div>
    <div class="table-container" id="reportCard" style="display:none;">
        <table>
            <thead>
                <tr>
                    <th>Denomination (₹)</th>
                    <th>Opening</th>
                    <th>Received</th>
                    <th>Paid</th>
                    <th>Closing</th>
                    <th>Amount (₹)</th>
                </tr>
            </thead>
            <tbody id="reportBody"></tbody>
            <tfoot>
                <tr>
                    <td><b>TOTAL</b></td>
                    <td id="ftOpen">0</td>
                    <td id="ftRec">0</td>
                    <td id="ftPaid">0</td>
                    <td id="ftClose">0</td>
                    <td id="ftAmt">₹ 0</td>
                </tr>
            </tfoot>
        </table>
    </div>

    <div class="button-container">
        <button class="btn btn-print" onclick="window.print()">Print</button>
        <button class="btn btn-export" onclick="exportCSV()">Export CSV</button>
        <button class="btn btn-cancel" onclick="cancelReport()">Cancel</button>
    </div>

</div>

<script>
    const DENOMS = [2000,1000,500,100,50,20,10,5,2,1];

    function generateReport() {
        const dt   = document.getElementById('reportDate').value;
        const type = document.getElementById('reportType').value;
        if (!dt) { alert('Please select Report Date.'); return; }

        const rows = DENOMS.map(function(d) {
            const op  = Math.floor(Math.random()*10);
            const rec = Math.floor(Math.random()*8);
            const paid= Math.floor(Math.random()*5);
            const cl  = op + rec - paid;
            return { denom:d, op, rec, paid, cl, amt: cl * d };
        });

        const tbody = document.getElementById('reportBody');
        let ftOpen=0, ftRec=0, ftPaid=0, ftClose=0, ftAmt=0;
        tbody.innerHTML = rows.map(function(r) {
            ftOpen  += r.op;  ftRec  += r.rec;
            ftPaid  += r.paid; ftClose += r.cl; ftAmt += r.amt;
            return '<tr>' +
                '<td>₹ ' + r.denom + '</td>' +
                '<td>' + r.op   + '</td>' +
                '<td>' + r.rec  + '</td>' +
                '<td>' + r.paid + '</td>' +
                '<td>' + r.cl   + '</td>' +
                '<td>' + r.amt.toLocaleString('en-IN') + '</td>' +
                '</tr>';
        }).join('');

        document.getElementById('ftOpen').textContent  = ftOpen;
        document.getElementById('ftRec').textContent   = ftRec;
        document.getElementById('ftPaid').textContent  = ftPaid;
        document.getElementById('ftClose').textContent = ftClose;
        document.getElementById('ftAmt').textContent   = '₹ ' + ftAmt.toLocaleString('en-IN');

        document.getElementById('noDataMsg').style.display = 'none';
        document.getElementById('reportCard').style.display = 'block';
    }

    function exportCSV() {
        const card = document.getElementById('reportCard');
        if (card.style.display === 'none') { alert('Please generate a report first.'); return; }
        const rows = [['Denomination','Opening','Received','Paid','Closing','Amount']];
        document.querySelectorAll('#reportBody tr').forEach(function(tr) {
            rows.push(Array.from(tr.querySelectorAll('td')).map(td => td.textContent.replace(/₹\s*/,'')));
        });
        const csv = rows.map(r => r.join(',')).join('\n');
        const a = document.createElement('a');
        a.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
        a.download = 'Denomination_Report_' + (document.getElementById('reportDate').value || 'NA') + '.csv';
        a.click();
    }

    function cancelReport() {
        document.getElementById('reportDate').value = '';
        document.getElementById('reportBody').innerHTML = '';
        document.getElementById('reportCard').style.display = 'none';
        document.getElementById('noDataMsg').style.display = 'block';
    }

    window.onload = function() {
        if (window.parent && window.parent.updateParentBreadcrumb) {
            window.parent.updateParentBreadcrumb('Cashers > Denomination Report', 'Cashers/denominationReport.jsp');
        }
    };
</script>
</body>
</html>
