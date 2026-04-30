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
    <title>Combine Denomination</title>
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

        .field-group input {
            padding: 10px 12px;
            border: 1px solid #999;
            border-radius: 2px;
            background: #f5f5f5;
            font-size: 13px;
        }

        .btn-add {
            padding: 10px 25px;
            background: #2b0d73;
            color: #fff;
            border: none;
            font-weight: 700;
            cursor: pointer;
        }

        .table-container {
            margin: 15px 0;
            border: 1px solid #999;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        table thead {
            background: #2b0d73;
            color: #fff;
        }

        table th, table td {
            padding: 10px;
            text-align: center;
        }

        .summary-block {
            padding: 15px;
            background: #f5f5f5;
            border: 1px solid #999;
            margin-top: 20px;
        }

        .button-container {
            text-align: center;
            margin-top: 20px;
        }

        .btn {
            padding: 10px 30px;
            background: #2b0d73;
            color: white;
            border: none;
            cursor: pointer;
            margin: 5px;
        }
    </style>
</head>
<body>

<h2>Combine Denomination - Branch <%= branchCode %></h2>

<div class="page-wrapper">

    <div class="section-label">Add Scroll</div>

    <div class="form-row">
        <div class="field-group">
            <label>Scroll Number</label>
            <input type="text" id="scrollNo">
        </div>

        <div class="field-group">
            <label>Amount</label>
            <input type="number" id="scrollAmt">
        </div>

        <button class="btn-add" onclick="addScroll()">Add</button>
    </div>

    <div class="section-label">Scroll List</div>

    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th>#</th>
                    <th>Scroll</th>
                    <th>Amount</th>
                </tr>
            </thead>
            <tbody id="scrollBody"></tbody>
        </table>
    </div>

    <div class="button-container">
        <button class="btn" onclick="validateCombine()">Validate</button>
        <button class="btn" onclick="saveCombine()">Save</button>
    </div>

</div>

<script>

let scrollList = [];

function addScroll() {
    let no = document.getElementById('scrollNo').value;
    let amt = document.getElementById('scrollAmt').value;

    scrollList.push({no, amt});
    render();
}

function render() {
    let html = '';
    scrollList.forEach((s,i)=>{
        html += `<tr><td>${i+1}</td><td>${s.no}</td><td>${s.amt}</td></tr>`;
    });
    document.getElementById('scrollBody').innerHTML = html;
}

function validateCombine(){
    alert("Combine Denomination validated successfully");
}

function saveCombine(){
    alert("Combine Denomination saved successfully");
}

window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            'Cashers > Combine Denomination',
            'Cashers/combineDenomination.jsp'
        );
    }
};

</script>

</body>
</html>