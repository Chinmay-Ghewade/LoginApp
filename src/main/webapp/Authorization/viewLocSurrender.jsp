<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("branchCode") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String sessionBranch = (String) sess.getAttribute("branchCode");
    String officerId     = (String) sess.getAttribute("userId"); // adjust attribute name if different

    /* ── Parameters passed from the list page ── */
    String pBranchCode   = request.getParameter("branchCode");
    String pLockerType   = request.getParameter("lockerType");
    String pLockerNumber = request.getParameter("lockerNumber");

    /* ── Basic guard ── */
    if (pBranchCode == null || pLockerType == null || pLockerNumber == null ||
        pBranchCode.trim().isEmpty() || pLockerType.trim().isEmpty() || pLockerNumber.trim().isEmpty()) {
        response.sendRedirect("authorizationPendingLockerSurrender.jsp");
        return;
    }

    /* ────────────────────────────────────────────────
       Handle AUTHORIZE / REJECT POST action
    ──────────────────────────────────────────────── */
    String action = request.getParameter("action");
    if ("AUTHORIZE".equals(action) || "REJECT".equals(action)) {
        String newStatus = "AUTHORIZE".equals(action) ? "A" : "R";
        try (Connection conn = DBConnection.getConnection()) {
            PreparedStatement upd = conn.prepareStatement(
                "UPDATE HISTORY.LOCKERSURRENDER " +
                "   SET LOCKER_STATUS   = ?, " +
                "       OFFICER_ID      = ?, " +
                "       MODIFIED_DATE   = SYSTIMESTAMP " +
                " WHERE TRIM(BRANCH_CODE)   = TRIM(?) " +
                "   AND TRIM(LOCKER_TYPE)   = TRIM(?) " +
                "   AND LOCKER_NUMBER       = ?"
            );
            upd.setString(1, newStatus);
            upd.setString(2, officerId != null ? officerId : "");
            upd.setString(3, pBranchCode);
            upd.setString(4, pLockerType);
            upd.setInt   (5, Integer.parseInt(pLockerNumber.trim()));
            upd.executeUpdate();
        } catch (Exception e) {
            /* log silently; redirect back to list */
        }
        response.sendRedirect("authorizationPendingLockerSurrender.jsp");
        return;
    }

    /* ────────────────────────────────────────────────
       Fetch locker surrender details
    ──────────────────────────────────────────────── */
    String  custId        = "";
    String  nameOfHire    = "";
    String  branchCode    = "";
    String  lockerType    = "";
    String  lockerNumber  = "";
    String  keyNo         = "";
    String  dateOfHire    = "";
    String  surrenderDate = "";
    boolean found         = false;

    try (Connection conn = DBConnection.getConnection()) {
        PreparedStatement ps = conn.prepareStatement(
            "SELECT " +
            "  TRIM(BRANCH_CODE)                               AS BRANCH_CODE, " +
            "  TRIM(LOCKER_TYPE)                               AS LOCKER_TYPE, " +
            "  TO_CHAR(LOCKER_NUMBER)                          AS LOCKER_NUMBER, " +
            "  NVL(TO_CHAR(CUPBORD_NO), '')                   AS CUPBORD_NO, " +
            "  NVL(TO_CHAR(KEY_NO), '')                       AS KEY_NO, " +
            "  NVL(TRIM(NAME_OF_HIRE), '')                    AS NAME_OF_HIRE, " +
            "  NVL(TRIM(CUSTOMER_ID), '')                     AS CUSTOMER_ID, " +
            "  NVL(TO_CHAR(DATEOFHIRE,      'DD-Mon-YYYY'), '') AS DATE_OF_HIRE, " +
            "  NVL(TO_CHAR(DATEOFSURRENDOR, 'DD-Mon-YYYY'), '') AS SURRENDER_DATE " +
            "FROM HISTORY.LOCKERSURRENDER " +
            "WHERE TRIM(BRANCH_CODE)   = TRIM(?) " +
            "  AND TRIM(LOCKER_TYPE)   = TRIM(?) " +
            "  AND LOCKER_NUMBER       = ? " +
            "  AND TRIM(LOCKER_STATUS) = 'E'"
        );
        ps.setString(1, pBranchCode);
        ps.setString(2, pLockerType);
        ps.setInt   (3, Integer.parseInt(pLockerNumber.trim()));

        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            found        = true;
            branchCode   = rs.getString("BRANCH_CODE");
            lockerType   = rs.getString("LOCKER_TYPE");
            lockerNumber = rs.getString("LOCKER_NUMBER");
            keyNo        = rs.getString("KEY_NO");
            nameOfHire   = rs.getString("NAME_OF_HIRE");
            custId       = rs.getString("CUSTOMER_ID");
            dateOfHire   = rs.getString("DATE_OF_HIRE");
            surrenderDate= rs.getString("SURRENDER_DATE");
        }
    } catch (Exception e) {
        /* record stays blank; handled below */
    }

    if (!found) {
        response.sendRedirect("authorizationPendingLockerSurrender.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Locker Surrender Details – <%= branchCode %></title>
<link rel="stylesheet" href="../css/locker.css">
<link rel="stylesheet" href="../css/addCustomer.css">
<script src="<%= request.getContextPath() %>/js/breadcrumb-auto.js"></script>

<style>
.btn-container {
    display: flex;
    justify-content: center;
    gap: 15px;
    margin-top: 25px;
    flex-wrap: wrap;
}

.btn {
    padding: 10px 28px;
    border: none;
    border-radius: 6px;
    font-size: 14px;
    font-weight: bold;
    cursor: pointer;
    transition: opacity 0.2s;
}
.btn:hover { opacity: 0.88; }

.form-buttons .btn-back      { background: #2b0d73 !important; color: white !important; }
.form-buttons .btn-authorize { background: #28a745 !important; color: white !important; }
.form-buttons .btn-reject    { background: #dc3545 !important; color: white !important; }
.form-buttons .btn-authorize:hover { background: #218838 !important; }
.form-buttons .btn-reject:hover    { background: #b02a37 !important; }

/* ── Modal Overlay ── */
.modal-overlay {
    display: none;
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.45);
    z-index: 1000;
    justify-content: center;
    align-items: center;
}
.modal-overlay.active { display: flex; }

.modal-box {
    background: #fff;
    border-radius: 16px;
    padding: 40px 36px 32px;
    width: 420px;
    max-width: 92vw;
    box-shadow: 0 8px 40px rgba(0,0,0,0.18);
    text-align: center;
    animation: modalIn 0.2s ease;
}
@keyframes modalIn {
    from { transform: scale(0.92); opacity: 0; }
    to   { transform: scale(1);    opacity: 1; }
}

.modal-icon        { font-size: 36px; font-weight: bold; margin-bottom: 10px; }
.auth-icon         { color: #28a745; }
.reject-icon       { color: #dc3545; }

.modal-title {
    font-size: 22px;
    font-weight: bold;
    color: #2b0d73;
    margin-bottom: 12px;
}
.modal-title.reject-title { color: #dc3545; }

.modal-message {
    font-size: 14px;
    color: #444;
    margin-bottom: 16px;
    line-height: 1.6;
}

.modal-info {
    background: #f4f4f8;
    border-radius: 8px;
    padding: 12px 16px;
    margin-bottom: 24px;
    text-align: left;
}
.modal-info-row {
    display: flex;
    justify-content: space-between;
    font-size: 13px;
    padding: 4px 0;
    border-bottom: 1px solid #e0e0e8;
}
.modal-info-row:last-child          { border-bottom: none; }
.modal-info-row span:first-child    { color: #666; font-weight: 600; }
.modal-info-row span:last-child     { color: #2b0d73; font-weight: bold; }

.modal-btn-row { display: flex; gap: 14px; justify-content: center; }

.modal-btn-cancel {
    padding: 10px 28px; border: none; border-radius: 8px;
    background: #e0e0e0; color: #333;
    font-size: 14px; font-weight: bold; cursor: pointer;
    transition: background 0.2s;
}
.modal-btn-cancel:hover { background: #ccc; }

.modal-btn-confirm-auth {
    padding: 10px 28px; border: none; border-radius: 8px;
    background: #28a745; color: #fff;
    font-size: 14px; font-weight: bold; cursor: pointer;
    transition: background 0.2s;
}
.modal-btn-confirm-auth:hover { background: #218838; }

.modal-btn-confirm-reject {
    padding: 10px 28px; border: none; border-radius: 8px;
    background: #dc3545; color: #fff;
    font-size: 14px; font-weight: bold; cursor: pointer;
    transition: background 0.2s;
}
.modal-btn-confirm-reject:hover { background: #b02a37; }

@media (max-width: 900px) {
    .form-grid-4 { grid-template-columns: repeat(2, 1fr); }
    .form-grid-3 { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 540px) {
    .form-grid-4, .form-grid-3, .form-grid-2 { grid-template-columns: 1fr; }
}
</style>
</head>
<body>

<!-- ── Main form ── -->
<div>
    <h2 style="text-align:center; color:#373279; margin: 20px 0 10px; font-size:1.5em; letter-spacing:0.5px;">Locker Surrender Details</h2>

    <!-- ── Fieldset 1 : Customer Details ── -->
    <fieldset>
        <legend>Customer Details</legend>
        <div class="form-grid">
            <div>
                <label>Branch Code</label>
                <input type="text" value="<%= branchCode %>" readonly>
            </div>
            <div>
                <label>Customer ID</label>
                <input type="text" value="<%= custId %>" readonly>
            </div>
            <div>
                <label>Name of Hire</label>
                <input type="text" value="<%= nameOfHire %>" readonly>
            </div>
        </div>
    </fieldset>

    <!-- ── Fieldset 2 : Locker Details ── -->
    <fieldset>
        <legend>Locker Details</legend>
        <div class="form-grid">
            <div>
                <label>Locker Type</label>
                <input type="text" value="<%= lockerType %>" readonly>
            </div>
            <div>
                <label>Locker Number</label>
                <input type="text" value="<%= lockerNumber %>" readonly>
            </div>
            <div>
                <label>Key No</label>
                <input type="text" value="<%= keyNo %>" readonly>
            </div>
            <div>
                <label>Date of Hire</label>
                <input type="text" value="<%= dateOfHire %>" readonly>
            </div>
            <div>
                <label>Date of Surrender</label>
                <input type="text" value="<%= surrenderDate %>" readonly>
            </div>
        </div>
    </fieldset>

    <!-- ── Buttons ── -->
    <div class="form-buttons">
        <button class="btn btn-back"
                onclick="window.location.href='authorizationPendingLockerSurrender.jsp'; return false;">
            ← Back to List
        </button>
        <button class="btn btn-authorize" onclick="showConfirm('AUTHORIZE')">
            ✔ Authorize
        </button>
        <button class="btn btn-reject" onclick="showConfirm('REJECT')">
            ✖ Reject
        </button>
    </div>
</div>

<!-- ── Modal: Authorize ── -->
<div class="modal-overlay" id="authModal">
    <div class="modal-box">
        <div class="modal-icon auth-icon">✔</div>
        <div class="modal-title">Confirm Authorization</div>
        <div class="modal-info">
            <div class="modal-info-row"><span>Customer</span><span><%= nameOfHire %></span></div>
            <div class="modal-info-row"><span>Locker Type</span><span><%= lockerType %></span></div>
            <div class="modal-info-row"><span>Locker Number</span><span><%= lockerNumber %></span></div>
        </div>
        <div class="modal-btn-row">
            <button class="modal-btn-cancel"       onclick="hideModal('authModal')">Cancel</button>
            <button class="modal-btn-confirm-auth" onclick="submitAction('AUTHORIZE')">✔ Authorize</button>
        </div>
    </div>
</div>

<!-- ── Modal: Reject ── -->
<div class="modal-overlay" id="rejectModal">
    <div class="modal-box">
        <div class="modal-icon reject-icon">✖</div>
        <div class="modal-title reject-title">Confirm Rejection</div>
        <div class="modal-info">
            <div class="modal-info-row"><span>Customer</span><span><%= nameOfHire %></span></div>
            <div class="modal-info-row"><span>Locker Type</span><span><%= lockerType %></span></div>
            <div class="modal-info-row"><span>Locker Number</span><span><%= lockerNumber %></span></div>
        </div>
        <div class="modal-btn-row">
            <button class="modal-btn-cancel"         onclick="hideModal('rejectModal')">Cancel</button>
            <button class="modal-btn-confirm-reject" onclick="submitAction('REJECT')">✖ Reject</button>
        </div>
    </div>
</div>

<!-- Hidden form for POST ── -->
<form id="actionForm" method="post" action="viewLocSurrender.jsp">
    <input type="hidden" name="branchCode"   value="<%= pBranchCode %>">
    <input type="hidden" name="lockerType"   value="<%= pLockerType %>">
    <input type="hidden" name="lockerNumber" value="<%= pLockerNumber %>">
    <input type="hidden" name="action"       id="hiddenAction" value="">
</form>

<script>
function showConfirm(action) {
    if (action === 'AUTHORIZE') {
        document.getElementById('authModal').classList.add('active');
    } else {
        document.getElementById('rejectModal').classList.add('active');
    }
}

function hideModal(id) {
    document.getElementById(id).classList.remove('active');
}

function submitAction(action) {
    document.getElementById('hiddenAction').value = action;
    document.getElementById('actionForm').submit();
}

/* Close on backdrop click */
document.querySelectorAll('.modal-overlay').forEach(function(overlay) {
    overlay.addEventListener('click', function(e) {
        if (e.target === this) this.classList.remove('active');
    });
});

/* Breadcrumb */
window.onload = function() {
    if (window.parent && window.parent.updateParentBreadcrumb) {
        window.parent.updateParentBreadcrumb(
            window.buildBreadcrumbPath('viewLocSurrender.jsp')
        );
    }
};
</script>
</body>
</html>
